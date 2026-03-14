#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import random
import re
import time
import urllib.parse
import urllib.request
from urllib.error import HTTPError, URLError
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
ROOT = Path(os.environ.get('GEO_API_ROOT', str(SCRIPT_DIR.parent))).resolve()
COUNTRIES_SQL = ROOT / 'liquibase/changelog/2-load-countries.sql'
OUT_SQL = ROOT / 'liquibase/changelog/18-load-territory-from-wikidata.sql'
CACHE_JSON = ROOT / 'scripts/.territory_wikidata_cache.json'
FAILED_JSON = ROOT / 'scripts/.territory_wikidata_failed.json'

REQUEST_INTERVAL_SECONDS = 1.0
MAX_ATTEMPTS = 4
MAX_BACKOFF_SECONDS = 20
DEFAULT_TIMEOUT_SECONDS = 120

TYPE_MAPPING = [
    ('federal state', 'state'),
    ('province', 'province'),
    ('region', 'region'),
    ('region of France', 'overseas_region'),
    ('department', 'department'),
    ('county', 'county'),
    ('district', 'district'),
    ('municipality', 'municipality'),
    ('autonomous region', 'autonomous_region'),
    ('overseas department', 'overseas_region'),
    ('overseas department and region of France', 'overseas_region'),
    ('overseas territory', 'overseas_region'),
    ('historical region', 'historical_region'),
    ('cultural region', 'cultural_region'),
]

ATTACHED_COUNTRY_LABELS = {
    "AU": {
        "christmas island",
        "cocos (keeling) islands",
        "norfolk island",
    },
    "CN": {
        "hong kong",
        "macau",
    },
    "DK": {
        "faroe islands",
        "greenland",
    },
    "ES": {
        "balearic islands",
        "canary islands",
        "ceuta",
        "melilla",
        "plazas de soberania",
        "rota",
        "spanish north africa",
    },
    "FI": {
        "aland islands",
        "åland islands",
    },
    "FR": {
        "clipperton island",
        "french guiana",
        "french polynesia",
        "french southern and antarctic lands",
        "french southern territories",
        "guadeloupe",
        "martinique",
        "mayotte",
        "new caledonia",
        "réunion",
        "reunion",
        "saint barthélemy",
        "saint barthelemy",
        "saint martin",
        "saint-pierre and miquelon",
        "saint pierre and miquelon",
        "wallis and futuna",
    },
    "GB": {
        "akrotiri and dhekelia",
        "alderney",
        "anguilla",
        "bermuda",
        "british antarctic territory",
        "british indian ocean territory",
        "british virgin islands",
        "cayman islands",
        "falkland islands",
        "gibraltar",
        "guernsey",
        "isle of man",
        "jersey",
        "montserrat",
        "pitcairn islands",
        "saint helena, ascension and tristan da cunha",
        "sark",
        "south georgia and the south sandwich islands",
        "turks and caicos islands",
    },
    "NL": {
        "aruba",
        "bonaire",
        "caribbean netherlands",
        "curaçao",
        "curacao",
        "saba",
        "sint eustatius",
        "sint maarten",
        "saint martin (dutch part)",
    },
    "NO": {
        "bouvet island",
        "jan mayen",
        "svalbard",
    },
    "NZ": {
        "chatham islands",
        "cook islands",
        "niue",
        "tokelau",
    },
    "PT": {
        "azores",
        "azores islands",
        "madeira",
        "madeira islands",
    },
    "US": {
        "american samoa",
        "guam",
        "guantánamo bay",
        "guantanamo bay",
        "northern mariana islands",
        "puerto rico",
        "u.s. virgin islands",
        "united states virgin islands",
        "us virgin islands",
    },
}

ATTACHED_COUNTRY_TYPE_QIDS = {
    "GB": {"Q46395", "Q185086"},
}

TYPE_PRIORITY = {
    'overseas_region': 1,
    'autonomous_region': 2,
    'state': 3,
    'province': 4,
    'department': 5,
    'county': 6,
    'district': 7,
    'municipality': 8,
    'region': 9,
    'historical_region': 10,
    'cultural_region': 11,
}
LABEL_FALLBACK_LANGUAGES = 'en,fr,de,es,pt,it,nl,ca,pl,cs,sv'
QID_LIKE_RE = re.compile(r'^Q[0-9]+$')


def parse_iso_codes() -> list[str]:
    if not COUNTRIES_SQL.exists():
        raise FileNotFoundError(
            f"Missing input SQL file: {COUNTRIES_SQL}. "
            "Set GEO_API_ROOT to the repository path if needed."
        )
    text = COUNTRIES_SQL.read_text(encoding='utf-8')
    return sorted(set(re.findall(r"\(\d+,\s*'[^']+',\s*'([A-Z]{2})'", text)))


def qid_from_uri(uri: str | None) -> str | None:
    if not uri:
        return None
    m = re.search(r'/Q(\d+)$', uri)
    return f"Q{m.group(1)}" if m else None


def parse_point(point: str | None) -> tuple[float | None, float | None]:
    if not point:
        return None, None
    m = re.match(r'^Point\(([-0-9.]+)\s+([-0-9.]+)\)$', point)
    if not m:
        return None, None
    lon = float(m.group(1))
    lat = float(m.group(2))
    return lat, lon


def choose_better_name(current: str | None, candidate: str | None, qid: str) -> str:
    current_is_qid = not current or QID_LIKE_RE.fullmatch(current) is not None or current == qid
    candidate_is_qid = not candidate or QID_LIKE_RE.fullmatch(candidate) is not None or candidate == qid
    if current_is_qid and not candidate_is_qid:
        return candidate  # type: ignore[return-value]
    if current is None:
        return candidate or qid
    return current


def normalize_code_list(values: list[str]) -> str | None:
    cleaned = sorted({value.strip() for value in values if value and value.strip()})
    if not cleaned:
        return None
    return ",".join(cleaned)


def wikidata_query(iso_values: list[str], limit: int, offset: int) -> dict:
    values_iso = ' '.join(f'"{iso}"' for iso in iso_values)
    values_type = '\n    '.join(f'("{src}" "{dst}")' for src, dst in TYPE_MAPPING)
    alias_rows = []
    for iso in iso_values:
        for label in sorted(ATTACHED_COUNTRY_LABELS.get(iso, ())):
            alias_rows.append(f'("{iso}" "{label}")')
    values_country_alias = "\n    ".join(alias_rows)
    type_rows = []
    for iso in iso_values:
        for qid in sorted(ATTACHED_COUNTRY_TYPE_QIDS.get(iso, ())):
            type_rows.append(f'(wd:{qid} "{iso}")')
    values_country_type = "\n    ".join(type_rows)
    country_binding = """
  {
    ?country wdt:P297 ?countryIso .
  }
"""
    if alias_rows or type_rows:
        alias_union = ""
        type_union = ""
        if alias_rows:
            alias_union = f"""
  UNION
  {{
    VALUES (?countryIso ?countryLabelLc) {{
      {values_country_alias}
    }}
    ?country rdfs:label ?countryLabel .
    FILTER(LANG(?countryLabel) = "en")
    FILTER(LCASE(STR(?countryLabel)) = ?countryLabelLc)
  }}
"""
        if type_rows:
            type_union = f"""
  UNION
  {{
    VALUES (?ukRelatedType ?countryIso) {{
      {values_country_type}
    }}
    ?country wdt:P31/wdt:P279* ?ukRelatedType .
  }}
"""
        country_binding = f"""
  {{
    ?country wdt:P297 ?countryIso .
  }}{alias_union}{type_union}
"""

    query = f"""
SELECT ?countryIso ?territory ?territoryLabel ?mappedType ?parent ?coord ?phoneCode ?localDialingCode WHERE {{
  VALUES ?countryIso {{ {values_iso} }}
  VALUES (?type_lc ?mappedType) {{
    {values_type}
  }}

  {country_binding}
  ?territory wdt:P17 ?country ;
             wdt:P31/wdt:P279* ?typeClass .

  ?typeClass rdfs:label ?typeLabel .
  FILTER(LANG(?typeLabel) = "en")
  BIND(LCASE(STR(?typeLabel)) AS ?type_lc)

  OPTIONAL {{ ?territory wdt:P131 ?parent . }}
  OPTIONAL {{ ?territory wdt:P625 ?coord . }}
  OPTIONAL {{ ?territory wdt:P474 ?phoneCode . }}
  OPTIONAL {{ ?territory wdt:P473 ?localDialingCode . }}

  SERVICE wikibase:label {{ bd:serviceParam wikibase:language "{LABEL_FALLBACK_LANGUAGES}". }}
}}
LIMIT {limit}
OFFSET {offset}
"""

    params = urllib.parse.urlencode({'format': 'json', 'query': query})
    url = f'https://query.wikidata.org/sparql?{params}'
    req = urllib.request.Request(
        url,
        headers={
            'Accept': 'application/sparql-results+json',
            'User-Agent': 'geo-api/territory-import-script/1.0 (contact: local-dev)',
        },
    )
    with urllib.request.urlopen(req, timeout=DEFAULT_TIMEOUT_SECONDS) as resp:
        return json.loads(resp.read().decode('utf-8'))


def _sleep_between_requests() -> None:
    time.sleep(REQUEST_INTERVAL_SECONDS)


def _retry_after_seconds(exc: HTTPError) -> int | None:
    if exc.headers is None:
        return None
    value = exc.headers.get('Retry-After')
    if value is None:
        return None
    value = value.strip()
    if value.isdigit():
        return int(value)
    return None


def wikidata_query_with_retry(iso_values: list[str], limit: int, offset: int, max_attempts: int = MAX_ATTEMPTS) -> dict:
    last_error: Exception | None = None
    for attempt in range(1, max_attempts + 1):
        try:
            _sleep_between_requests()
            return wikidata_query(iso_values, limit=limit, offset=offset)
        except HTTPError as exc:
            last_error = exc
            if exc.code not in {429, 500, 502, 503, 504}:
                raise
            retry_after = _retry_after_seconds(exc)
            backoff = min((2 ** attempt) + random.random(), MAX_BACKOFF_SECONDS)
            sleep_s = retry_after if retry_after is not None else backoff
            print(
                f"retry {attempt}/{max_attempts} iso={','.join(iso_values)} offset={offset} "
                f"http={exc.code} sleep={sleep_s:.1f}s"
            )
            time.sleep(sleep_s)
        except (URLError, TimeoutError) as exc:
            last_error = exc
            sleep_s = min((2 ** attempt) + random.random(), MAX_BACKOFF_SECONDS)
            print(f"retry {attempt}/{max_attempts} iso={','.join(iso_values)} offset={offset}: {exc} sleep={sleep_s:.1f}s")
            time.sleep(sleep_s)
    raise RuntimeError(f"Wikidata query failed after {max_attempts} attempts") from last_error


def sql_string(value: str | None) -> str:
    if value is None:
        return 'NULL'
    return "'" + value.replace("'", "''") + "'"


def sql_number(value: float | None) -> str:
    if value is None:
        return 'NULL'
    return f"{value:.6f}"


def render_sql(rows: list[dict]) -> str:
    if not rows:
        raise RuntimeError('No territory rows found from Wikidata query.')

    values_sql = ",\n        ".join(
        "(" + ", ".join(
            [
                sql_string(row['qid']),
                sql_string(row['name']),
                sql_string(row['type']),
                sql_string(row['country_iso']),
                sql_string(row['parent_qid']),
                sql_string(row.get('telephone_country_code')),
                sql_string(row.get('local_dialing_code')),
                sql_number(row['lat']),
                sql_number(row['lon']),
            ]
        ) + ")"
        for row in rows
    )
    return f"""--liquibase formatted sql
--changeset codex:18-load-territory-from-wikidata dbms:postgresql
--comment Load territory data from Wikidata (P17/P31/P279/P131/P474/P473/P625) with mapped territory types.

WITH data (wikidata_id, name, type, country_iso, parent_wikidata_id, telephone_country_code, local_dialing_code, latitude, longitude) AS (
    VALUES
        {values_sql}
), upsert AS (
    INSERT INTO territory (wikidata_id, name, type, country_id, parent_id, telephone_country_code, local_dialing_code, latitude, longitude)
    SELECT
        d.wikidata_id,
        d.name,
        d.type,
        c.id,
        NULL,
        d.telephone_country_code,
        d.local_dialing_code,
        d.latitude,
        d.longitude
    FROM data d
    JOIN country c ON c.iso_code = d.country_iso
    ON CONFLICT (wikidata_id) DO UPDATE
    SET
        name = EXCLUDED.name,
        type = EXCLUDED.type,
        country_id = EXCLUDED.country_id,
        telephone_country_code = EXCLUDED.telephone_country_code,
        local_dialing_code = EXCLUDED.local_dialing_code,
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude
)
UPDATE territory t
SET parent_id = p.id
FROM data d
JOIN territory p ON p.wikidata_id = d.parent_wikidata_id
WHERE t.wikidata_id = d.wikidata_id
  AND d.parent_wikidata_id IS NOT NULL
  AND t.parent_id IS DISTINCT FROM p.id;
"""


def load_cache() -> tuple[int, dict[str, dict]]:
    if not CACHE_JSON.exists():
        return 0, {}
    payload = json.loads(CACHE_JSON.read_text(encoding='utf-8'))
    return int(payload.get('next_start', 0)), payload.get('rows_by_qid', {})


def save_cache(next_start: int, rows_by_qid: dict[str, dict]) -> None:
    payload = {
        'next_start': next_start,
        'rows_by_qid': rows_by_qid,
    }
    CACHE_JSON.write_text(json.dumps(payload, ensure_ascii=False), encoding='utf-8')


def main() -> None:
    parser = argparse.ArgumentParser(description='Generate Liquibase SQL for territory import from Wikidata.')
    parser.add_argument('--reset-cache', action='store_true', help='Start from scratch and ignore previous cache.')
    parser.add_argument(
        '--stop-on-error',
        action='store_true',
        help='Stop at first country failing after retries (default: continue and log failures).',
    )
    parser.add_argument(
        '--only-iso',
        type=str,
        default='',
        help='Comma-separated ISO2 list to process only specific countries (example: AF,AE,FR).',
    )
    parser.add_argument(
        '--limit',
        type=int,
        default=100,
        help='SPARQL page size (lower values reduce 504 errors but increase total requests).',
    )
    args = parser.parse_args()
    if args.limit <= 0:
        parser.error('--limit must be >= 1')

    iso_codes = parse_iso_codes()
    if args.only_iso.strip():
        wanted = {x.strip().upper() for x in args.only_iso.split(',') if x.strip()}
        iso_codes = [iso for iso in iso_codes if iso in wanted]
        print(f"only-iso mode: {','.join(iso_codes)}")
    if args.reset_cache and CACHE_JSON.exists():
        CACHE_JSON.unlink()
    if args.reset_cache and FAILED_JSON.exists():
        FAILED_JSON.unlink()

    resume_start, rows_by_qid = load_cache()
    if resume_start > 0:
        print(f"resuming from batch index {resume_start}")

    limit = args.limit
    batch_size = 1
    total = 0
    failed_isos: list[str] = []
    total_batches = (len(iso_codes) + batch_size - 1) // batch_size
    try:
        for start in range(resume_start, len(iso_codes), batch_size):
            iso_batch = iso_codes[start:start + batch_size]
            print(f"batch {start // batch_size + 1}/{total_batches} iso={','.join(iso_batch)}")
            offset = 0
            while True:
                try:
                    data = wikidata_query_with_retry(iso_batch, limit=limit, offset=offset)
                except Exception as exc:
                    failed_iso = ','.join(iso_batch)
                    print(f"failed iso={failed_iso} after retries: {exc}")
                    failed_isos.append(failed_iso)
                    if args.stop_on_error:
                        raise
                    break
                bindings = data.get('results', {}).get('bindings', [])
                if not bindings:
                    break
                print(f"  offset={offset} rows={len(bindings)}")

                for b in bindings:
                    country_iso = b.get('countryIso', {}).get('value')
                    territory_uri = b.get('territory', {}).get('value')
                    qid = qid_from_uri(territory_uri)
                    if not qid:
                        continue

                    mapped_type = b.get('mappedType', {}).get('value')
                    name = b.get('territoryLabel', {}).get('value') or qid
                    parent_qid = qid_from_uri(b.get('parent', {}).get('value'))
                    phone_code = b.get('phoneCode', {}).get('value')
                    local_dialing_code = b.get('localDialingCode', {}).get('value')
                    lat, lon = parse_point(b.get('coord', {}).get('value'))

                    existing = rows_by_qid.get(qid)
                    candidate = {
                        'qid': qid,
                        'name': name,
                        'type': mapped_type,
                        'country_iso': country_iso,
                        'parent_qid': parent_qid,
                        'telephone_country_code': phone_code,
                        'local_dialing_code': local_dialing_code,
                        'lat': lat,
                        'lon': lon,
                    }

                    if existing is None:
                        rows_by_qid[qid] = candidate
                    else:
                        p_old = TYPE_PRIORITY.get(existing['type'], 999)
                        p_new = TYPE_PRIORITY.get(mapped_type, 999)
                        if p_new < p_old:
                            candidate['parent_qid'] = candidate['parent_qid'] or existing['parent_qid']
                            candidate['telephone_country_code'] = normalize_code_list(
                                [candidate.get('telephone_country_code'), existing.get('telephone_country_code')]
                            )
                            candidate['local_dialing_code'] = normalize_code_list(
                                (candidate.get('local_dialing_code') or '').split(',')
                                + (existing.get('local_dialing_code') or '').split(',')
                            )
                            candidate['lat'] = candidate['lat'] if candidate['lat'] is not None else existing['lat']
                            candidate['lon'] = candidate['lon'] if candidate['lon'] is not None else existing['lon']
                            candidate['name'] = choose_better_name(candidate['name'], existing['name'], qid)
                            rows_by_qid[qid] = candidate
                        else:
                            existing['parent_qid'] = existing['parent_qid'] or candidate['parent_qid']
                            existing['telephone_country_code'] = normalize_code_list(
                                [existing.get('telephone_country_code'), candidate.get('telephone_country_code')]
                            )
                            existing['local_dialing_code'] = normalize_code_list(
                                (existing.get('local_dialing_code') or '').split(',')
                                + (candidate.get('local_dialing_code') or '').split(',')
                            )
                            existing['lat'] = existing['lat'] if existing['lat'] is not None else candidate['lat']
                            existing['lon'] = existing['lon'] if existing['lon'] is not None else candidate['lon']
                            existing['name'] = choose_better_name(existing['name'], candidate['name'], qid)

                total += len(bindings)
                offset += limit
            save_cache(start + batch_size, rows_by_qid)
    except KeyboardInterrupt:
        print("interrupted by user; writing partial SQL from collected data...")

    rows = sorted(rows_by_qid.values(), key=lambda r: (r['country_iso'], r['name'], r['qid']))
    sql = render_sql(rows)

    OUT_SQL.write_text(sql, encoding='utf-8')
    print(f"bindings fetched: {total}")
    print(f"unique territories: {len(rows)}")
    print(f"wrote: {OUT_SQL}")
    print(f"cache: {CACHE_JSON}")
    if failed_isos:
        FAILED_JSON.write_text(json.dumps(sorted(set(failed_isos)), ensure_ascii=False, indent=2), encoding='utf-8')
        print(f"failed iso list: {FAILED_JSON}")


if __name__ == '__main__':
    main()

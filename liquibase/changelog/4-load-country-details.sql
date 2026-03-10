--liquibase formatted sql
--changeset codex:4-load-country-details dbms:postgresql
--comment Load extended country metadata (official name, ISO3, region, geo, timezones, currencies, languages, flags).

UPDATE country
SET
    official_name = 'Islamic Republic of Afghanistan',
    iso3_code = 'AFG',
    iso_numeric = '004',
    region = 'Asia',
    subregion = 'Southern Asia',
    capital = 'Kabul',
    latitude = 33.000000,
    longitude = 65.000000,
    area_km2 = 652230.00,
    tld = '[".af"]'::jsonb,
    timezones = '["UTC+04:30"]'::jsonb,
    currencies = '{"AFN":{"name":"Afghan afghani","symbol":"؋"}}'::jsonb,
    languages = '{"prs":"Dari","pus":"Pashto","tuk":"Turkmen"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'AF';

UPDATE country
SET
    official_name = 'Republic of Albania',
    iso3_code = 'ALB',
    iso_numeric = '008',
    region = 'Europe',
    subregion = 'Southeast Europe',
    capital = 'Tirana',
    latitude = 41.000000,
    longitude = 20.000000,
    area_km2 = 28748.00,
    tld = '[".al"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"ALL":{"name":"Albanian lek","symbol":"L"}}'::jsonb,
    languages = '{"sqi":"Albanian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'AL';

UPDATE country
SET
    official_name = 'People''s Democratic Republic of Algeria',
    iso3_code = 'DZA',
    iso_numeric = '012',
    region = 'Africa',
    subregion = 'Northern Africa',
    capital = 'Algiers',
    latitude = 28.000000,
    longitude = 3.000000,
    area_km2 = 2381741.00,
    tld = '[".dz","الجزائر."]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"DZD":{"name":"Algerian dinar","symbol":"د.ج"}}'::jsonb,
    languages = '{"ara":"Arabic"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'sunday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'DZ';

UPDATE country
SET
    official_name = 'Principality of Andorra',
    iso3_code = 'AND',
    iso_numeric = '020',
    region = 'Europe',
    subregion = 'Southern Europe',
    capital = 'Andorra la Vella',
    latitude = 42.500000,
    longitude = 1.500000,
    area_km2 = 468.00,
    tld = '[".ad"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"cat":"Catalan"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'AD';

UPDATE country
SET
    official_name = 'Republic of Angola',
    iso3_code = 'AGO',
    iso_numeric = '024',
    region = 'Africa',
    subregion = 'Middle Africa',
    capital = 'Luanda',
    latitude = -12.500000,
    longitude = 18.500000,
    area_km2 = 1246700.00,
    tld = '[".ao"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"AOA":{"name":"Angolan kwanza","symbol":"Kz"}}'::jsonb,
    languages = '{"por":"Portuguese"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'AO';

UPDATE country
SET
    official_name = 'Antigua and Barbuda',
    iso3_code = 'ATG',
    iso_numeric = '028',
    region = 'Americas',
    subregion = 'Caribbean',
    capital = 'Saint John''s',
    latitude = 17.050000,
    longitude = -61.800000,
    area_km2 = 442.00,
    tld = '[".ag"]'::jsonb,
    timezones = '["UTC-04:00"]'::jsonb,
    currencies = '{"XCD":{"name":"Eastern Caribbean dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'AG';

UPDATE country
SET
    official_name = 'Argentine Republic',
    iso3_code = 'ARG',
    iso_numeric = '032',
    region = 'Americas',
    subregion = 'South America',
    capital = 'Buenos Aires',
    latitude = -34.000000,
    longitude = -64.000000,
    area_km2 = 2780400.00,
    tld = '[".ar"]'::jsonb,
    timezones = '["UTC-03:00"]'::jsonb,
    currencies = '{"ARS":{"name":"Argentine peso","symbol":"$"}}'::jsonb,
    languages = '{"grn":"Guaraní","spa":"Spanish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'AR';

UPDATE country
SET
    official_name = 'Republic of Armenia',
    iso3_code = 'ARM',
    iso_numeric = '051',
    region = 'Asia',
    subregion = 'Western Asia',
    capital = 'Yerevan',
    latitude = 40.000000,
    longitude = 45.000000,
    area_km2 = 29743.00,
    tld = '[".am"]'::jsonb,
    timezones = '["UTC+04:00"]'::jsonb,
    currencies = '{"AMD":{"name":"Armenian dram","symbol":"֏"}}'::jsonb,
    languages = '{"hye":"Armenian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'AM';

UPDATE country
SET
    official_name = 'Commonwealth of Australia',
    iso3_code = 'AUS',
    iso_numeric = '036',
    region = 'Oceania',
    subregion = 'Australia and New Zealand',
    capital = 'Canberra',
    latitude = -27.000000,
    longitude = 133.000000,
    area_km2 = 7692024.00,
    tld = '[".au"]'::jsonb,
    timezones = '["UTC+05:00","UTC+06:30","UTC+07:00","UTC+08:00","UTC+09:30","UTC+10:00","UTC+10:30","UTC+11:30"]'::jsonb,
    currencies = '{"AUD":{"name":"Australian dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'AU';

UPDATE country
SET
    official_name = 'Republic of Austria',
    iso3_code = 'AUT',
    iso_numeric = '040',
    region = 'Europe',
    subregion = 'Central Europe',
    capital = 'Vienna',
    latitude = 47.333333,
    longitude = 13.333333,
    area_km2 = 83871.00,
    tld = '[".at"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"deu":"German"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'AT';

UPDATE country
SET
    official_name = 'Republic of Azerbaijan',
    iso3_code = 'AZE',
    iso_numeric = '031',
    region = 'Asia',
    subregion = 'Western Asia',
    capital = 'Baku',
    latitude = 40.500000,
    longitude = 47.500000,
    area_km2 = 86600.00,
    tld = '[".az"]'::jsonb,
    timezones = '["UTC+04:00"]'::jsonb,
    currencies = '{"AZN":{"name":"Azerbaijani manat","symbol":"₼"}}'::jsonb,
    languages = '{"aze":"Azerbaijani"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'AZ';

UPDATE country
SET
    official_name = 'Commonwealth of the Bahamas',
    iso3_code = 'BHS',
    iso_numeric = '044',
    region = 'Americas',
    subregion = 'Caribbean',
    capital = 'Nassau',
    latitude = 25.034300,
    longitude = -77.396300,
    area_km2 = 13943.00,
    tld = '[".bs"]'::jsonb,
    timezones = '["UTC-05:00"]'::jsonb,
    currencies = '{"BSD":{"name":"Bahamian dollar","symbol":"$"},"USD":{"name":"United States dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'BS';

UPDATE country
SET
    official_name = 'Kingdom of Bahrain',
    iso3_code = 'BHR',
    iso_numeric = '048',
    region = 'Asia',
    subregion = 'Western Asia',
    capital = 'Manama',
    latitude = 26.000000,
    longitude = 50.550000,
    area_km2 = 765.00,
    tld = '[".bh"]'::jsonb,
    timezones = '["UTC+03:00"]'::jsonb,
    currencies = '{"BHD":{"name":"Bahraini dinar","symbol":".د.ب"}}'::jsonb,
    languages = '{"ara":"Arabic"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'BH';

UPDATE country
SET
    official_name = 'People''s Republic of Bangladesh',
    iso3_code = 'BGD',
    iso_numeric = '050',
    region = 'Asia',
    subregion = 'Southern Asia',
    capital = 'Dhaka',
    latitude = 24.000000,
    longitude = 90.000000,
    area_km2 = 147570.00,
    tld = '[".bd"]'::jsonb,
    timezones = '["UTC+06:00"]'::jsonb,
    currencies = '{"BDT":{"name":"Bangladeshi taka","symbol":"৳"}}'::jsonb,
    languages = '{"ben":"Bengali"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'sunday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'BD';

UPDATE country
SET
    official_name = 'Barbados',
    iso3_code = 'BRB',
    iso_numeric = '052',
    region = 'Americas',
    subregion = 'Caribbean',
    capital = 'Bridgetown',
    latitude = 13.166667,
    longitude = -59.533333,
    area_km2 = 430.00,
    tld = '[".bb"]'::jsonb,
    timezones = '["UTC-04:00"]'::jsonb,
    currencies = '{"BBD":{"name":"Barbadian dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'BB';

UPDATE country
SET
    official_name = 'Republic of Belarus',
    iso3_code = 'BLR',
    iso_numeric = '112',
    region = 'Europe',
    subregion = 'Eastern Europe',
    capital = 'Minsk',
    latitude = 53.000000,
    longitude = 28.000000,
    area_km2 = 207600.00,
    tld = '[".by"]'::jsonb,
    timezones = '["UTC+03:00"]'::jsonb,
    currencies = '{"BYN":{"name":"Belarusian ruble","symbol":"Br"}}'::jsonb,
    languages = '{"bel":"Belarusian","rus":"Russian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'BY';

UPDATE country
SET
    official_name = 'Kingdom of Belgium',
    iso3_code = 'BEL',
    iso_numeric = '056',
    region = 'Europe',
    subregion = 'Western Europe',
    capital = 'Brussels',
    latitude = 50.833333,
    longitude = 4.000000,
    area_km2 = 30528.00,
    tld = '[".be"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"deu":"German","fra":"French","nld":"Dutch"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'BE';

UPDATE country
SET
    official_name = 'Belize',
    iso3_code = 'BLZ',
    iso_numeric = '084',
    region = 'Americas',
    subregion = 'Central America',
    capital = 'Belmopan',
    latitude = 17.250000,
    longitude = -88.750000,
    area_km2 = 22966.00,
    tld = '[".bz"]'::jsonb,
    timezones = '["UTC-06:00"]'::jsonb,
    currencies = '{"BZD":{"name":"Belize dollar","symbol":"$"}}'::jsonb,
    languages = '{"bjz":"Belizean Creole","eng":"English","spa":"Spanish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'BZ';

UPDATE country
SET
    official_name = 'Republic of Benin',
    iso3_code = 'BEN',
    iso_numeric = '204',
    region = 'Africa',
    subregion = 'Western Africa',
    capital = 'Porto-Novo',
    latitude = 9.500000,
    longitude = 2.250000,
    area_km2 = 112622.00,
    tld = '[".bj"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"XOF":{"name":"West African CFA franc","symbol":"Fr"}}'::jsonb,
    languages = '{"fra":"French"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'BJ';

UPDATE country
SET
    official_name = 'Kingdom of Bhutan',
    iso3_code = 'BTN',
    iso_numeric = '064',
    region = 'Asia',
    subregion = 'Southern Asia',
    capital = 'Thimphu',
    latitude = 27.500000,
    longitude = 90.500000,
    area_km2 = 38394.00,
    tld = '[".bt"]'::jsonb,
    timezones = '["UTC+06:00"]'::jsonb,
    currencies = '{"BTN":{"name":"Bhutanese ngultrum","symbol":"Nu."},"INR":{"name":"Indian rupee","symbol":"₹"}}'::jsonb,
    languages = '{"dzo":"Dzongkha"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'BT';

UPDATE country
SET
    official_name = 'Plurinational State of Bolivia',
    iso3_code = 'BOL',
    iso_numeric = '068',
    region = 'Americas',
    subregion = 'South America',
    capital = 'Sucre',
    latitude = -17.000000,
    longitude = -65.000000,
    area_km2 = 1098581.00,
    tld = '[".bo"]'::jsonb,
    timezones = '["UTC-04:00"]'::jsonb,
    currencies = '{"BOB":{"name":"Bolivian boliviano","symbol":"Bs."}}'::jsonb,
    languages = '{"aym":"Aymara","grn":"Guaraní","que":"Quechua","spa":"Spanish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'BO';

UPDATE country
SET
    official_name = 'Bosnia and Herzegovina',
    iso3_code = 'BIH',
    iso_numeric = '070',
    region = 'Europe',
    subregion = 'Southeast Europe',
    capital = 'Sarajevo',
    latitude = 44.000000,
    longitude = 18.000000,
    area_km2 = 51209.00,
    tld = '[".ba"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"BAM":{"name":"Bosnia and Herzegovina convertible mark","symbol":"KM"}}'::jsonb,
    languages = '{"bos":"Bosnian","hrv":"Croatian","srp":"Serbian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'BA';

UPDATE country
SET
    official_name = 'Republic of Botswana',
    iso3_code = 'BWA',
    iso_numeric = '072',
    region = 'Africa',
    subregion = 'Southern Africa',
    capital = 'Gaborone',
    latitude = -22.000000,
    longitude = 24.000000,
    area_km2 = 582000.00,
    tld = '[".bw"]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"BWP":{"name":"Botswana pula","symbol":"P"}}'::jsonb,
    languages = '{"eng":"English","tsn":"Tswana"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'BW';

UPDATE country
SET
    official_name = 'Federative Republic of Brazil',
    iso3_code = 'BRA',
    iso_numeric = '076',
    region = 'Americas',
    subregion = 'South America',
    capital = 'Brasília',
    latitude = -10.000000,
    longitude = -55.000000,
    area_km2 = 8515767.00,
    tld = '[".br"]'::jsonb,
    timezones = '["UTC-05:00","UTC-04:00","UTC-03:00","UTC-02:00"]'::jsonb,
    currencies = '{"BRL":{"name":"Brazilian real","symbol":"R$"}}'::jsonb,
    languages = '{"por":"Portuguese"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'sunday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'BR';

UPDATE country
SET
    official_name = 'Nation of Brunei, Abode of Peace',
    iso3_code = 'BRN',
    iso_numeric = '096',
    region = 'Asia',
    subregion = 'South-Eastern Asia',
    capital = 'Bandar Seri Begawan',
    latitude = 4.500000,
    longitude = 114.666667,
    area_km2 = 5765.00,
    tld = '[".bn"]'::jsonb,
    timezones = '["UTC+08:00"]'::jsonb,
    currencies = '{"BND":{"name":"Brunei dollar","symbol":"$"},"SGD":{"name":"Singapore dollar","symbol":"$"}}'::jsonb,
    languages = '{"msa":"Malay"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'BN';

UPDATE country
SET
    official_name = 'Republic of Bulgaria',
    iso3_code = 'BGR',
    iso_numeric = '100',
    region = 'Europe',
    subregion = 'Southeast Europe',
    capital = 'Sofia',
    latitude = 43.000000,
    longitude = 25.000000,
    area_km2 = 110879.00,
    tld = '[".bg"]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"BGN":{"name":"Bulgarian lev","symbol":"лв"}}'::jsonb,
    languages = '{"bul":"Bulgarian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'BG';

UPDATE country
SET
    official_name = 'Burkina Faso',
    iso3_code = 'BFA',
    iso_numeric = '854',
    region = 'Africa',
    subregion = 'Western Africa',
    capital = 'Ouagadougou',
    latitude = 13.000000,
    longitude = -2.000000,
    area_km2 = 272967.00,
    tld = '[".bf"]'::jsonb,
    timezones = '["UTC"]'::jsonb,
    currencies = '{"XOF":{"name":"West African CFA franc","symbol":"Fr"}}'::jsonb,
    languages = '{"fra":"French"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'BF';

UPDATE country
SET
    official_name = 'Republic of Burundi',
    iso3_code = 'BDI',
    iso_numeric = '108',
    region = 'Africa',
    subregion = 'Eastern Africa',
    capital = 'Gitega',
    latitude = -3.500000,
    longitude = 30.000000,
    area_km2 = 27834.00,
    tld = '[".bi"]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"BIF":{"name":"Burundian franc","symbol":"Fr"}}'::jsonb,
    languages = '{"fra":"French","run":"Kirundi"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'BI';

UPDATE country
SET
    official_name = 'Kingdom of Cambodia',
    iso3_code = 'KHM',
    iso_numeric = '116',
    region = 'Asia',
    subregion = 'South-Eastern Asia',
    capital = 'Phnom Penh',
    latitude = 13.000000,
    longitude = 105.000000,
    area_km2 = 181035.00,
    tld = '[".kh"]'::jsonb,
    timezones = '["UTC+07:00"]'::jsonb,
    currencies = '{"KHR":{"name":"Cambodian riel","symbol":"៛"},"USD":{"name":"United States dollar","symbol":"$"}}'::jsonb,
    languages = '{"khm":"Khmer"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'KH';

UPDATE country
SET
    official_name = 'Republic of Cameroon',
    iso3_code = 'CMR',
    iso_numeric = '120',
    region = 'Africa',
    subregion = 'Middle Africa',
    capital = 'Yaoundé',
    latitude = 6.000000,
    longitude = 12.000000,
    area_km2 = 475442.00,
    tld = '[".cm"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"XAF":{"name":"Central African CFA franc","symbol":"Fr"}}'::jsonb,
    languages = '{"eng":"English","fra":"French"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'CM';

UPDATE country
SET
    official_name = 'Canada',
    iso3_code = 'CAN',
    iso_numeric = '124',
    region = 'Americas',
    subregion = 'North America',
    capital = 'Ottawa',
    latitude = 60.000000,
    longitude = -95.000000,
    area_km2 = 9984670.00,
    tld = '[".ca"]'::jsonb,
    timezones = '["UTC-08:00","UTC-07:00","UTC-06:00","UTC-05:00","UTC-04:00","UTC-03:30"]'::jsonb,
    currencies = '{"CAD":{"name":"Canadian dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English","fra":"French"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'sunday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'CA';

UPDATE country
SET
    official_name = 'Republic of Cabo Verde',
    iso3_code = 'CPV',
    iso_numeric = '132',
    region = 'Africa',
    subregion = 'Western Africa',
    capital = 'Praia',
    latitude = 16.538800,
    longitude = -23.041800,
    area_km2 = 4033.00,
    tld = '[".cv"]'::jsonb,
    timezones = '["UTC-01:00"]'::jsonb,
    currencies = '{"CVE":{"name":"Cape Verdean escudo","symbol":"Esc"}}'::jsonb,
    languages = '{"por":"Portuguese"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'CV';

UPDATE country
SET
    official_name = 'Central African Republic',
    iso3_code = 'CAF',
    iso_numeric = '140',
    region = 'Africa',
    subregion = 'Middle Africa',
    capital = 'Bangui',
    latitude = 7.000000,
    longitude = 21.000000,
    area_km2 = 622984.00,
    tld = '[".cf"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"XAF":{"name":"Central African CFA franc","symbol":"Fr"}}'::jsonb,
    languages = '{"fra":"French","sag":"Sango"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'CF';

UPDATE country
SET
    official_name = 'Republic of Chad',
    iso3_code = 'TCD',
    iso_numeric = '148',
    region = 'Africa',
    subregion = 'Middle Africa',
    capital = 'N''Djamena',
    latitude = 15.000000,
    longitude = 19.000000,
    area_km2 = 1284000.00,
    tld = '[".td"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"XAF":{"name":"Central African CFA franc","symbol":"Fr"}}'::jsonb,
    languages = '{"ara":"Arabic","fra":"French"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'TD';

UPDATE country
SET
    official_name = 'Republic of Chile',
    iso3_code = 'CHL',
    iso_numeric = '152',
    region = 'Americas',
    subregion = 'South America',
    capital = 'Santiago',
    latitude = -30.000000,
    longitude = -71.000000,
    area_km2 = 756102.00,
    tld = '[".cl"]'::jsonb,
    timezones = '["UTC-06:00","UTC-04:00"]'::jsonb,
    currencies = '{"CLP":{"name":"Chilean peso","symbol":"$"}}'::jsonb,
    languages = '{"spa":"Spanish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'CL';

UPDATE country
SET
    official_name = 'People''s Republic of China',
    iso3_code = 'CHN',
    iso_numeric = '156',
    region = 'Asia',
    subregion = 'Eastern Asia',
    capital = 'Beijing',
    latitude = 35.000000,
    longitude = 105.000000,
    area_km2 = 9706961.00,
    tld = '[".cn",".中国",".中國",".公司",".网络"]'::jsonb,
    timezones = '["UTC+08:00"]'::jsonb,
    currencies = '{"CNY":{"name":"Chinese yuan","symbol":"¥"}}'::jsonb,
    languages = '{"zho":"Chinese"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'CN';

UPDATE country
SET
    official_name = 'Republic of Colombia',
    iso3_code = 'COL',
    iso_numeric = '170',
    region = 'Americas',
    subregion = 'South America',
    capital = 'Bogotá',
    latitude = 4.000000,
    longitude = -72.000000,
    area_km2 = 1141748.00,
    tld = '[".co"]'::jsonb,
    timezones = '["UTC-05:00"]'::jsonb,
    currencies = '{"COP":{"name":"Colombian peso","symbol":"$"}}'::jsonb,
    languages = '{"spa":"Spanish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'CO';

UPDATE country
SET
    official_name = 'Union of the Comoros',
    iso3_code = 'COM',
    iso_numeric = '174',
    region = 'Africa',
    subregion = 'Eastern Africa',
    capital = 'Moroni',
    latitude = -12.166667,
    longitude = 44.250000,
    area_km2 = 1862.00,
    tld = '[".km"]'::jsonb,
    timezones = '["UTC+03:00"]'::jsonb,
    currencies = '{"KMF":{"name":"Comorian franc","symbol":"Fr"}}'::jsonb,
    languages = '{"ara":"Arabic","fra":"French","zdj":"Comorian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'KM';

UPDATE country
SET
    official_name = 'Republic of the Congo',
    iso3_code = 'COG',
    iso_numeric = '178',
    region = 'Africa',
    subregion = 'Middle Africa',
    capital = 'Brazzaville',
    latitude = -1.000000,
    longitude = 15.000000,
    area_km2 = 342000.00,
    tld = '[".cg"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"XAF":{"name":"Central African CFA franc","symbol":"Fr"}}'::jsonb,
    languages = '{"fra":"French","kon":"Kikongo","lin":"Lingala"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'CG';

UPDATE country
SET
    official_name = 'Democratic Republic of the Congo',
    iso3_code = 'COD',
    iso_numeric = '180',
    region = 'Africa',
    subregion = 'Middle Africa',
    capital = 'Kinshasa',
    latitude = 0.000000,
    longitude = 25.000000,
    area_km2 = 2344858.00,
    tld = '[".cd"]'::jsonb,
    timezones = '["UTC+01:00","UTC+02:00"]'::jsonb,
    currencies = '{"CDF":{"name":"Congolese franc","symbol":"FC"}}'::jsonb,
    languages = '{"fra":"French","kon":"Kikongo","lin":"Lingala","lua":"Tshiluba","swa":"Swahili"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'CD';

UPDATE country
SET
    official_name = 'Republic of Costa Rica',
    iso3_code = 'CRI',
    iso_numeric = '188',
    region = 'Americas',
    subregion = 'Central America',
    capital = 'San José',
    latitude = 10.000000,
    longitude = -84.000000,
    area_km2 = 51100.00,
    tld = '[".cr"]'::jsonb,
    timezones = '["UTC-06:00"]'::jsonb,
    currencies = '{"CRC":{"name":"Costa Rican colón","symbol":"₡"}}'::jsonb,
    languages = '{"spa":"Spanish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'CR';

UPDATE country
SET
    official_name = 'Republic of Côte d''Ivoire',
    iso3_code = 'CIV',
    iso_numeric = '384',
    region = 'Africa',
    subregion = 'Western Africa',
    capital = 'Yamoussoukro',
    latitude = 8.000000,
    longitude = -5.000000,
    area_km2 = 322463.00,
    tld = '[".ci"]'::jsonb,
    timezones = '["UTC"]'::jsonb,
    currencies = '{"XOF":{"name":"West African CFA franc","symbol":"Fr"}}'::jsonb,
    languages = '{"fra":"French"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'CI';

UPDATE country
SET
    official_name = 'Republic of Croatia',
    iso3_code = 'HRV',
    iso_numeric = '191',
    region = 'Europe',
    subregion = 'Southeast Europe',
    capital = 'Zagreb',
    latitude = 45.166667,
    longitude = 15.500000,
    area_km2 = 56594.00,
    tld = '[".hr"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"hrv":"Croatian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'HR';

UPDATE country
SET
    official_name = 'Republic of Cuba',
    iso3_code = 'CUB',
    iso_numeric = '192',
    region = 'Americas',
    subregion = 'Caribbean',
    capital = 'Havana',
    latitude = 21.500000,
    longitude = -80.000000,
    area_km2 = 109884.00,
    tld = '[".cu"]'::jsonb,
    timezones = '["UTC-05:00"]'::jsonb,
    currencies = '{"CUC":{"name":"Cuban convertible peso","symbol":"$"},"CUP":{"name":"Cuban peso","symbol":"$"}}'::jsonb,
    languages = '{"spa":"Spanish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'CU';

UPDATE country
SET
    official_name = 'Republic of Cyprus',
    iso3_code = 'CYP',
    iso_numeric = '196',
    region = 'Europe',
    subregion = 'Southern Europe',
    capital = 'Nicosia',
    latitude = 35.000000,
    longitude = 33.000000,
    area_km2 = 9251.00,
    tld = '[".cy"]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"ell":"Greek","tur":"Turkish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'CY';

UPDATE country
SET
    official_name = 'Czech Republic',
    iso3_code = 'CZE',
    iso_numeric = '203',
    region = 'Europe',
    subregion = 'Central Europe',
    capital = 'Prague',
    latitude = 49.750000,
    longitude = 15.500000,
    area_km2 = 78865.00,
    tld = '[".cz"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"CZK":{"name":"Czech koruna","symbol":"Kč"}}'::jsonb,
    languages = '{"ces":"Czech","slk":"Slovak"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'CZ';

UPDATE country
SET
    official_name = 'Kingdom of Denmark',
    iso3_code = 'DNK',
    iso_numeric = '208',
    region = 'Europe',
    subregion = 'Northern Europe',
    capital = 'Copenhagen',
    latitude = 56.000000,
    longitude = 10.000000,
    area_km2 = 43094.00,
    tld = '[".dk"]'::jsonb,
    timezones = '["UTC-04:00","UTC-03:00","UTC-01:00","UTC","UTC+01:00"]'::jsonb,
    currencies = '{"DKK":{"name":"Danish krone","symbol":"kr"}}'::jsonb,
    languages = '{"dan":"Danish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'DK';

UPDATE country
SET
    official_name = 'Republic of Djibouti',
    iso3_code = 'DJI',
    iso_numeric = '262',
    region = 'Africa',
    subregion = 'Eastern Africa',
    capital = 'Djibouti',
    latitude = 11.500000,
    longitude = 43.000000,
    area_km2 = 23200.00,
    tld = '[".dj"]'::jsonb,
    timezones = '["UTC+03:00"]'::jsonb,
    currencies = '{"DJF":{"name":"Djiboutian franc","symbol":"Fr"}}'::jsonb,
    languages = '{"ara":"Arabic","fra":"French"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'DJ';

UPDATE country
SET
    official_name = 'Commonwealth of Dominica',
    iso3_code = 'DMA',
    iso_numeric = '212',
    region = 'Americas',
    subregion = 'Caribbean',
    capital = 'Roseau',
    latitude = 15.416667,
    longitude = -61.333333,
    area_km2 = 751.00,
    tld = '[".dm"]'::jsonb,
    timezones = '["UTC-04:00"]'::jsonb,
    currencies = '{"XCD":{"name":"Eastern Caribbean dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'DM';

UPDATE country
SET
    official_name = 'Dominican Republic',
    iso3_code = 'DOM',
    iso_numeric = '214',
    region = 'Americas',
    subregion = 'Caribbean',
    capital = 'Santo Domingo',
    latitude = 19.000000,
    longitude = -70.666667,
    area_km2 = 48671.00,
    tld = '[".do"]'::jsonb,
    timezones = '["UTC-04:00"]'::jsonb,
    currencies = '{"DOP":{"name":"Dominican peso","symbol":"$"}}'::jsonb,
    languages = '{"spa":"Spanish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'DO';

UPDATE country
SET
    official_name = 'Republic of Ecuador',
    iso3_code = 'ECU',
    iso_numeric = '218',
    region = 'Americas',
    subregion = 'South America',
    capital = 'Quito',
    latitude = -2.000000,
    longitude = -77.500000,
    area_km2 = 276841.00,
    tld = '[".ec"]'::jsonb,
    timezones = '["UTC-06:00","UTC-05:00"]'::jsonb,
    currencies = '{"USD":{"name":"United States dollar","symbol":"$"}}'::jsonb,
    languages = '{"spa":"Spanish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'EC';

UPDATE country
SET
    official_name = 'Arab Republic of Egypt',
    iso3_code = 'EGY',
    iso_numeric = '818',
    region = 'Africa',
    subregion = 'Northern Africa',
    capital = 'Cairo',
    latitude = 27.000000,
    longitude = 30.000000,
    area_km2 = 1002450.00,
    tld = '[".eg",".مصر"]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"EGP":{"name":"Egyptian pound","symbol":"£"}}'::jsonb,
    languages = '{"ara":"Arabic"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'sunday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'EG';

UPDATE country
SET
    official_name = 'Republic of El Salvador',
    iso3_code = 'SLV',
    iso_numeric = '222',
    region = 'Americas',
    subregion = 'Central America',
    capital = 'San Salvador',
    latitude = 13.833333,
    longitude = -88.916667,
    area_km2 = 21041.00,
    tld = '[".sv"]'::jsonb,
    timezones = '["UTC-06:00"]'::jsonb,
    currencies = '{"USD":{"name":"United States dollar","symbol":"$"}}'::jsonb,
    languages = '{"spa":"Spanish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'SV';

UPDATE country
SET
    official_name = 'Republic of Equatorial Guinea',
    iso3_code = 'GNQ',
    iso_numeric = '226',
    region = 'Africa',
    subregion = 'Middle Africa',
    capital = 'Ciudad de la Paz',
    latitude = 2.000000,
    longitude = 10.000000,
    area_km2 = 28051.00,
    tld = '[".gq"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"XAF":{"name":"Central African CFA franc","symbol":"Fr"}}'::jsonb,
    languages = '{"fra":"French","por":"Portuguese","spa":"Spanish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'GQ';

UPDATE country
SET
    official_name = 'State of Eritrea',
    iso3_code = 'ERI',
    iso_numeric = '232',
    region = 'Africa',
    subregion = 'Eastern Africa',
    capital = 'Asmara',
    latitude = 15.000000,
    longitude = 39.000000,
    area_km2 = 117600.00,
    tld = '[".er"]'::jsonb,
    timezones = '["UTC+03:00"]'::jsonb,
    currencies = '{"ERN":{"name":"Eritrean nakfa","symbol":"Nfk"}}'::jsonb,
    languages = '{"ara":"Arabic","eng":"English","tir":"Tigrinya"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'ER';

UPDATE country
SET
    official_name = 'Republic of Estonia',
    iso3_code = 'EST',
    iso_numeric = '233',
    region = 'Europe',
    subregion = 'Northern Europe',
    capital = 'Tallinn',
    latitude = 59.000000,
    longitude = 26.000000,
    area_km2 = 45227.00,
    tld = '[".ee"]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"est":"Estonian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'EE';

UPDATE country
SET
    official_name = 'Kingdom of Eswatini',
    iso3_code = 'SWZ',
    iso_numeric = '748',
    region = 'Africa',
    subregion = 'Southern Africa',
    capital = 'Mbabane',
    latitude = -26.500000,
    longitude = 31.500000,
    area_km2 = 17364.00,
    tld = '[".sz"]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"SZL":{"name":"Swazi lilangeni","symbol":"L"},"ZAR":{"name":"South African rand","symbol":"R"}}'::jsonb,
    languages = '{"eng":"English","ssw":"Swazi"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'SZ';

UPDATE country
SET
    official_name = 'Federal Democratic Republic of Ethiopia',
    iso3_code = 'ETH',
    iso_numeric = '231',
    region = 'Africa',
    subregion = 'Eastern Africa',
    capital = 'Addis Ababa',
    latitude = 8.000000,
    longitude = 38.000000,
    area_km2 = 1104300.00,
    tld = '[".et"]'::jsonb,
    timezones = '["UTC+03:00"]'::jsonb,
    currencies = '{"ETB":{"name":"Ethiopian birr","symbol":"Br"}}'::jsonb,
    languages = '{"amh":"Amharic"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'ET';

UPDATE country
SET
    official_name = 'Republic of Fiji',
    iso3_code = 'FJI',
    iso_numeric = '242',
    region = 'Oceania',
    subregion = 'Melanesia',
    capital = 'Suva',
    latitude = -17.713400,
    longitude = 178.065000,
    area_km2 = 18272.00,
    tld = '[".fj"]'::jsonb,
    timezones = '["UTC+12:00"]'::jsonb,
    currencies = '{"FJD":{"name":"Fijian dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English","fij":"Fijian","hif":"Fiji Hindi"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'FJ';

UPDATE country
SET
    official_name = 'Republic of Finland',
    iso3_code = 'FIN',
    iso_numeric = '246',
    region = 'Europe',
    subregion = 'Northern Europe',
    capital = 'Helsinki',
    latitude = 64.000000,
    longitude = 26.000000,
    area_km2 = 338455.00,
    tld = '[".fi"]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"fin":"Finnish","swe":"Swedish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'FI';

UPDATE country
SET
    official_name = 'French Republic',
    iso3_code = 'FRA',
    iso_numeric = '250',
    region = 'Europe',
    subregion = 'Western Europe',
    capital = 'Paris',
    latitude = 46.000000,
    longitude = 2.000000,
    area_km2 = 543908.00,
    tld = '[".fr"]'::jsonb,
    timezones = '["UTC-10:00","UTC-09:30","UTC-09:00","UTC-08:00","UTC-04:00","UTC-03:00","UTC+01:00","UTC+02:00","UTC+03:00","UTC+04:00","UTC+05:00","UTC+10:00","UTC+11:00","UTC+12:00"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"fra":"French"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'FR';

UPDATE country
SET
    official_name = 'Gabonese Republic',
    iso3_code = 'GAB',
    iso_numeric = '266',
    region = 'Africa',
    subregion = 'Middle Africa',
    capital = 'Libreville',
    latitude = -1.000000,
    longitude = 11.750000,
    area_km2 = 267668.00,
    tld = '[".ga"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"XAF":{"name":"Central African CFA franc","symbol":"Fr"}}'::jsonb,
    languages = '{"fra":"French"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'GA';

UPDATE country
SET
    official_name = 'Republic of the Gambia',
    iso3_code = 'GMB',
    iso_numeric = '270',
    region = 'Africa',
    subregion = 'Western Africa',
    capital = 'Banjul',
    latitude = 13.466667,
    longitude = -16.566667,
    area_km2 = 10689.00,
    tld = '[".gm"]'::jsonb,
    timezones = '["UTC+00:00"]'::jsonb,
    currencies = '{"GMD":{"name":"dalasi","symbol":"D"}}'::jsonb,
    languages = '{"eng":"English"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'GM';

UPDATE country
SET
    official_name = 'Georgia',
    iso3_code = 'GEO',
    iso_numeric = '268',
    region = 'Asia',
    subregion = 'Western Asia',
    capital = 'Tbilisi',
    latitude = 42.000000,
    longitude = 43.500000,
    area_km2 = 69700.00,
    tld = '[".ge"]'::jsonb,
    timezones = '["UTC+04:00"]'::jsonb,
    currencies = '{"GEL":{"name":"lari","symbol":"₾"}}'::jsonb,
    languages = '{"kat":"Georgian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'GE';

UPDATE country
SET
    official_name = 'Federal Republic of Germany',
    iso3_code = 'DEU',
    iso_numeric = '276',
    region = 'Europe',
    subregion = 'Western Europe',
    capital = 'Berlin',
    latitude = 51.000000,
    longitude = 9.000000,
    area_km2 = 357114.00,
    tld = '[".de"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"deu":"German"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'DE';

UPDATE country
SET
    official_name = 'Republic of Ghana',
    iso3_code = 'GHA',
    iso_numeric = '288',
    region = 'Africa',
    subregion = 'Western Africa',
    capital = 'Accra',
    latitude = 8.000000,
    longitude = -2.000000,
    area_km2 = 238533.00,
    tld = '[".gh"]'::jsonb,
    timezones = '["UTC"]'::jsonb,
    currencies = '{"GHS":{"name":"Ghanaian cedi","symbol":"₵"}}'::jsonb,
    languages = '{"eng":"English"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'GH';

UPDATE country
SET
    official_name = 'Hellenic Republic',
    iso3_code = 'GRC',
    iso_numeric = '300',
    region = 'Europe',
    subregion = 'Southern Europe',
    capital = 'Athens',
    latitude = 39.000000,
    longitude = 22.000000,
    area_km2 = 131990.00,
    tld = '[".gr"]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"ell":"Greek"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'GR';

UPDATE country
SET
    official_name = 'Grenada',
    iso3_code = 'GRD',
    iso_numeric = '308',
    region = 'Americas',
    subregion = 'Caribbean',
    capital = 'St. George''s',
    latitude = 12.116667,
    longitude = -61.666667,
    area_km2 = 344.00,
    tld = '[".gd"]'::jsonb,
    timezones = '["UTC-04:00"]'::jsonb,
    currencies = '{"XCD":{"name":"Eastern Caribbean dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'GD';

UPDATE country
SET
    official_name = 'Republic of Guatemala',
    iso3_code = 'GTM',
    iso_numeric = '320',
    region = 'Americas',
    subregion = 'Central America',
    capital = 'Guatemala City',
    latitude = 15.500000,
    longitude = -90.250000,
    area_km2 = 108889.00,
    tld = '[".gt"]'::jsonb,
    timezones = '["UTC-06:00"]'::jsonb,
    currencies = '{"GTQ":{"name":"Guatemalan quetzal","symbol":"Q"}}'::jsonb,
    languages = '{"spa":"Spanish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'GT';

UPDATE country
SET
    official_name = 'Republic of Guinea',
    iso3_code = 'GIN',
    iso_numeric = '324',
    region = 'Africa',
    subregion = 'Western Africa',
    capital = 'Conakry',
    latitude = 11.000000,
    longitude = -10.000000,
    area_km2 = 245857.00,
    tld = '[".gn"]'::jsonb,
    timezones = '["UTC"]'::jsonb,
    currencies = '{"GNF":{"name":"Guinean franc","symbol":"Fr"}}'::jsonb,
    languages = '{"fra":"French"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'GN';

UPDATE country
SET
    official_name = 'Republic of Guinea-Bissau',
    iso3_code = 'GNB',
    iso_numeric = '624',
    region = 'Africa',
    subregion = 'Western Africa',
    capital = 'Bissau',
    latitude = 12.000000,
    longitude = -15.000000,
    area_km2 = 36125.00,
    tld = '[".gw"]'::jsonb,
    timezones = '["UTC"]'::jsonb,
    currencies = '{"XOF":{"name":"West African CFA franc","symbol":"Fr"}}'::jsonb,
    languages = '{"por":"Portuguese","pov":"Upper Guinea Creole"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = FALSE,
    independent = TRUE
WHERE iso_code = 'GW';

UPDATE country
SET
    official_name = 'Co-operative Republic of Guyana',
    iso3_code = 'GUY',
    iso_numeric = '328',
    region = 'Americas',
    subregion = 'South America',
    capital = 'Georgetown',
    latitude = 5.000000,
    longitude = -59.000000,
    area_km2 = 214969.00,
    tld = '[".gy"]'::jsonb,
    timezones = '["UTC-04:00"]'::jsonb,
    currencies = '{"GYD":{"name":"Guyanese dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'GY';

UPDATE country
SET
    official_name = 'Republic of Haiti',
    iso3_code = 'HTI',
    iso_numeric = '332',
    region = 'Americas',
    subregion = 'Caribbean',
    capital = 'Port-au-Prince',
    latitude = 19.000000,
    longitude = -72.416667,
    area_km2 = 27750.00,
    tld = '[".ht"]'::jsonb,
    timezones = '["UTC-05:00"]'::jsonb,
    currencies = '{"HTG":{"name":"Haitian gourde","symbol":"G"}}'::jsonb,
    languages = '{"fra":"French","hat":"Haitian Creole"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'HT';

UPDATE country
SET
    official_name = 'Republic of Honduras',
    iso3_code = 'HND',
    iso_numeric = '340',
    region = 'Americas',
    subregion = 'Central America',
    capital = 'Tegucigalpa',
    latitude = 15.000000,
    longitude = -86.500000,
    area_km2 = 112492.00,
    tld = '[".hn"]'::jsonb,
    timezones = '["UTC-06:00"]'::jsonb,
    currencies = '{"HNL":{"name":"Honduran lempira","symbol":"L"}}'::jsonb,
    languages = '{"spa":"Spanish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'HN';

UPDATE country
SET
    official_name = 'Hungary',
    iso3_code = 'HUN',
    iso_numeric = '348',
    region = 'Europe',
    subregion = 'Central Europe',
    capital = 'Budapest',
    latitude = 47.000000,
    longitude = 20.000000,
    area_km2 = 93028.00,
    tld = '[".hu"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"HUF":{"name":"Hungarian forint","symbol":"Ft"}}'::jsonb,
    languages = '{"hun":"Hungarian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'HU';

UPDATE country
SET
    official_name = 'Iceland',
    iso3_code = 'ISL',
    iso_numeric = '352',
    region = 'Europe',
    subregion = 'Northern Europe',
    capital = 'Reykjavik',
    latitude = 65.000000,
    longitude = -18.000000,
    area_km2 = 103000.00,
    tld = '[".is"]'::jsonb,
    timezones = '["UTC"]'::jsonb,
    currencies = '{"ISK":{"name":"Icelandic króna","symbol":"kr"}}'::jsonb,
    languages = '{"isl":"Icelandic"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'IS';

UPDATE country
SET
    official_name = 'Republic of India',
    iso3_code = 'IND',
    iso_numeric = '356',
    region = 'Asia',
    subregion = 'Southern Asia',
    capital = 'New Delhi',
    latitude = 20.000000,
    longitude = 77.000000,
    area_km2 = 3287263.00,
    tld = '[".in"]'::jsonb,
    timezones = '["UTC+05:30"]'::jsonb,
    currencies = '{"INR":{"name":"Indian rupee","symbol":"₹"}}'::jsonb,
    languages = '{"eng":"English","hin":"Hindi","tam":"Tamil"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'IN';

UPDATE country
SET
    official_name = 'Republic of Indonesia',
    iso3_code = 'IDN',
    iso_numeric = '360',
    region = 'Asia',
    subregion = 'South-Eastern Asia',
    capital = 'Jakarta',
    latitude = -5.000000,
    longitude = 120.000000,
    area_km2 = 1904569.00,
    tld = '[".id"]'::jsonb,
    timezones = '["UTC+07:00","UTC+08:00","UTC+09:00"]'::jsonb,
    currencies = '{"IDR":{"name":"Indonesian rupiah","symbol":"Rp"}}'::jsonb,
    languages = '{"ind":"Indonesian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'ID';

UPDATE country
SET
    official_name = 'Islamic Republic of Iran',
    iso3_code = 'IRN',
    iso_numeric = '364',
    region = 'Asia',
    subregion = 'Southern Asia',
    capital = 'Tehran',
    latitude = 32.000000,
    longitude = 53.000000,
    area_km2 = 1648195.00,
    tld = '[".ir","ایران."]'::jsonb,
    timezones = '["UTC+03:30"]'::jsonb,
    currencies = '{"IRR":{"name":"Iranian rial","symbol":"﷼"}}'::jsonb,
    languages = '{"fas":"Persian (Farsi)"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'saturday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'IR';

UPDATE country
SET
    official_name = 'Republic of Iraq',
    iso3_code = 'IRQ',
    iso_numeric = '368',
    region = 'Asia',
    subregion = 'Western Asia',
    capital = 'Baghdad',
    latitude = 33.000000,
    longitude = 44.000000,
    area_km2 = 438317.00,
    tld = '[".iq"]'::jsonb,
    timezones = '["UTC+03:00"]'::jsonb,
    currencies = '{"IQD":{"name":"Iraqi dinar","symbol":"ع.د"}}'::jsonb,
    languages = '{"ara":"Arabic","arc":"Aramaic","ckb":"Sorani"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'sunday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'IQ';

UPDATE country
SET
    official_name = 'Republic of Ireland',
    iso3_code = 'IRL',
    iso_numeric = '372',
    region = 'Europe',
    subregion = 'Northern Europe',
    capital = 'Dublin',
    latitude = 53.000000,
    longitude = -8.000000,
    area_km2 = 70273.00,
    tld = '[".ie"]'::jsonb,
    timezones = '["UTC"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"eng":"English","gle":"Irish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'IE';

UPDATE country
SET
    official_name = 'State of Israel',
    iso3_code = 'ISR',
    iso_numeric = '376',
    region = 'Asia',
    subregion = 'Western Asia',
    capital = 'Jerusalem',
    latitude = 31.470000,
    longitude = 35.130000,
    area_km2 = 21937.00,
    tld = '[".il"]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"ILS":{"name":"Israeli new shekel","symbol":"₪"}}'::jsonb,
    languages = '{"ara":"Arabic","heb":"Hebrew"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'sunday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'IL';

UPDATE country
SET
    official_name = 'Italian Republic',
    iso3_code = 'ITA',
    iso_numeric = '380',
    region = 'Europe',
    subregion = 'Southern Europe',
    capital = 'Rome',
    latitude = 42.833333,
    longitude = 12.833333,
    area_km2 = 301336.00,
    tld = '[".it"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"ita":"Italian","cat":"Catalan"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'IT';

UPDATE country
SET
    official_name = 'Jamaica',
    iso3_code = 'JAM',
    iso_numeric = '388',
    region = 'Americas',
    subregion = 'Caribbean',
    capital = 'Kingston',
    latitude = 18.250000,
    longitude = -77.500000,
    area_km2 = 10991.00,
    tld = '[".jm"]'::jsonb,
    timezones = '["UTC-05:00"]'::jsonb,
    currencies = '{"JMD":{"name":"Jamaican dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English","jam":"Jamaican Patois"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'JM';

UPDATE country
SET
    official_name = 'Japan',
    iso3_code = 'JPN',
    iso_numeric = '392',
    region = 'Asia',
    subregion = 'Eastern Asia',
    capital = 'Tokyo',
    latitude = 36.000000,
    longitude = 138.000000,
    area_km2 = 377930.00,
    tld = '[".jp",".みんな"]'::jsonb,
    timezones = '["UTC+09:00"]'::jsonb,
    currencies = '{"JPY":{"name":"Japanese yen","symbol":"¥"}}'::jsonb,
    languages = '{"jpn":"Japanese"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'JP';

UPDATE country
SET
    official_name = 'Hashemite Kingdom of Jordan',
    iso3_code = 'JOR',
    iso_numeric = '400',
    region = 'Asia',
    subregion = 'Western Asia',
    capital = 'Amman',
    latitude = 31.000000,
    longitude = 36.000000,
    area_km2 = 89342.00,
    tld = '[".jo","الاردن."]'::jsonb,
    timezones = '["UTC+03:00"]'::jsonb,
    currencies = '{"JOD":{"name":"Jordanian dinar","symbol":"د.ا"}}'::jsonb,
    languages = '{"ara":"Arabic"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'sunday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'JO';

UPDATE country
SET
    official_name = 'Republic of Kazakhstan',
    iso3_code = 'KAZ',
    iso_numeric = '398',
    region = 'Asia',
    subregion = 'Central Asia',
    capital = 'Astana',
    latitude = 48.019600,
    longitude = 66.923700,
    area_km2 = 2724900.00,
    tld = '[".kz",".қаз"]'::jsonb,
    timezones = '["UTC+05:00","UTC+06:00"]'::jsonb,
    currencies = '{"KZT":{"name":"Kazakhstani tenge","symbol":"₸"}}'::jsonb,
    languages = '{"kaz":"Kazakh","rus":"Russian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'KZ';

UPDATE country
SET
    official_name = 'Republic of Kenya',
    iso3_code = 'KEN',
    iso_numeric = '404',
    region = 'Africa',
    subregion = 'Eastern Africa',
    capital = 'Nairobi',
    latitude = 1.000000,
    longitude = 38.000000,
    area_km2 = 580367.00,
    tld = '[".ke"]'::jsonb,
    timezones = '["UTC+03:00"]'::jsonb,
    currencies = '{"KES":{"name":"Kenyan shilling","symbol":"Sh"}}'::jsonb,
    languages = '{"eng":"English","swa":"Swahili"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'KE';

UPDATE country
SET
    official_name = 'Independent and Sovereign Republic of Kiribati',
    iso3_code = 'KIR',
    iso_numeric = '296',
    region = 'Oceania',
    subregion = 'Micronesia',
    capital = 'South Tarawa',
    latitude = 1.416667,
    longitude = 173.000000,
    area_km2 = 811.00,
    tld = '[".ki"]'::jsonb,
    timezones = '["UTC+12:00","UTC+13:00","UTC+14:00"]'::jsonb,
    currencies = '{"AUD":{"name":"Australian dollar","symbol":"$"},"KID":{"name":"Kiribati dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English","gil":"Gilbertese"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'KI';

UPDATE country
SET
    official_name = 'Democratic People''s Republic of Korea',
    iso3_code = 'PRK',
    iso_numeric = '408',
    region = 'Asia',
    subregion = 'Eastern Asia',
    capital = 'Pyongyang',
    latitude = 40.000000,
    longitude = 127.000000,
    area_km2 = 120538.00,
    tld = '[".kp"]'::jsonb,
    timezones = '["UTC+09:00"]'::jsonb,
    currencies = '{"KPW":{"name":"North Korean won","symbol":"₩"}}'::jsonb,
    languages = '{"kor":"Korean"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'KP';

UPDATE country
SET
    official_name = 'Republic of Korea',
    iso3_code = 'KOR',
    iso_numeric = '410',
    region = 'Asia',
    subregion = 'Eastern Asia',
    capital = 'Seoul',
    latitude = 37.000000,
    longitude = 127.500000,
    area_km2 = 100210.00,
    tld = '[".kr",".한국"]'::jsonb,
    timezones = '["UTC+09:00"]'::jsonb,
    currencies = '{"KRW":{"name":"South Korean won","symbol":"₩"}}'::jsonb,
    languages = '{"kor":"Korean"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'KR';

UPDATE country
SET
    official_name = 'State of Kuwait',
    iso3_code = 'KWT',
    iso_numeric = '414',
    region = 'Asia',
    subregion = 'Western Asia',
    capital = 'Kuwait City',
    latitude = 29.500000,
    longitude = 45.750000,
    area_km2 = 17818.00,
    tld = '[".kw"]'::jsonb,
    timezones = '["UTC+03:00"]'::jsonb,
    currencies = '{"KWD":{"name":"Kuwaiti dinar","symbol":"د.ك"}}'::jsonb,
    languages = '{"ara":"Arabic"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'sunday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'KW';

UPDATE country
SET
    official_name = 'Kyrgyz Republic',
    iso3_code = 'KGZ',
    iso_numeric = '417',
    region = 'Asia',
    subregion = 'Central Asia',
    capital = 'Bishkek',
    latitude = 41.000000,
    longitude = 75.000000,
    area_km2 = 199951.00,
    tld = '[".kg"]'::jsonb,
    timezones = '["UTC+06:00"]'::jsonb,
    currencies = '{"KGS":{"name":"Kyrgyzstani som","symbol":"с"}}'::jsonb,
    languages = '{"kir":"Kyrgyz","rus":"Russian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'KG';

UPDATE country
SET
    official_name = 'Lao People''s Democratic Republic',
    iso3_code = 'LAO',
    iso_numeric = '418',
    region = 'Asia',
    subregion = 'South-Eastern Asia',
    capital = 'Vientiane',
    latitude = 18.000000,
    longitude = 105.000000,
    area_km2 = 236800.00,
    tld = '[".la"]'::jsonb,
    timezones = '["UTC+07:00"]'::jsonb,
    currencies = '{"LAK":{"name":"Lao kip","symbol":"₭"}}'::jsonb,
    languages = '{"lao":"Lao"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'LA';

UPDATE country
SET
    official_name = 'Republic of Latvia',
    iso3_code = 'LVA',
    iso_numeric = '428',
    region = 'Europe',
    subregion = 'Northern Europe',
    capital = 'Riga',
    latitude = 57.000000,
    longitude = 25.000000,
    area_km2 = 64559.00,
    tld = '[".lv"]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"lav":"Latvian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'LV';

UPDATE country
SET
    official_name = 'Lebanese Republic',
    iso3_code = 'LBN',
    iso_numeric = '422',
    region = 'Asia',
    subregion = 'Western Asia',
    capital = 'Beirut',
    latitude = 33.833333,
    longitude = 35.833333,
    area_km2 = 10452.00,
    tld = '[".lb"]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"LBP":{"name":"Lebanese pound","symbol":"ل.ل"}}'::jsonb,
    languages = '{"ara":"Arabic","fra":"French"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'LB';

UPDATE country
SET
    official_name = 'Kingdom of Lesotho',
    iso3_code = 'LSO',
    iso_numeric = '426',
    region = 'Africa',
    subregion = 'Southern Africa',
    capital = 'Maseru',
    latitude = -29.500000,
    longitude = 28.500000,
    area_km2 = 30355.00,
    tld = '[".ls"]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"LSL":{"name":"Lesotho loti","symbol":"L"},"ZAR":{"name":"South African rand","symbol":"R"}}'::jsonb,
    languages = '{"eng":"English","sot":"Sotho"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'LS';

UPDATE country
SET
    official_name = 'Republic of Liberia',
    iso3_code = 'LBR',
    iso_numeric = '430',
    region = 'Africa',
    subregion = 'Western Africa',
    capital = 'Monrovia',
    latitude = 6.500000,
    longitude = -9.500000,
    area_km2 = 111369.00,
    tld = '[".lr"]'::jsonb,
    timezones = '["UTC"]'::jsonb,
    currencies = '{"LRD":{"name":"Liberian dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'LR';

UPDATE country
SET
    official_name = 'State of Libya',
    iso3_code = 'LBY',
    iso_numeric = '434',
    region = 'Africa',
    subregion = 'Northern Africa',
    capital = 'Tripoli',
    latitude = 25.000000,
    longitude = 17.000000,
    area_km2 = 1759540.00,
    tld = '[".ly"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"LYD":{"name":"Libyan dinar","symbol":"ل.د"}}'::jsonb,
    languages = '{"ara":"Arabic"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'sunday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'LY';

UPDATE country
SET
    official_name = 'Principality of Liechtenstein',
    iso3_code = 'LIE',
    iso_numeric = '438',
    region = 'Europe',
    subregion = 'Western Europe',
    capital = 'Vaduz',
    latitude = 47.266667,
    longitude = 9.533333,
    area_km2 = 160.00,
    tld = '[".li"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"CHF":{"name":"Swiss franc","symbol":"Fr"}}'::jsonb,
    languages = '{"deu":"German"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'LI';

UPDATE country
SET
    official_name = 'Republic of Lithuania',
    iso3_code = 'LTU',
    iso_numeric = '440',
    region = 'Europe',
    subregion = 'Northern Europe',
    capital = 'Vilnius',
    latitude = 56.000000,
    longitude = 24.000000,
    area_km2 = 65300.00,
    tld = '[".lt"]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"lit":"Lithuanian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'LT';

UPDATE country
SET
    official_name = 'Grand Duchy of Luxembourg',
    iso3_code = 'LUX',
    iso_numeric = '442',
    region = 'Europe',
    subregion = 'Western Europe',
    capital = 'Luxembourg',
    latitude = 49.750000,
    longitude = 6.166667,
    area_km2 = 2586.00,
    tld = '[".lu"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"deu":"German","fra":"French","ltz":"Luxembourgish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'LU';

UPDATE country
SET
    official_name = 'Republic of Madagascar',
    iso3_code = 'MDG',
    iso_numeric = '450',
    region = 'Africa',
    subregion = 'Eastern Africa',
    capital = 'Antananarivo',
    latitude = -20.000000,
    longitude = 47.000000,
    area_km2 = 587041.00,
    tld = '[".mg"]'::jsonb,
    timezones = '["UTC+03:00"]'::jsonb,
    currencies = '{"MGA":{"name":"Malagasy ariary","symbol":"Ar"}}'::jsonb,
    languages = '{"fra":"French","mlg":"Malagasy"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'MG';

UPDATE country
SET
    official_name = 'Republic of Malawi',
    iso3_code = 'MWI',
    iso_numeric = '454',
    region = 'Africa',
    subregion = 'Eastern Africa',
    capital = 'Lilongwe',
    latitude = -13.500000,
    longitude = 34.000000,
    area_km2 = 118484.00,
    tld = '[".mw"]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"MWK":{"name":"Malawian kwacha","symbol":"MK"}}'::jsonb,
    languages = '{"eng":"English","nya":"Chewa"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'MW';

UPDATE country
SET
    official_name = 'Malaysia',
    iso3_code = 'MYS',
    iso_numeric = '458',
    region = 'Asia',
    subregion = 'South-Eastern Asia',
    capital = 'Kuala Lumpur',
    latitude = 2.500000,
    longitude = 112.500000,
    area_km2 = 330803.00,
    tld = '[".my"]'::jsonb,
    timezones = '["UTC+08:00"]'::jsonb,
    currencies = '{"MYR":{"name":"Malaysian ringgit","symbol":"RM"}}'::jsonb,
    languages = '{"eng":"English","msa":"Malay"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'sunday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'MY';

UPDATE country
SET
    official_name = 'Republic of the Maldives',
    iso3_code = 'MDV',
    iso_numeric = '462',
    region = 'Asia',
    subregion = 'Southern Asia',
    capital = 'Malé',
    latitude = 3.250000,
    longitude = 73.000000,
    area_km2 = 300.00,
    tld = '[".mv"]'::jsonb,
    timezones = '["UTC+05:00"]'::jsonb,
    currencies = '{"MVR":{"name":"Maldivian rufiyaa","symbol":".ރ"}}'::jsonb,
    languages = '{"div":"Maldivian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'sunday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'MV';

UPDATE country
SET
    official_name = 'Republic of Mali',
    iso3_code = 'MLI',
    iso_numeric = '466',
    region = 'Africa',
    subregion = 'Western Africa',
    capital = 'Bamako',
    latitude = 17.000000,
    longitude = -4.000000,
    area_km2 = 1240192.00,
    tld = '[".ml"]'::jsonb,
    timezones = '["UTC"]'::jsonb,
    currencies = '{"XOF":{"name":"West African CFA franc","symbol":"Fr"}}'::jsonb,
    languages = '{"fra":"French"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'ML';

UPDATE country
SET
    official_name = 'Republic of Malta',
    iso3_code = 'MLT',
    iso_numeric = '470',
    region = 'Europe',
    subregion = 'Southern Europe',
    capital = 'Valletta',
    latitude = 35.937500,
    longitude = 14.375400,
    area_km2 = 316.00,
    tld = '[".mt"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"eng":"English","mlt":"Maltese"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'MT';

UPDATE country
SET
    official_name = 'Republic of the Marshall Islands',
    iso3_code = 'MHL',
    iso_numeric = '584',
    region = 'Oceania',
    subregion = 'Micronesia',
    capital = 'Majuro',
    latitude = 9.000000,
    longitude = 168.000000,
    area_km2 = 181.00,
    tld = '[".mh"]'::jsonb,
    timezones = '["UTC+12:00"]'::jsonb,
    currencies = '{"USD":{"name":"United States dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English","mah":"Marshallese"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'MH';

UPDATE country
SET
    official_name = 'Islamic Republic of Mauritania',
    iso3_code = 'MRT',
    iso_numeric = '478',
    region = 'Africa',
    subregion = 'Western Africa',
    capital = 'Nouakchott',
    latitude = 20.000000,
    longitude = -12.000000,
    area_km2 = 1030700.00,
    tld = '[".mr"]'::jsonb,
    timezones = '["UTC"]'::jsonb,
    currencies = '{"MRU":{"name":"Mauritanian ouguiya","symbol":"UM"}}'::jsonb,
    languages = '{"ara":"Arabic"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'MR';

UPDATE country
SET
    official_name = 'Republic of Mauritius',
    iso3_code = 'MUS',
    iso_numeric = '480',
    region = 'Africa',
    subregion = 'Eastern Africa',
    capital = 'Port Louis',
    latitude = -20.283333,
    longitude = 57.550000,
    area_km2 = 2040.00,
    tld = '[".mu"]'::jsonb,
    timezones = '["UTC+04:00"]'::jsonb,
    currencies = '{"MUR":{"name":"Mauritian rupee","symbol":"₨"}}'::jsonb,
    languages = '{"eng":"English","fra":"French","mfe":"Mauritian Creole"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'MU';

UPDATE country
SET
    official_name = 'United Mexican States',
    iso3_code = 'MEX',
    iso_numeric = '484',
    region = 'Americas',
    subregion = 'North America',
    capital = 'Mexico City',
    latitude = 23.000000,
    longitude = -102.000000,
    area_km2 = 1964375.00,
    tld = '[".mx"]'::jsonb,
    timezones = '["UTC-08:00","UTC-07:00","UTC-06:00"]'::jsonb,
    currencies = '{"MXN":{"name":"Mexican peso","symbol":"$"}}'::jsonb,
    languages = '{"spa":"Spanish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'MX';

UPDATE country
SET
    official_name = 'Federated States of Micronesia',
    iso3_code = 'FSM',
    iso_numeric = '583',
    region = 'Oceania',
    subregion = 'Micronesia',
    capital = 'Palikir',
    latitude = 6.916667,
    longitude = 158.250000,
    area_km2 = 702.00,
    tld = '[".fm"]'::jsonb,
    timezones = '["UTC+10:00","UTC+11:00"]'::jsonb,
    currencies = '{"USD":{"name":"United States dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'FM';

UPDATE country
SET
    official_name = 'Republic of Moldova',
    iso3_code = 'MDA',
    iso_numeric = '498',
    region = 'Europe',
    subregion = 'Eastern Europe',
    capital = 'Chișinău',
    latitude = 47.000000,
    longitude = 29.000000,
    area_km2 = 33847.00,
    tld = '[".md"]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"MDL":{"name":"Moldovan leu","symbol":"L"}}'::jsonb,
    languages = '{"ron":"Romanian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'MD';

UPDATE country
SET
    official_name = 'Principality of Monaco',
    iso3_code = 'MCO',
    iso_numeric = '492',
    region = 'Europe',
    subregion = 'Western Europe',
    capital = 'Monaco',
    latitude = 43.733333,
    longitude = 7.400000,
    area_km2 = 2.02,
    tld = '[".mc"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"fra":"French"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'MC';

UPDATE country
SET
    official_name = 'Mongolia',
    iso3_code = 'MNG',
    iso_numeric = '496',
    region = 'Asia',
    subregion = 'Eastern Asia',
    capital = 'Ulan Bator',
    latitude = 46.000000,
    longitude = 105.000000,
    area_km2 = 1564110.00,
    tld = '[".mn"]'::jsonb,
    timezones = '["UTC+07:00","UTC+08:00"]'::jsonb,
    currencies = '{"MNT":{"name":"Mongolian tögrög","symbol":"₮"}}'::jsonb,
    languages = '{"mon":"Mongolian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'MN';

UPDATE country
SET
    official_name = 'Montenegro',
    iso3_code = 'MNE',
    iso_numeric = '499',
    region = 'Europe',
    subregion = 'Southeast Europe',
    capital = 'Podgorica',
    latitude = 42.500000,
    longitude = 19.300000,
    area_km2 = 13812.00,
    tld = '[".me"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"cnr":"Montenegrin"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'ME';

UPDATE country
SET
    official_name = 'Kingdom of Morocco',
    iso3_code = 'MAR',
    iso_numeric = '504',
    region = 'Africa',
    subregion = 'Northern Africa',
    capital = 'Rabat',
    latitude = 32.000000,
    longitude = -5.000000,
    area_km2 = 446550.00,
    tld = '[".ma","المغرب."]'::jsonb,
    timezones = '["UTC"]'::jsonb,
    currencies = '{"MAD":{"name":"Moroccan dirham","symbol":"د.م."}}'::jsonb,
    languages = '{"ara":"Arabic","ber":"Berber"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'MA';

UPDATE country
SET
    official_name = 'Republic of Mozambique',
    iso3_code = 'MOZ',
    iso_numeric = '508',
    region = 'Africa',
    subregion = 'Eastern Africa',
    capital = 'Maputo',
    latitude = -18.250000,
    longitude = 35.000000,
    area_km2 = 801590.00,
    tld = '[".mz"]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"MZN":{"name":"Mozambican metical","symbol":"MT"}}'::jsonb,
    languages = '{"por":"Portuguese"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'MZ';

UPDATE country
SET
    official_name = 'Republic of the Union of Myanmar',
    iso3_code = 'MMR',
    iso_numeric = '104',
    region = 'Asia',
    subregion = 'South-Eastern Asia',
    capital = 'Naypyidaw',
    latitude = 22.000000,
    longitude = 98.000000,
    area_km2 = 676578.00,
    tld = '[".mm"]'::jsonb,
    timezones = '["UTC+06:30"]'::jsonb,
    currencies = '{"MMK":{"name":"Burmese kyat","symbol":"Ks"}}'::jsonb,
    languages = '{"mya":"Burmese"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'MM';

UPDATE country
SET
    official_name = 'Republic of Namibia',
    iso3_code = 'NAM',
    iso_numeric = '516',
    region = 'Africa',
    subregion = 'Southern Africa',
    capital = 'Windhoek',
    latitude = -22.000000,
    longitude = 17.000000,
    area_km2 = 825615.00,
    tld = '[".na"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"NAD":{"name":"Namibian dollar","symbol":"$"},"ZAR":{"name":"South African rand","symbol":"R"}}'::jsonb,
    languages = '{"afr":"Afrikaans","deu":"German","eng":"English","her":"Herero","hgm":"Khoekhoe","kwn":"Kwangali","loz":"Lozi","ndo":"Ndonga","tsn":"Tswana"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'NA';

UPDATE country
SET
    official_name = 'Republic of Nauru',
    iso3_code = 'NRU',
    iso_numeric = '520',
    region = 'Oceania',
    subregion = 'Micronesia',
    capital = 'Yaren',
    latitude = -0.533333,
    longitude = 166.916667,
    area_km2 = 21.00,
    tld = '[".nr"]'::jsonb,
    timezones = '["UTC+12:00"]'::jsonb,
    currencies = '{"AUD":{"name":"Australian dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English","nau":"Nauru"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'NR';

UPDATE country
SET
    official_name = 'Federal Democratic Republic of Nepal',
    iso3_code = 'NPL',
    iso_numeric = '524',
    region = 'Asia',
    subregion = 'Southern Asia',
    capital = 'Kathmandu',
    latitude = 28.000000,
    longitude = 84.000000,
    area_km2 = 147181.00,
    tld = '[".np"]'::jsonb,
    timezones = '["UTC+05:45"]'::jsonb,
    currencies = '{"NPR":{"name":"Nepalese rupee","symbol":"₨"}}'::jsonb,
    languages = '{"nep":"Nepali"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'sunday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'NP';

UPDATE country
SET
    official_name = 'Kingdom of the Netherlands',
    iso3_code = 'NLD',
    iso_numeric = '528',
    region = 'Europe',
    subregion = 'Western Europe',
    capital = 'Amsterdam',
    latitude = 52.500000,
    longitude = 5.750000,
    area_km2 = 41865.00,
    tld = '[".nl"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"nld":"Dutch"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'NL';

UPDATE country
SET
    official_name = 'New Zealand',
    iso3_code = 'NZL',
    iso_numeric = '554',
    region = 'Oceania',
    subregion = 'Australia and New Zealand',
    capital = 'Wellington',
    latitude = -41.000000,
    longitude = 174.000000,
    area_km2 = 268838.00,
    tld = '[".nz"]'::jsonb,
    timezones = '["UTC-11:00","UTC-10:00","UTC+12:00","UTC+12:45","UTC+13:00"]'::jsonb,
    currencies = '{"NZD":{"name":"New Zealand dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English","mri":"Māori","nzs":"New Zealand Sign Language"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'NZ';

UPDATE country
SET
    official_name = 'Republic of Nicaragua',
    iso3_code = 'NIC',
    iso_numeric = '558',
    region = 'Americas',
    subregion = 'Central America',
    capital = 'Managua',
    latitude = 13.000000,
    longitude = -85.000000,
    area_km2 = 130373.00,
    tld = '[".ni"]'::jsonb,
    timezones = '["UTC-06:00"]'::jsonb,
    currencies = '{"NIO":{"name":"Nicaraguan córdoba","symbol":"C$"}}'::jsonb,
    languages = '{"spa":"Spanish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'NI';

UPDATE country
SET
    official_name = 'Republic of Niger',
    iso3_code = 'NER',
    iso_numeric = '562',
    region = 'Africa',
    subregion = 'Western Africa',
    capital = 'Niamey',
    latitude = 16.000000,
    longitude = 8.000000,
    area_km2 = 1267000.00,
    tld = '[".ne"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"XOF":{"name":"West African CFA franc","symbol":"Fr"}}'::jsonb,
    languages = '{"fra":"French"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'NE';

UPDATE country
SET
    official_name = 'Federal Republic of Nigeria',
    iso3_code = 'NGA',
    iso_numeric = '566',
    region = 'Africa',
    subregion = 'Western Africa',
    capital = 'Abuja',
    latitude = 10.000000,
    longitude = 8.000000,
    area_km2 = 923768.00,
    tld = '[".ng"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"NGN":{"name":"Nigerian naira","symbol":"₦"}}'::jsonb,
    languages = '{"eng":"English"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'NG';

UPDATE country
SET
    official_name = 'Republic of North Macedonia',
    iso3_code = 'MKD',
    iso_numeric = '807',
    region = 'Europe',
    subregion = 'Southeast Europe',
    capital = 'Skopje',
    latitude = 41.833333,
    longitude = 22.000000,
    area_km2 = 25713.00,
    tld = '[".mk"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"MKD":{"name":"denar","symbol":"den"}}'::jsonb,
    languages = '{"mkd":"Macedonian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'MK';

UPDATE country
SET
    official_name = 'Kingdom of Norway',
    iso3_code = 'NOR',
    iso_numeric = '578',
    region = 'Europe',
    subregion = 'Northern Europe',
    capital = 'Oslo',
    latitude = 62.000000,
    longitude = 10.000000,
    area_km2 = 386224.00,
    tld = '[".no"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"NOK":{"name":"Norwegian krone","symbol":"kr"}}'::jsonb,
    languages = '{"nno":"Norwegian Nynorsk","nob":"Norwegian Bokmål","smi":"Sami"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'NO';

UPDATE country
SET
    official_name = 'Sultanate of Oman',
    iso3_code = 'OMN',
    iso_numeric = '512',
    region = 'Asia',
    subregion = 'Western Asia',
    capital = 'Muscat',
    latitude = 21.000000,
    longitude = 57.000000,
    area_km2 = 309500.00,
    tld = '[".om"]'::jsonb,
    timezones = '["UTC+04:00"]'::jsonb,
    currencies = '{"OMR":{"name":"Omani rial","symbol":"ر.ع."}}'::jsonb,
    languages = '{"ara":"Arabic"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'sunday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'OM';

UPDATE country
SET
    official_name = 'Islamic Republic of Pakistan',
    iso3_code = 'PAK',
    iso_numeric = '586',
    region = 'Asia',
    subregion = 'Southern Asia',
    capital = 'Islamabad',
    latitude = 30.000000,
    longitude = 70.000000,
    area_km2 = 796095.00,
    tld = '[".pk"]'::jsonb,
    timezones = '["UTC+05:00"]'::jsonb,
    currencies = '{"PKR":{"name":"Pakistani rupee","symbol":"₨"}}'::jsonb,
    languages = '{"eng":"English","urd":"Urdu"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'PK';

UPDATE country
SET
    official_name = 'Republic of Palau',
    iso3_code = 'PLW',
    iso_numeric = '585',
    region = 'Oceania',
    subregion = 'Micronesia',
    capital = 'Ngerulmud',
    latitude = 7.500000,
    longitude = 134.500000,
    area_km2 = 459.00,
    tld = '[".pw"]'::jsonb,
    timezones = '["UTC+09:00"]'::jsonb,
    currencies = '{"USD":{"name":"United States dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English","pau":"Palauan"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'PW';

UPDATE country
SET
    official_name = 'State of Palestine',
    iso3_code = 'PSE',
    iso_numeric = '275',
    region = 'Asia',
    subregion = 'Western Asia',
    capital = 'Ramallah',
    latitude = 31.900000,
    longitude = 35.200000,
    area_km2 = 6220.00,
    tld = '[".ps","فلسطين."]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"EGP":{"name":"Egyptian pound","symbol":"E£"},"ILS":{"name":"Israeli new shekel","symbol":"₪"},"JOD":{"name":"Jordanian dinar","symbol":"JD"}}'::jsonb,
    languages = '{"ara":"Arabic"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'sunday',
    un_member = FALSE,
    independent = FALSE
WHERE iso_code = 'PS';

UPDATE country
SET
    official_name = 'Republic of Panama',
    iso3_code = 'PAN',
    iso_numeric = '591',
    region = 'Americas',
    subregion = 'Central America',
    capital = 'Panama City',
    latitude = 9.000000,
    longitude = -80.000000,
    area_km2 = 75417.00,
    tld = '[".pa"]'::jsonb,
    timezones = '["UTC-05:00"]'::jsonb,
    currencies = '{"PAB":{"name":"Panamanian balboa","symbol":"B/."},"USD":{"name":"United States dollar","symbol":"$"}}'::jsonb,
    languages = '{"spa":"Spanish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'PA';

UPDATE country
SET
    official_name = 'Independent State of Papua New Guinea',
    iso3_code = 'PNG',
    iso_numeric = '598',
    region = 'Oceania',
    subregion = 'Melanesia',
    capital = 'Port Moresby',
    latitude = -6.000000,
    longitude = 147.000000,
    area_km2 = 462840.00,
    tld = '[".pg"]'::jsonb,
    timezones = '["UTC+10:00"]'::jsonb,
    currencies = '{"PGK":{"name":"Papua New Guinean kina","symbol":"K"}}'::jsonb,
    languages = '{"eng":"English","hmo":"Hiri Motu","tpi":"Tok Pisin"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'PG';

UPDATE country
SET
    official_name = 'Republic of Paraguay',
    iso3_code = 'PRY',
    iso_numeric = '600',
    region = 'Americas',
    subregion = 'South America',
    capital = 'Asunción',
    latitude = -23.000000,
    longitude = -58.000000,
    area_km2 = 406752.00,
    tld = '[".py"]'::jsonb,
    timezones = '["UTC-04:00"]'::jsonb,
    currencies = '{"PYG":{"name":"Paraguayan guaraní","symbol":"₲"}}'::jsonb,
    languages = '{"grn":"Guaraní","spa":"Spanish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'PY';

UPDATE country
SET
    official_name = 'Republic of Peru',
    iso3_code = 'PER',
    iso_numeric = '604',
    region = 'Americas',
    subregion = 'South America',
    capital = 'Lima',
    latitude = -10.000000,
    longitude = -76.000000,
    area_km2 = 1285216.00,
    tld = '[".pe"]'::jsonb,
    timezones = '["UTC-05:00"]'::jsonb,
    currencies = '{"PEN":{"name":"Peruvian sol","symbol":"S/ "}}'::jsonb,
    languages = '{"aym":"Aymara","que":"Quechua","spa":"Spanish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'PE';

UPDATE country
SET
    official_name = 'Republic of the Philippines',
    iso3_code = 'PHL',
    iso_numeric = '608',
    region = 'Asia',
    subregion = 'South-Eastern Asia',
    capital = 'Manila',
    latitude = 13.000000,
    longitude = 122.000000,
    area_km2 = 342353.00,
    tld = '[".ph"]'::jsonb,
    timezones = '["UTC+08:00"]'::jsonb,
    currencies = '{"PHP":{"name":"Philippine peso","symbol":"₱"}}'::jsonb,
    languages = '{"eng":"English","fil":"Filipino"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'PH';

UPDATE country
SET
    official_name = 'Republic of Poland',
    iso3_code = 'POL',
    iso_numeric = '616',
    region = 'Europe',
    subregion = 'Central Europe',
    capital = 'Warsaw',
    latitude = 52.000000,
    longitude = 20.000000,
    area_km2 = 312679.00,
    tld = '[".pl"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"PLN":{"name":"Polish złoty","symbol":"zł"}}'::jsonb,
    languages = '{"pol":"Polish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'PL';

UPDATE country
SET
    official_name = 'Portuguese Republic',
    iso3_code = 'PRT',
    iso_numeric = '620',
    region = 'Europe',
    subregion = 'Southern Europe',
    capital = 'Lisbon',
    latitude = 39.500000,
    longitude = -8.000000,
    area_km2 = 92090.00,
    tld = '[".pt"]'::jsonb,
    timezones = '["UTC-01:00","UTC"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"por":"Portuguese"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'PT';

UPDATE country
SET
    official_name = 'State of Qatar',
    iso3_code = 'QAT',
    iso_numeric = '634',
    region = 'Asia',
    subregion = 'Western Asia',
    capital = 'Doha',
    latitude = 25.500000,
    longitude = 51.250000,
    area_km2 = 11586.00,
    tld = '[".qa","قطر."]'::jsonb,
    timezones = '["UTC+03:00"]'::jsonb,
    currencies = '{"QAR":{"name":"Qatari riyal","symbol":"ر.ق"}}'::jsonb,
    languages = '{"ara":"Arabic"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'sunday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'QA';

UPDATE country
SET
    official_name = 'Romania',
    iso3_code = 'ROU',
    iso_numeric = '642',
    region = 'Europe',
    subregion = 'Southeast Europe',
    capital = 'Bucharest',
    latitude = 46.000000,
    longitude = 25.000000,
    area_km2 = 238391.00,
    tld = '[".ro"]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"RON":{"name":"Romanian leu","symbol":"lei"}}'::jsonb,
    languages = '{"ron":"Romanian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'RO';

UPDATE country
SET
    official_name = 'Russian Federation',
    iso3_code = 'RUS',
    iso_numeric = '643',
    region = 'Europe',
    subregion = 'Eastern Europe',
    capital = 'Moscow',
    latitude = 60.000000,
    longitude = 100.000000,
    area_km2 = 17098246.00,
    tld = '[".ru",".su",".рф"]'::jsonb,
    timezones = '["UTC+03:00","UTC+04:00","UTC+06:00","UTC+07:00","UTC+08:00","UTC+09:00","UTC+10:00","UTC+11:00","UTC+12:00"]'::jsonb,
    currencies = '{"RUB":{"name":"Russian ruble","symbol":"₽"}}'::jsonb,
    languages = '{"rus":"Russian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'RU';

UPDATE country
SET
    official_name = 'Republic of Rwanda',
    iso3_code = 'RWA',
    iso_numeric = '646',
    region = 'Africa',
    subregion = 'Eastern Africa',
    capital = 'Kigali',
    latitude = -2.000000,
    longitude = 30.000000,
    area_km2 = 26338.00,
    tld = '[".rw"]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"RWF":{"name":"Rwandan franc","symbol":"Fr"}}'::jsonb,
    languages = '{"eng":"English","fra":"French","kin":"Kinyarwanda"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'RW';

UPDATE country
SET
    official_name = 'Federation of Saint Christopher and Nevis',
    iso3_code = 'KNA',
    iso_numeric = '659',
    region = 'Americas',
    subregion = 'Caribbean',
    capital = 'Basseterre',
    latitude = 17.333333,
    longitude = -62.750000,
    area_km2 = 261.00,
    tld = '[".kn"]'::jsonb,
    timezones = '["UTC-04:00"]'::jsonb,
    currencies = '{"XCD":{"name":"Eastern Caribbean dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'KN';

UPDATE country
SET
    official_name = 'Saint Lucia',
    iso3_code = 'LCA',
    iso_numeric = '662',
    region = 'Americas',
    subregion = 'Caribbean',
    capital = 'Castries',
    latitude = 13.883333,
    longitude = -60.966667,
    area_km2 = 616.00,
    tld = '[".lc"]'::jsonb,
    timezones = '["UTC-04:00"]'::jsonb,
    currencies = '{"XCD":{"name":"Eastern Caribbean dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'LC';

UPDATE country
SET
    official_name = 'Saint Vincent and the Grenadines',
    iso3_code = 'VCT',
    iso_numeric = '670',
    region = 'Americas',
    subregion = 'Caribbean',
    capital = 'Kingstown',
    latitude = 13.250000,
    longitude = -61.200000,
    area_km2 = 389.00,
    tld = '[".vc"]'::jsonb,
    timezones = '["UTC-04:00"]'::jsonb,
    currencies = '{"XCD":{"name":"Eastern Caribbean dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'VC';

UPDATE country
SET
    official_name = 'Independent State of Samoa',
    iso3_code = 'WSM',
    iso_numeric = '882',
    region = 'Oceania',
    subregion = 'Polynesia',
    capital = 'Apia',
    latitude = -13.583333,
    longitude = -172.333333,
    area_km2 = 2842.00,
    tld = '[".ws"]'::jsonb,
    timezones = '["UTC+13:00"]'::jsonb,
    currencies = '{"WST":{"name":"Samoan tālā","symbol":"T"}}'::jsonb,
    languages = '{"eng":"English","smo":"Samoan"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'WS';

UPDATE country
SET
    official_name = 'Republic of San Marino',
    iso3_code = 'SMR',
    iso_numeric = '674',
    region = 'Europe',
    subregion = 'Southern Europe',
    capital = 'City of San Marino',
    latitude = 43.766667,
    longitude = 12.416667,
    area_km2 = 61.00,
    tld = '[".sm"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"ita":"Italian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'SM';

UPDATE country
SET
    official_name = 'Democratic Republic of São Tomé and Príncipe',
    iso3_code = 'STP',
    iso_numeric = '678',
    region = 'Africa',
    subregion = 'Middle Africa',
    capital = 'São Tomé',
    latitude = 1.000000,
    longitude = 7.000000,
    area_km2 = 964.00,
    tld = '[".st"]'::jsonb,
    timezones = '["UTC"]'::jsonb,
    currencies = '{"STN":{"name":"São Tomé and Príncipe dobra","symbol":"Db"}}'::jsonb,
    languages = '{"por":"Portuguese"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'ST';

UPDATE country
SET
    official_name = 'Kingdom of Saudi Arabia',
    iso3_code = 'SAU',
    iso_numeric = '682',
    region = 'Asia',
    subregion = 'Western Asia',
    capital = 'Riyadh',
    latitude = 25.000000,
    longitude = 45.000000,
    area_km2 = 2149690.00,
    tld = '[".sa",".السعودية"]'::jsonb,
    timezones = '["UTC+03:00"]'::jsonb,
    currencies = '{"SAR":{"name":"Saudi riyal","symbol":"ر.س"}}'::jsonb,
    languages = '{"ara":"Arabic"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'sunday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'SA';

UPDATE country
SET
    official_name = 'Republic of Senegal',
    iso3_code = 'SEN',
    iso_numeric = '686',
    region = 'Africa',
    subregion = 'Western Africa',
    capital = 'Dakar',
    latitude = 14.000000,
    longitude = -14.000000,
    area_km2 = 196722.00,
    tld = '[".sn"]'::jsonb,
    timezones = '["UTC"]'::jsonb,
    currencies = '{"XOF":{"name":"West African CFA franc","symbol":"Fr"}}'::jsonb,
    languages = '{"fra":"French"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'SN';

UPDATE country
SET
    official_name = 'Republic of Serbia',
    iso3_code = 'SRB',
    iso_numeric = '688',
    region = 'Europe',
    subregion = 'Southeast Europe',
    capital = 'Belgrade',
    latitude = 44.000000,
    longitude = 21.000000,
    area_km2 = 77589.00,
    tld = '[".rs",".срб"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"RSD":{"name":"Serbian dinar","symbol":"дин."}}'::jsonb,
    languages = '{"srp":"Serbian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'RS';

UPDATE country
SET
    official_name = 'Republic of Seychelles',
    iso3_code = 'SYC',
    iso_numeric = '690',
    region = 'Africa',
    subregion = 'Eastern Africa',
    capital = 'Victoria',
    latitude = -4.583333,
    longitude = 55.666667,
    area_km2 = 452.00,
    tld = '[".sc"]'::jsonb,
    timezones = '["UTC+04:00"]'::jsonb,
    currencies = '{"SCR":{"name":"Seychellois rupee","symbol":"₨"}}'::jsonb,
    languages = '{"crs":"Seychellois Creole","eng":"English","fra":"French"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'SC';

UPDATE country
SET
    official_name = 'Republic of Sierra Leone',
    iso3_code = 'SLE',
    iso_numeric = '694',
    region = 'Africa',
    subregion = 'Western Africa',
    capital = 'Freetown',
    latitude = 8.500000,
    longitude = -11.500000,
    area_km2 = 71740.00,
    tld = '[".sl"]'::jsonb,
    timezones = '["UTC"]'::jsonb,
    currencies = '{"SLE":{"name":"Leone","symbol":"Le"}}'::jsonb,
    languages = '{"eng":"English"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'SL';

UPDATE country
SET
    official_name = 'Republic of Singapore',
    iso3_code = 'SGP',
    iso_numeric = '702',
    region = 'Asia',
    subregion = 'South-Eastern Asia',
    capital = 'Singapore',
    latitude = 1.366667,
    longitude = 103.800000,
    area_km2 = 710.00,
    tld = '[".sg",".新加坡",".சிங்கப்பூர்"]'::jsonb,
    timezones = '["UTC+08:00"]'::jsonb,
    currencies = '{"SGD":{"name":"Singapore dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English","zho":"Chinese","msa":"Malay","tam":"Tamil"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'SG';

UPDATE country
SET
    official_name = 'Slovak Republic',
    iso3_code = 'SVK',
    iso_numeric = '703',
    region = 'Europe',
    subregion = 'Central Europe',
    capital = 'Bratislava',
    latitude = 48.666667,
    longitude = 19.500000,
    area_km2 = 49037.00,
    tld = '[".sk"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"slk":"Slovak"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'SK';

UPDATE country
SET
    official_name = 'Republic of Slovenia',
    iso3_code = 'SVN',
    iso_numeric = '705',
    region = 'Europe',
    subregion = 'Central Europe',
    capital = 'Ljubljana',
    latitude = 46.116667,
    longitude = 14.816667,
    area_km2 = 20273.00,
    tld = '[".si"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"slv":"Slovene"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'SI';

UPDATE country
SET
    official_name = 'Solomon Islands',
    iso3_code = 'SLB',
    iso_numeric = '090',
    region = 'Oceania',
    subregion = 'Melanesia',
    capital = 'Honiara',
    latitude = -8.000000,
    longitude = 159.000000,
    area_km2 = 28896.00,
    tld = '[".sb"]'::jsonb,
    timezones = '["UTC+11:00"]'::jsonb,
    currencies = '{"SBD":{"name":"Solomon Islands dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'SB';

UPDATE country
SET
    official_name = 'Federal Republic of Somalia',
    iso3_code = 'SOM',
    iso_numeric = '706',
    region = 'Africa',
    subregion = 'Eastern Africa',
    capital = 'Mogadishu',
    latitude = 10.000000,
    longitude = 49.000000,
    area_km2 = 637657.00,
    tld = '[".so"]'::jsonb,
    timezones = '["UTC+03:00"]'::jsonb,
    currencies = '{"SOS":{"name":"Somali shilling","symbol":"Sh"}}'::jsonb,
    languages = '{"ara":"Arabic","som":"Somali"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'SO';

UPDATE country
SET
    official_name = 'Republic of South Africa',
    iso3_code = 'ZAF',
    iso_numeric = '710',
    region = 'Africa',
    subregion = 'Southern Africa',
    capital = 'Pretoria',
    latitude = -29.000000,
    longitude = 24.000000,
    area_km2 = 1221037.00,
    tld = '[".za"]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"ZAR":{"name":"South African rand","symbol":"R"}}'::jsonb,
    languages = '{"afr":"Afrikaans","eng":"English","nbl":"Southern Ndebele","nso":"Northern Sotho","sot":"Southern Sotho","ssw":"Swazi","tsn":"Tswana","tso":"Tsonga","ven":"Venda","xho":"Xhosa","zul":"Zulu"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'ZA';

UPDATE country
SET
    official_name = 'Republic of South Sudan',
    iso3_code = 'SSD',
    iso_numeric = '728',
    region = 'Africa',
    subregion = 'Middle Africa',
    capital = 'Juba',
    latitude = 7.000000,
    longitude = 30.000000,
    area_km2 = 619745.00,
    tld = '[".ss"]'::jsonb,
    timezones = '["UTC+03:00"]'::jsonb,
    currencies = '{"SSP":{"name":"South Sudanese pound","symbol":"£"}}'::jsonb,
    languages = '{"eng":"English"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'sunday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'SS';

UPDATE country
SET
    official_name = 'Kingdom of Spain',
    iso3_code = 'ESP',
    iso_numeric = '724',
    region = 'Europe',
    subregion = 'Southern Europe',
    capital = 'Madrid',
    latitude = 40.000000,
    longitude = -4.000000,
    area_km2 = 505992.00,
    tld = '[".es"]'::jsonb,
    timezones = '["UTC","UTC+01:00"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"spa":"Spanish","cat":"Catalan","eus":"Basque","glc":"Galician"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'ES';

UPDATE country
SET
    official_name = 'Democratic Socialist Republic of Sri Lanka',
    iso3_code = 'LKA',
    iso_numeric = '144',
    region = 'Asia',
    subregion = 'Southern Asia',
    capital = 'Sri Jayawardenepura Kotte',
    latitude = 7.000000,
    longitude = 81.000000,
    area_km2 = 65610.00,
    tld = '[".lk",".இலங்கை",".ලංකා"]'::jsonb,
    timezones = '["UTC+05:30"]'::jsonb,
    currencies = '{"LKR":{"name":"Sri Lankan rupee","symbol":"Rs  රු"}}'::jsonb,
    languages = '{"sin":"Sinhala","tam":"Tamil"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'LK';

UPDATE country
SET
    official_name = 'Republic of the Sudan',
    iso3_code = 'SDN',
    iso_numeric = '729',
    region = 'Africa',
    subregion = 'Northern Africa',
    capital = 'Khartoum',
    latitude = 15.000000,
    longitude = 30.000000,
    area_km2 = 1886068.00,
    tld = '[".sd"]'::jsonb,
    timezones = '["UTC+03:00"]'::jsonb,
    currencies = '{"SDG":{"name":"Sudanese pound","symbol":"ج.س"}}'::jsonb,
    languages = '{"ara":"Arabic","eng":"English"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'SD';

UPDATE country
SET
    official_name = 'Republic of Suriname',
    iso3_code = 'SUR',
    iso_numeric = '740',
    region = 'Americas',
    subregion = 'South America',
    capital = 'Paramaribo',
    latitude = 4.000000,
    longitude = -56.000000,
    area_km2 = 163820.00,
    tld = '[".sr"]'::jsonb,
    timezones = '["UTC-03:00"]'::jsonb,
    currencies = '{"SRD":{"name":"Surinamese dollar","symbol":"$"}}'::jsonb,
    languages = '{"nld":"Dutch"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'SR';

UPDATE country
SET
    official_name = 'Kingdom of Sweden',
    iso3_code = 'SWE',
    iso_numeric = '752',
    region = 'Europe',
    subregion = 'Northern Europe',
    capital = 'Stockholm',
    latitude = 62.000000,
    longitude = 15.000000,
    area_km2 = 450295.00,
    tld = '[".se"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"SEK":{"name":"Swedish krona","symbol":"kr"}}'::jsonb,
    languages = '{"swe":"Swedish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'SE';

UPDATE country
SET
    official_name = 'Swiss Confederation',
    iso3_code = 'CHE',
    iso_numeric = '756',
    region = 'Europe',
    subregion = 'Western Europe',
    capital = 'Bern',
    latitude = 47.000000,
    longitude = 8.000000,
    area_km2 = 41284.00,
    tld = '[".ch"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"CHF":{"name":"Swiss franc","symbol":"Fr."}}'::jsonb,
    languages = '{"fra":"French","gsw":"Swiss German","ita":"Italian","roh":"Romansh"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'CH';

UPDATE country
SET
    official_name = 'Syrian Arab Republic',
    iso3_code = 'SYR',
    iso_numeric = '760',
    region = 'Asia',
    subregion = 'Western Asia',
    capital = 'Damascus',
    latitude = 35.000000,
    longitude = 38.000000,
    area_km2 = 185180.00,
    tld = '[".sy","سوريا."]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"SYP":{"name":"Syrian pound","symbol":"£"}}'::jsonb,
    languages = '{"ara":"Arabic"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'SY';

UPDATE country
SET
    official_name = 'Republic of China (Taiwan)',
    iso3_code = 'TWN',
    iso_numeric = '158',
    region = 'Asia',
    subregion = 'Eastern Asia',
    capital = 'Taipei',
    latitude = 23.500000,
    longitude = 121.000000,
    area_km2 = 36197.00,
    tld = '[".tw",".台灣",".台湾"]'::jsonb,
    timezones = '["UTC+08:00"]'::jsonb,
    currencies = '{"TWD":{"name":"New Taiwan dollar","symbol":"$"}}'::jsonb,
    languages = '{"zho":"Chinese"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = FALSE,
    independent = FALSE
WHERE iso_code = 'TW';

UPDATE country
SET
    official_name = 'Republic of Tajikistan',
    iso3_code = 'TJK',
    iso_numeric = '762',
    region = 'Asia',
    subregion = 'Central Asia',
    capital = 'Dushanbe',
    latitude = 39.000000,
    longitude = 71.000000,
    area_km2 = 143100.00,
    tld = '[".tj"]'::jsonb,
    timezones = '["UTC+05:00"]'::jsonb,
    currencies = '{"TJS":{"name":"Tajikistani somoni","symbol":"ЅМ"}}'::jsonb,
    languages = '{"rus":"Russian","tgk":"Tajik"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'TJ';

UPDATE country
SET
    official_name = 'United Republic of Tanzania',
    iso3_code = 'TZA',
    iso_numeric = '834',
    region = 'Africa',
    subregion = 'Eastern Africa',
    capital = 'Dodoma',
    latitude = -6.000000,
    longitude = 35.000000,
    area_km2 = 947303.00,
    tld = '[".tz"]'::jsonb,
    timezones = '["UTC+03:00"]'::jsonb,
    currencies = '{"TZS":{"name":"Tanzanian shilling","symbol":"Sh"}}'::jsonb,
    languages = '{"eng":"English","swa":"Swahili"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'TZ';

UPDATE country
SET
    official_name = 'Kingdom of Thailand',
    iso3_code = 'THA',
    iso_numeric = '764',
    region = 'Asia',
    subregion = 'South-Eastern Asia',
    capital = 'Bangkok',
    latitude = 15.000000,
    longitude = 100.000000,
    area_km2 = 513120.00,
    tld = '[".th",".ไทย"]'::jsonb,
    timezones = '["UTC+07:00"]'::jsonb,
    currencies = '{"THB":{"name":"Thai baht","symbol":"฿"}}'::jsonb,
    languages = '{"tha":"Thai"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'TH';

UPDATE country
SET
    official_name = 'Democratic Republic of Timor-Leste',
    iso3_code = 'TLS',
    iso_numeric = '626',
    region = 'Asia',
    subregion = 'South-Eastern Asia',
    capital = 'Dili',
    latitude = -8.833333,
    longitude = 125.916667,
    area_km2 = 14874.00,
    tld = '[".tl"]'::jsonb,
    timezones = '["UTC+09:00"]'::jsonb,
    currencies = '{"USD":{"name":"United States dollar","symbol":"$"}}'::jsonb,
    languages = '{"por":"Portuguese","tet":"Tetum"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'TL';

UPDATE country
SET
    official_name = 'Togolese Republic',
    iso3_code = 'TGO',
    iso_numeric = '768',
    region = 'Africa',
    subregion = 'Western Africa',
    capital = 'Lomé',
    latitude = 8.000000,
    longitude = 1.166667,
    area_km2 = 56785.00,
    tld = '[".tg"]'::jsonb,
    timezones = '["UTC"]'::jsonb,
    currencies = '{"XOF":{"name":"West African CFA franc","symbol":"Fr"}}'::jsonb,
    languages = '{"fra":"French"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'TG';

UPDATE country
SET
    official_name = 'Kingdom of Tonga',
    iso3_code = 'TON',
    iso_numeric = '776',
    region = 'Oceania',
    subregion = 'Polynesia',
    capital = 'Nuku''alofa',
    latitude = -20.000000,
    longitude = -175.000000,
    area_km2 = 747.00,
    tld = '[".to"]'::jsonb,
    timezones = '["UTC+13:00"]'::jsonb,
    currencies = '{"TOP":{"name":"Tongan paʻanga","symbol":"T$"}}'::jsonb,
    languages = '{"eng":"English","ton":"Tongan"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'TO';

UPDATE country
SET
    official_name = 'Republic of Trinidad and Tobago',
    iso3_code = 'TTO',
    iso_numeric = '780',
    region = 'Americas',
    subregion = 'Caribbean',
    capital = 'Port of Spain',
    latitude = 10.691800,
    longitude = -61.222500,
    area_km2 = 5130.00,
    tld = '[".tt"]'::jsonb,
    timezones = '["UTC-04:00"]'::jsonb,
    currencies = '{"TTD":{"name":"Trinidad and Tobago dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'TT';

UPDATE country
SET
    official_name = 'Tunisian Republic',
    iso3_code = 'TUN',
    iso_numeric = '788',
    region = 'Africa',
    subregion = 'Northern Africa',
    capital = 'Tunis',
    latitude = 34.000000,
    longitude = 9.000000,
    area_km2 = 163610.00,
    tld = '[".tn"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"TND":{"name":"Tunisian dinar","symbol":"د.ت"}}'::jsonb,
    languages = '{"ara":"Arabic"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'TN';

UPDATE country
SET
    official_name = 'Republic of Turkey',
    iso3_code = 'TUR',
    iso_numeric = '792',
    region = 'Asia',
    subregion = 'Western Asia',
    capital = 'Ankara',
    latitude = 39.000000,
    longitude = 35.000000,
    area_km2 = 783562.00,
    tld = '[".tr"]'::jsonb,
    timezones = '["UTC+03:00"]'::jsonb,
    currencies = '{"TRY":{"name":"Turkish lira","symbol":"₺"}}'::jsonb,
    languages = '{"tur":"Turkish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'TR';

UPDATE country
SET
    official_name = 'Turkmenistan',
    iso3_code = 'TKM',
    iso_numeric = '795',
    region = 'Asia',
    subregion = 'Central Asia',
    capital = 'Ashgabat',
    latitude = 40.000000,
    longitude = 60.000000,
    area_km2 = 488100.00,
    tld = '[".tm"]'::jsonb,
    timezones = '["UTC+05:00"]'::jsonb,
    currencies = '{"TMT":{"name":"Turkmenistan manat","symbol":"m"}}'::jsonb,
    languages = '{"rus":"Russian","tuk":"Turkmen"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'TM';

UPDATE country
SET
    official_name = 'Tuvalu',
    iso3_code = 'TUV',
    iso_numeric = '798',
    region = 'Oceania',
    subregion = 'Polynesia',
    capital = 'Funafuti',
    latitude = -8.000000,
    longitude = 178.000000,
    area_km2 = 26.00,
    tld = '[".tv"]'::jsonb,
    timezones = '["UTC+12:00"]'::jsonb,
    currencies = '{"AUD":{"name":"Australian dollar","symbol":"$"},"TVD":{"name":"Tuvaluan dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English","tvl":"Tuvaluan"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'TV';

UPDATE country
SET
    official_name = 'Republic of Uganda',
    iso3_code = 'UGA',
    iso_numeric = '800',
    region = 'Africa',
    subregion = 'Eastern Africa',
    capital = 'Kampala',
    latitude = 1.000000,
    longitude = 32.000000,
    area_km2 = 241550.00,
    tld = '[".ug"]'::jsonb,
    timezones = '["UTC+03:00"]'::jsonb,
    currencies = '{"UGX":{"name":"Ugandan shilling","symbol":"Sh"}}'::jsonb,
    languages = '{"eng":"English","swa":"Swahili"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'UG';

UPDATE country
SET
    official_name = 'Ukraine',
    iso3_code = 'UKR',
    iso_numeric = '804',
    region = 'Europe',
    subregion = 'Eastern Europe',
    capital = 'Kyiv',
    latitude = 49.000000,
    longitude = 32.000000,
    area_km2 = 603550.00,
    tld = '[".ua",".укр"]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"UAH":{"name":"Ukrainian hryvnia","symbol":"₴"}}'::jsonb,
    languages = '{"ukr":"Ukrainian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'UA';

UPDATE country
SET
    official_name = 'United Arab Emirates',
    iso3_code = 'ARE',
    iso_numeric = '784',
    region = 'Asia',
    subregion = 'Western Asia',
    capital = 'Abu Dhabi',
    latitude = 24.000000,
    longitude = 54.000000,
    area_km2 = 83600.00,
    tld = '[".ae","امارات."]'::jsonb,
    timezones = '["UTC+04:00"]'::jsonb,
    currencies = '{"AED":{"name":"United Arab Emirates dirham","symbol":"د.إ"}}'::jsonb,
    languages = '{"ara":"Arabic"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'sunday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'AE';

UPDATE country
SET
    official_name = 'United Kingdom of Great Britain and Northern Ireland',
    iso3_code = 'GBR',
    iso_numeric = '826',
    region = 'Europe',
    subregion = 'Northern Europe',
    capital = 'London',
    latitude = 54.000000,
    longitude = -2.000000,
    area_km2 = 244376.00,
    tld = '[".uk"]'::jsonb,
    timezones = '["UTC-08:00","UTC-05:00","UTC-04:00","UTC-03:00","UTC-02:00","UTC","UTC+01:00","UTC+02:00","UTC+06:00"]'::jsonb,
    currencies = '{"GBP":{"name":"British pound","symbol":"£"}}'::jsonb,
    languages = '{"eng":"English"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'GB';

UPDATE country
SET
    official_name = 'United States of America',
    iso3_code = 'USA',
    iso_numeric = '840',
    region = 'Americas',
    subregion = 'North America',
    capital = 'Washington, D.C.',
    latitude = 38.000000,
    longitude = -97.000000,
    area_km2 = 9525067.00,
    tld = '[".us"]'::jsonb,
    timezones = '["UTC-12:00","UTC-11:00","UTC-10:00","UTC-09:00","UTC-08:00","UTC-07:00","UTC-06:00","UTC-05:00","UTC-04:00","UTC+10:00","UTC+12:00"]'::jsonb,
    currencies = '{"USD":{"name":"United States dollar","symbol":"$"}}'::jsonb,
    languages = '{"eng":"English"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'sunday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'US';

UPDATE country
SET
    official_name = 'Oriental Republic of Uruguay',
    iso3_code = 'URY',
    iso_numeric = '858',
    region = 'Americas',
    subregion = 'South America',
    capital = 'Montevideo',
    latitude = -33.000000,
    longitude = -56.000000,
    area_km2 = 181034.00,
    tld = '[".uy"]'::jsonb,
    timezones = '["UTC-03:00"]'::jsonb,
    currencies = '{"UYU":{"name":"Uruguayan peso","symbol":"$"}}'::jsonb,
    languages = '{"spa":"Spanish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'UY';

UPDATE country
SET
    official_name = 'Republic of Uzbekistan',
    iso3_code = 'UZB',
    iso_numeric = '860',
    region = 'Asia',
    subregion = 'Central Asia',
    capital = 'Tashkent',
    latitude = 41.000000,
    longitude = 64.000000,
    area_km2 = 447400.00,
    tld = '[".uz"]'::jsonb,
    timezones = '["UTC+05:00"]'::jsonb,
    currencies = '{"UZS":{"name":"Uzbekistani soʻm","symbol":"so''m"}}'::jsonb,
    languages = '{"rus":"Russian","uzb":"Uzbek"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'UZ';

UPDATE country
SET
    official_name = 'Republic of Vanuatu',
    iso3_code = 'VUT',
    iso_numeric = '548',
    region = 'Oceania',
    subregion = 'Melanesia',
    capital = 'Port Vila',
    latitude = -16.000000,
    longitude = 167.000000,
    area_km2 = 12189.00,
    tld = '[".vu"]'::jsonb,
    timezones = '["UTC+11:00"]'::jsonb,
    currencies = '{"VUV":{"name":"Vanuatu vatu","symbol":"Vt"}}'::jsonb,
    languages = '{"bis":"Bislama","eng":"English","fra":"French"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'VU';

UPDATE country
SET
    official_name = 'Vatican City State',
    iso3_code = 'VAT',
    iso_numeric = '336',
    region = 'Europe',
    subregion = 'Southern Europe',
    capital = 'Vatican City',
    latitude = 41.900000,
    longitude = 12.450000,
    area_km2 = 0.49,
    tld = '[".va"]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"ita":"Italian","lat":"Latin"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = FALSE,
    independent = TRUE
WHERE iso_code = 'VA';

UPDATE country
SET
    official_name = 'Bolivarian Republic of Venezuela',
    iso3_code = 'VEN',
    iso_numeric = '862',
    region = 'Americas',
    subregion = 'South America',
    capital = 'Caracas',
    latitude = 8.000000,
    longitude = -66.000000,
    area_km2 = 916445.00,
    tld = '[".ve"]'::jsonb,
    timezones = '["UTC-04:00"]'::jsonb,
    currencies = '{"VES":{"name":"Venezuelan bolívar soberano","symbol":"Bs.S."}}'::jsonb,
    languages = '{"spa":"Spanish"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'VE';

UPDATE country
SET
    official_name = 'Socialist Republic of Vietnam',
    iso3_code = 'VNM',
    iso_numeric = '704',
    region = 'Asia',
    subregion = 'South-Eastern Asia',
    capital = 'Hanoi',
    latitude = 16.166667,
    longitude = 107.833333,
    area_km2 = 331212.00,
    tld = '[".vn"]'::jsonb,
    timezones = '["UTC+07:00"]'::jsonb,
    currencies = '{"VND":{"name":"Vietnamese đồng","symbol":"₫"}}'::jsonb,
    languages = '{"vie":"Vietnamese"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'VN';

UPDATE country
SET
    official_name = 'Republic of Yemen',
    iso3_code = 'YEM',
    iso_numeric = '887',
    region = 'Asia',
    subregion = 'Western Asia',
    capital = 'Sana''a',
    latitude = 15.000000,
    longitude = 48.000000,
    area_km2 = 527968.00,
    tld = '[".ye"]'::jsonb,
    timezones = '["UTC+03:00"]'::jsonb,
    currencies = '{"YER":{"name":"Yemeni rial","symbol":"﷼"}}'::jsonb,
    languages = '{"ara":"Arabic"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'sunday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'YE';

UPDATE country
SET
    official_name = 'Republic of Zambia',
    iso3_code = 'ZMB',
    iso_numeric = '894',
    region = 'Africa',
    subregion = 'Eastern Africa',
    capital = 'Lusaka',
    latitude = -15.000000,
    longitude = 30.000000,
    area_km2 = 752612.00,
    tld = '[".zm"]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"ZMW":{"name":"Zambian kwacha","symbol":"ZK"}}'::jsonb,
    languages = '{"eng":"English"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'ZM';

UPDATE country
SET
    official_name = 'Republic of Zimbabwe',
    iso3_code = 'ZWE',
    iso_numeric = '716',
    region = 'Africa',
    subregion = 'Southern Africa',
    capital = 'Harare',
    latitude = -20.000000,
    longitude = 30.000000,
    area_km2 = 390757.00,
    tld = '[".zw"]'::jsonb,
    timezones = '["UTC+02:00"]'::jsonb,
    currencies = '{"ZWL":{"name":"Zimbabwean dollar","symbol":"$"}}'::jsonb,
    languages = '{"bwg":"Chibarwe","eng":"English","kck":"Kalanga","khi":"Khoisan","ndc":"Ndau","nde":"Northern Ndebele","nya":"Chewa","sna":"Shona","sot":"Sotho","toi":"Tonga","tsn":"Tswana","tso":"Tsonga","ven":"Venda","xho":"Xhosa","zib":"Zimbabwean Sign Language"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = TRUE,
    independent = TRUE
WHERE iso_code = 'ZW';

UPDATE country
SET
    official_name = 'Republic of Kosovo',
    iso3_code = 'UNK',
    iso_numeric = '',
    region = 'Europe',
    subregion = 'Southeast Europe',
    capital = 'Pristina',
    latitude = 42.666667,
    longitude = 21.166667,
    area_km2 = 10908.00,
    tld = '[]'::jsonb,
    timezones = '["UTC+01:00"]'::jsonb,
    currencies = '{"EUR":{"name":"euro","symbol":"€"}}'::jsonb,
    languages = '{"sqi":"Albanian","srp":"Serbian"}'::jsonb,
    flag_emoji = chr(127397 + ascii(substr(iso_code, 1, 1))) || chr(127397 + ascii(substr(iso_code, 2, 1))),
    start_of_week = 'monday',
    un_member = FALSE,
    independent = TRUE
WHERE iso_code = 'XK';

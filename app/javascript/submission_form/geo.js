const countries = [
  {
    name: 'United States',
    dial: '1',
    flag: '🇺🇸',
    tz: [
      'America/New_York',
      'America/Chicago',
      'America/Denver',
      'America/Los_Angeles',
      'America/Anchorage',
      'America/Adak',
      'Pacific/Honolulu'
    ]
  },
  {
    name: 'Afghanistan',
    dial: '93',
    flag: '🇦🇫',
    tz: ['Asia/Kabul']
  },
  {
    name: 'Aland Islands',
    dial: '358',
    flag: '🇦🇽',
    tz: ['Europe/Mariehamn']
  },
  {
    name: 'Albania',
    dial: '355',
    flag: '🇦🇱',
    tz: ['Europe/Tirane']
  },
  {
    name: 'Algeria',
    dial: '213',
    flag: '🇩🇿',
    tz: ['Africa/Algiers']
  },
  {
    name: 'American Samoa',
    dial: '1684',
    flag: '🇦🇸',
    tz: ['Pacific/Pago_Pago']
  },
  {
    name: 'Andorra',
    dial: '376',
    flag: '🇦🇩',
    tz: ['Europe/Andorra']
  },
  {
    name: 'Angola',
    dial: '244',
    flag: '🇦🇴',
    tz: ['Africa/Luanda']
  },
  {
    name: 'Anguilla',
    dial: '1264',
    flag: '🇦🇮',
    tz: ['America/Anguilla']
  },
  {
    name: 'Antigua and Barbuda',
    dial: '1268',
    flag: '🇦🇬',
    tz: ['America/Antigua']
  },
  {
    name: 'Argentina',
    dial: '54',
    flag: '🇦🇷',
    tz: [
      'America/Argentina/Buenos_Aires',
      'America/Argentina/Catamarca',
      'America/Argentina/Cordoba',
      'America/Argentina/Jujuy',
      'America/Argentina/La_Rioja',
      'America/Argentina/Mendoza',
      'America/Argentina/Rio_Gallegos',
      'America/Argentina/Salta',
      'America/Argentina/San_Juan',
      'America/Argentina/San_Luis',
      'America/Argentina/Tucuman',
      'America/Argentina/Ushuaia'
    ]
  },
  {
    name: 'Armenia',
    dial: '374',
    flag: '🇦🇲',
    tz: ['Asia/Yerevan']
  },
  {
    name: 'Aruba',
    dial: '297',
    flag: '🇦🇼',
    tz: ['America/Aruba']
  },
  {
    name: 'Australia',
    dial: '61',
    flag: '🇦🇺',
    tz: [
      'Australia/Adelaide',
      'Australia/Brisbane',
      'Australia/Broken_Hill',
      'Australia/Currie',
      'Australia/Darwin',
      'Australia/Eucla',
      'Australia/Hobart',
      'Australia/Lindeman',
      'Australia/Lord_Howe',
      'Australia/Melbourne',
      'Australia/Perth',
      'Australia/Sydney'
    ]
  },
  {
    name: 'Austria',
    dial: '43',
    flag: '🇦🇹',
    tz: ['Europe/Vienna']
  },
  {
    name: 'Azerbaijan',
    dial: '994',
    flag: '🇦🇿',
    tz: ['Asia/Baku']
  },
  {
    name: 'Bahamas',
    dial: '1242',
    flag: '🇧🇸',
    tz: ['America/Nassau']
  },
  {
    name: 'Bahrain',
    dial: '973',
    flag: '🇧🇭',
    tz: ['Asia/Bahrain']
  },
  {
    name: 'Bangladesh',
    dial: '880',
    flag: '🇧🇩',
    tz: ['Asia/Dhaka']
  },
  {
    name: 'Barbados',
    dial: '1246',
    flag: '🇧🇧',
    tz: ['America/Barbados']
  },
  {
    name: 'Belgium',
    dial: '32',
    flag: '🇧🇪',
    tz: ['Europe/Brussels']
  },
  {
    name: 'Belize',
    dial: '501',
    flag: '🇧🇿',
    tz: ['America/Belize']
  },
  {
    name: 'Benin',
    dial: '229',
    flag: '🇧🇯',
    tz: ['Africa/Porto-Novo']
  },
  {
    name: 'Bermuda',
    dial: '1441',
    flag: '🇧🇲',
    tz: ['Atlantic/Bermuda']
  },
  {
    name: 'Bhutan',
    dial: '975',
    flag: '🇧🇹',
    tz: ['Asia/Thimphu']
  },
  {
    name: 'Bolivia',
    dial: '591',
    flag: '🇧🇴',
    tz: ['America/La_Paz']
  },
  {
    name: 'Bosnia and Herzegovina',
    dial: '387',
    flag: '🇧🇦',
    tz: ['Europe/Sarajevo']
  },
  {
    name: 'Botswana',
    dial: '267',
    flag: '🇧🇼',
    tz: ['Africa/Gaborone']
  },
  {
    name: 'Brazil',
    dial: '55',
    flag: '🇧🇷',
    tz: [
      'America/Araguaina',
      'America/Bahia',
      'America/Belem',
      'America/Boa_Vista',
      'America/Campo_Grande',
      'America/Cuiaba',
      'America/Eirunepe',
      'America/Fortaleza',
      'America/Maceio',
      'America/Manaus',
      'America/Noronha',
      'America/Porto_Velho',
      'America/Recife',
      'America/Rio_Branco',
      'America/Santarem',
      'America/Sao_Paulo'
    ]
  },
  {
    name: 'British Indian Ocean Territory',
    dial: '246',
    flag: '🇮🇴',
    tz: ['Indian/Chagos']
  },
  {
    name: 'Brunei Darussalam',
    dial: '673',
    flag: '🇧🇳',
    tz: ['Asia/Brunei']
  },
  {
    name: 'Bulgaria',
    dial: '359',
    flag: '🇧🇬',
    tz: ['Europe/Sofia']
  },
  {
    name: 'Burkina Faso',
    dial: '226',
    flag: '🇧🇫',
    tz: ['Africa/Ouagadougou']
  },
  {
    name: 'Burundi',
    dial: '257',
    flag: '🇧🇮',
    tz: ['Africa/Bujumbura']
  },
  {
    name: 'Cambodia',
    dial: '855',
    flag: '🇰🇭',
    tz: ['Asia/Phnom_Penh']
  },
  {
    name: 'Cameroon',
    dial: '237',
    flag: '🇨🇲',
    tz: ['Africa/Douala']
  },
  {
    name: 'Canada',
    dial: '1',
    flag: '🇨🇦',
    tz: [
      'America/Atikokan',
      'America/Blanc-Sablon',
      'America/Cambridge_Bay',
      'America/Creston',
      'America/Dawson',
      'America/Dawson_Creek',
      'America/Edmonton',
      'America/Fort_Nelson',
      'America/Glace_Bay',
      'America/Goose_Bay',
      'America/Halifax',
      'America/Inuvik',
      'America/Iqaluit',
      'America/Moncton',
      'America/Nipigon',
      'America/Pangnirtung',
      'America/Rainy_River',
      'America/Rankin_Inlet',
      'America/Regina',
      'America/Resolute',
      'America/St_Johns',
      'America/Swift_Current',
      'America/Thunder_Bay',
      'America/Toronto',
      'America/Vancouver',
      'America/Whitehorse',
      'America/Winnipeg',
      'America/Yellowknife'
    ]
  },
  {
    name: 'Cape Verde',
    dial: '238',
    flag: '🇨🇻',
    tz: ['Atlantic/Cape_Verde']
  },
  {
    name: 'Cayman Islands',
    dial: '1345',
    flag: '🇰🇾',
    tz: ['America/Cayman']
  },
  {
    name: 'Chad',
    dial: '235',
    flag: '🇹🇩',
    tz: ['Africa/Ndjamena']
  },
  {
    name: 'Chile',
    dial: '56',
    flag: '🇨🇱',
    tz: ['America/Punta_Arenas', 'America/Santiago', 'Pacific/Easter']
  },
  {
    name: 'China',
    dial: '86',
    flag: '🇨🇳',
    tz: ['Asia/Shanghai', 'Asia/Urumqi']
  },
  {
    name: 'Christmas Island',
    dial: '61',
    flag: '🇨🇽',
    tz: ['Indian/Christmas']
  },
  {
    name: 'Cocos (Keeling) Islands',
    dial: '61',
    flag: '🇨🇨',
    tz: ['Indian/Cocos']
  },
  {
    name: 'Colombia',
    dial: '57',
    flag: '🇨🇴',
    tz: ['America/Bogota']
  },
  {
    name: 'Comoros',
    dial: '269',
    flag: '🇰🇲',
    tz: ['Indian/Comoro']
  },
  {
    name: 'Congo, The Democratic Republic of the',
    dial: '243',
    flag: '🇨🇩',
    tz: ['Africa/Kinshasa', 'Africa/Lubumbashi']
  },
  {
    name: 'Cook Islands',
    dial: '682',
    flag: '🇨🇰',
    tz: ['Pacific/Rarotonga']
  },
  {
    name: 'Costa Rica',
    dial: '506',
    flag: '🇨🇷',
    tz: ['America/Costa_Rica']
  },
  {
    name: "Côte d'Ivoire",
    dial: '225',
    flag: '🇨🇮',
    tz: ['Africa/Abidjan']
  },
  {
    name: 'Croatia',
    dial: '385',
    flag: '🇭🇷',
    tz: ['Europe/Zagreb']
  },
  {
    name: 'Cyprus',
    dial: '357',
    flag: '🇨🇾',
    tz: ['Asia/Nicosia', 'Asia/Famagusta']
  },
  {
    name: 'Czech Republic',
    dial: '420',
    flag: '🇨🇿',
    tz: ['Europe/Prague']
  },
  {
    name: 'Denmark',
    dial: '45',
    flag: '🇩🇰',
    tz: ['Europe/Copenhagen']
  },
  {
    name: 'Djibouti',
    dial: '253',
    flag: '🇩🇯',
    tz: ['Africa/Djibouti']
  },
  {
    name: 'Dominica',
    dial: '1767',
    flag: '🇩🇲',
    tz: ['America/Dominica']
  },
  {
    name: 'Dominican Republic',
    dial: '1849',
    flag: '🇩🇴',
    tz: ['America/Santo_Domingo']
  },
  {
    name: 'Ecuador',
    dial: '593',
    flag: '🇪🇨',
    tz: ['America/Guayaquil', 'Pacific/Galapagos']
  },
  {
    name: 'Egypt',
    dial: '20',
    flag: '🇪🇬',
    tz: ['Africa/Cairo']
  },
  {
    name: 'El Salvador',
    dial: '503',
    flag: '🇸🇻',
    tz: ['America/El_Salvador']
  },
  {
    name: 'Equatorial Guinea',
    dial: '240',
    flag: '🇬🇶',
    tz: ['Africa/Malabo']
  },
  {
    name: 'Eritrea',
    dial: '291',
    flag: '🇪🇷',
    tz: ['Africa/Asmara']
  },
  {
    name: 'Estonia',
    dial: '372',
    flag: '🇪🇪',
    tz: ['Europe/Tallinn']
  },
  {
    name: 'Ethiopia',
    dial: '251',
    flag: '🇪🇹',
    tz: ['Africa/Addis_Ababa']
  },
  {
    name: 'Falkland Islands (Malvinas)',
    dial: '500',
    flag: '🇫🇰',
    tz: ['Atlantic/Stanley']
  },
  {
    name: 'Faroe Islands',
    dial: '298',
    flag: '🇫🇴',
    tz: ['Atlantic/Faroe']
  },
  {
    name: 'Fiji',
    dial: '679',
    flag: '🇫🇯',
    tz: ['Pacific/Fiji']
  },
  {
    name: 'Finland',
    dial: '358',
    flag: '🇫🇮',
    tz: ['Europe/Helsinki']
  },
  {
    name: 'France',
    dial: '33',
    flag: '🇫🇷',
    tz: ['Europe/Paris']
  },
  {
    name: 'French Guiana',
    dial: '594',
    flag: '🇬🇫',
    tz: ['America/Cayenne']
  },
  {
    name: 'French Polynesia',
    dial: '689',
    flag: '🇵🇫',
    tz: ['Pacific/Tahiti', 'Pacific/Marquesas', 'Pacific/Gambier']
  },
  {
    name: 'Gabon',
    dial: '241',
    flag: '🇬🇦',
    tz: ['Africa/Libreville']
  },
  {
    name: 'Gambia',
    dial: '220',
    flag: '🇬🇲',
    tz: ['Africa/Banjul']
  },
  {
    name: 'Georgia',
    dial: '995',
    flag: '🇬🇪',
    tz: ['Asia/Tbilisi']
  },
  {
    name: 'Germany',
    dial: '49',
    flag: '🇩🇪',
    tz: ['Europe/Berlin', 'Europe/Busingen']
  },
  {
    name: 'Ghana',
    dial: '233',
    flag: '🇬🇭',
    tz: ['Africa/Accra']
  },
  {
    name: 'Gibraltar',
    dial: '350',
    flag: '🇬🇮',
    tz: ['Europe/Gibraltar']
  },
  {
    name: 'Greece',
    dial: '30',
    flag: '🇬🇷',
    tz: ['Europe/Athens']
  },
  {
    name: 'Greenland',
    dial: '299',
    flag: '🇬🇱',
    tz: [
      'America/Nuuk',
      'America/Danmarkshavn',
      'America/Scoresbysund',
      'America/Thule'
    ]
  },
  {
    name: 'Grenada',
    dial: '1473',
    flag: '🇬🇩',
    tz: ['America/Grenada']
  },
  {
    name: 'Guadeloupe',
    dial: '590',
    flag: '🇬🇵',
    tz: ['America/Guadeloupe']
  },
  {
    name: 'Guam',
    dial: '1671',
    flag: '🇬🇺',
    tz: ['Pacific/Guam']
  },
  {
    name: 'Guatemala',
    dial: '502',
    flag: '🇬🇹',
    tz: ['America/Guatemala']
  },
  {
    name: 'Guinea',
    dial: '224',
    flag: '🇬🇳',
    tz: ['Africa/Conakry']
  },
  {
    name: 'Guinea-Bissau',
    dial: '245',
    flag: '🇬🇼',
    tz: ['Africa/Bissau']
  },
  {
    name: 'Guyana',
    dial: '592',
    flag: '🇬🇾',
    tz: ['America/Guyana']
  },
  {
    name: 'Haiti',
    dial: '509',
    flag: '🇭🇹',
    tz: ['America/Port-au-Prince']
  },
  {
    name: 'Honduras',
    dial: '504',
    flag: '🇭🇳',
    tz: ['America/Tegucigalpa']
  },
  {
    name: 'Hong Kong',
    dial: '852',
    flag: '🇭🇰',
    tz: ['Asia/Hong_Kong']
  },
  {
    name: 'Hungary',
    dial: '36',
    flag: '🇭🇺',
    tz: ['Europe/Budapest']
  },

  {
    name: 'Iceland',
    dial: '354',
    flag: '🇮🇸',
    tz: ['Atlantic/Reykjavik']
  },
  {
    name: 'India',
    dial: '91',
    flag: '🇮🇳',
    tz: ['Asia/Kolkata']
  },
  {
    name: 'Indonesia',
    dial: '62',
    flag: '🇮🇩',
    tz: [
      'Asia/Jakarta',
      'Asia/Pontianak',
      'Asia/Makassar',
      'Asia/Jayapura'
    ]
  },
  {
    name: 'Iraq',
    dial: '964',
    flag: '🇮🇶',
    tz: ['Asia/Baghdad']
  },
  {
    name: 'Ireland',
    dial: '353',
    flag: '🇮🇪',
    tz: ['Europe/Dublin']
  },
  {
    name: 'Isle of Man',
    dial: '44',
    flag: '🇮🇲',
    tz: ['Europe/Isle_of_Man']
  },
  {
    name: 'Israel',
    dial: '972',
    flag: '🇮🇱',
    tz: ['Asia/Jerusalem']
  },
  {
    name: 'Italy',
    dial: '39',
    flag: '🇮🇹',
    tz: ['Europe/Rome']
  },
  {
    name: 'Jamaica',
    dial: '1876',
    flag: '🇯🇲',
    tz: ['America/Jamaica']
  },
  {
    name: 'Japan',
    dial: '81',
    flag: '🇯🇵',
    tz: ['Asia/Tokyo']
  },
  {
    name: 'Jersey',
    dial: '44',
    flag: '🇯🇪',
    tz: ['Europe/Jersey']
  },
  {
    name: 'Jordan',
    dial: '962',
    flag: '🇯🇴',
    tz: ['Asia/Amman']
  },
  {
    name: 'Kazakhstan',
    dial: '7',
    flag: '🇰🇿',
    tz: [
      'Asia/Almaty',
      'Asia/Qyzylorda',
      'Asia/Aqtobe',
      'Asia/Aqtau',
      'Asia/Oral'
    ]
  },
  {
    name: 'Kenya',
    dial: '254',
    flag: '🇰🇪',
    tz: ['Africa/Nairobi']
  },
  {
    name: 'Kiribati',
    dial: '686',
    flag: '🇰🇮',
    tz: ['Pacific/Tarawa', 'Pacific/Enderbury', 'Pacific/Kiritimati']
  },
  {
    name: 'South Korea',
    dial: '82',
    flag: '🇰🇷',
    tz: ['Asia/Seoul']
  },
  {
    name: 'Kuwait',
    dial: '965',
    flag: '🇰🇼',
    tz: ['Asia/Kuwait']
  },
  {
    name: 'Kyrgyzstan',
    dial: '996',
    flag: '🇰🇬',
    tz: ['Asia/Bishkek']
  },
  {
    name: 'Laos',
    dial: '856',
    flag: '🇱🇦',
    tz: ['Asia/Vientiane']
  },
  {
    name: 'Latvia',
    dial: '371',
    flag: '🇱🇻',
    tz: ['Europe/Riga']
  },
  {
    name: 'Lebanon',
    dial: '961',
    flag: '🇱🇧',
    tz: ['Asia/Beirut']
  },
  {
    name: 'Lesotho',
    dial: '266',
    flag: '🇱🇸',
    tz: ['Africa/Maseru']
  },
  {
    name: 'Liberia',
    dial: '231',
    flag: '🇱🇷',
    tz: ['Africa/Monrovia']
  },
  {
    name: 'Liechtenstein',
    dial: '423',
    flag: '🇱🇮',
    tz: ['Europe/Vaduz']
  },
  {
    name: 'Lithuania',
    dial: '370',
    flag: '🇱🇹',
    tz: ['Europe/Vilnius']
  },
  {
    name: 'Luxembourg',
    dial: '352',
    flag: '🇱🇺',
    tz: ['Europe/Luxembourg']
  },
  {
    name: 'Macao',
    dial: '853',
    flag: '🇲🇴',
    tz: ['Asia/Macau']
  },
  {
    name: 'North Macedonia',
    dial: '389',
    flag: '🇲🇰',
    tz: ['Europe/Skopje']
  },
  {
    name: 'Madagascar',
    dial: '261',
    flag: '🇲🇬',
    tz: ['Indian/Antananarivo']
  },
  {
    name: 'Malawi',
    dial: '265',
    flag: '🇲🇼',
    tz: ['Africa/Blantyre']
  },
  {
    name: 'Malaysia',
    dial: '60',
    flag: '🇲🇾',
    tz: ['Asia/Kuala_Lumpur', 'Asia/Kuching']
  },
  {
    name: 'Maldives',
    dial: '960',
    flag: '🇲🇻',
    tz: ['Indian/Maldives']
  },
  {
    name: 'Mali',
    dial: '223',
    flag: '🇲🇱',
    tz: ['Africa/Bamako']
  },
  {
    name: 'Malta',
    dial: '356',
    flag: '🇲🇹',
    tz: ['Europe/Malta']
  },
  {
    name: 'Marshall Islands',
    dial: '692',
    flag: '🇲🇭',
    tz: ['Pacific/Majuro', 'Pacific/Kwajalein']
  },
  {
    name: 'Martinique',
    dial: '596',
    flag: '🇲🇶',
    tz: ['America/Martinique']
  },
  {
    name: 'Mauritania',
    dial: '222',
    flag: '🇲🇷',
    tz: ['Africa/Nouakchott']
  },
  {
    name: 'Mauritius',
    dial: '230',
    flag: '🇲🇺',
    tz: ['Indian/Mauritius']
  },
  {
    name: 'Mayotte',
    dial: '262',
    flag: '🇾🇹',
    tz: ['Indian/Mayotte']
  },
  {
    name: 'Mexico',
    dial: '52',
    flag: '🇲🇽',
    tz: [
      'America/Bahia_Banderas',
      'America/Cancun',
      'America/Chihuahua',
      'America/Hermosillo',
      'America/Matamoros',
      'America/Mazatlan',
      'America/Merida',
      'America/Mexico_City',
      'America/Monterrey',
      'America/Ojinaga',
      'America/Tijuana'
    ]
  },
  {
    name: 'Micronesia, Federated States of',
    dial: '691',
    flag: '🇫🇲',
    tz: ['Pacific/Chuuk', 'Pacific/Pohnpei', 'Pacific/Kosrae']
  },

  {
    name: 'Moldova',
    dial: '373',
    flag: '🇲🇩',
    tz: ['Europe/Chisinau']
  },
  {
    name: 'Monaco',
    dial: '377',
    flag: '🇲🇨',
    tz: ['Europe/Monaco']
  },
  {
    name: 'Mongolia',
    dial: '976',
    flag: '🇲🇳',
    tz: ['Asia/Ulaanbaatar', 'Asia/Hovd', 'Asia/Choibalsan']
  },
  {
    name: 'Montenegro',
    dial: '382',
    flag: '🇲🇪',
    tz: ['Europe/Podgorica']
  },
  {
    name: 'Montserrat',
    dial: '1664',
    flag: '🇲🇸',
    tz: ['America/Montserrat']
  },
  {
    name: 'Morocco',
    dial: '212',
    flag: '🇲🇦',
    tz: ['Africa/Casablanca']
  },
  {
    name: 'Mozambique',
    dial: '258',
    flag: '🇲🇿',
    tz: ['Africa/Maputo']
  },
  {
    name: 'Namibia',
    dial: '264',
    flag: '🇳🇦',
    tz: ['Africa/Windhoek']
  },
  {
    name: 'Nauru',
    dial: '674',
    flag: '🇳🇷',
    tz: ['Pacific/Nauru']
  },
  {
    name: 'Nepal',
    dial: '977',
    flag: '🇳🇵',
    tz: ['Asia/Kathmandu']
  },
  {
    name: 'Netherlands',
    dial: '31',
    flag: '🇳🇱',
    tz: ['Europe/Amsterdam']
  },
  {
    name: 'New Caledonia',
    dial: '687',
    flag: '🇳🇨',
    tz: ['Pacific/Noumea']
  },
  {
    name: 'New Zealand',
    dial: '64',
    flag: '🇳🇿',
    tz: ['Pacific/Auckland', 'Pacific/Chatham']
  },
  {
    name: 'Niger',
    dial: '227',
    flag: '🇳🇪',
    tz: ['Africa/Niamey']
  },
  {
    name: 'Nigeria',
    dial: '234',
    flag: '🇳🇬',
    tz: ['Africa/Lagos']
  },
  {
    name: 'Niue',
    dial: '683',
    flag: '🇳🇺',
    tz: ['Pacific/Niue']
  },
  {
    name: 'Norfolk Island',
    dial: '672',
    flag: '🇳🇫',
    tz: ['Pacific/Norfolk']
  },
  {
    name: 'Northern Mariana Islands',
    dial: '1670',
    flag: '🇲🇵',
    tz: ['Pacific/Saipan']
  },
  {
    name: 'Norway',
    dial: '47',
    flag: '🇳🇴',
    tz: ['Europe/Oslo']
  },
  {
    name: 'Oman',
    dial: '968',
    flag: '🇴🇲',
    tz: ['Asia/Muscat']
  },
  {
    name: 'Pakistan',
    dial: '92',
    flag: '🇵🇰',
    tz: ['Asia/Karachi']
  },
  {
    name: 'Palau',
    dial: '680',
    flag: '🇵🇼',
    tz: ['Pacific/Palau']
  },
  {
    name: 'Panama',
    dial: '507',
    flag: '🇵🇦',
    tz: ['America/Panama']
  },
  {
    name: 'Papua New Guinea',
    dial: '675',
    flag: '🇵🇬',
    tz: ['Pacific/Port_Moresby', 'Pacific/Bougainville']
  },
  {
    name: 'Paraguay',
    dial: '595',
    flag: '🇵🇾',
    tz: ['America/Asuncion']
  },
  {
    name: 'Peru',
    dial: '51',
    flag: '🇵🇪',
    tz: ['America/Lima']
  },
  {
    name: 'Philippines',
    dial: '63',
    flag: '🇵🇭',
    tz: ['Asia/Manila']
  },
  {
    name: 'Pitcairn',
    dial: '872',
    flag: '🇵🇳',
    tz: ['Pacific/Pitcairn']
  },
  {
    name: 'Poland',
    dial: '48',
    flag: '🇵🇱',
    tz: ['Europe/Warsaw']
  },
  {
    name: 'Portugal',
    dial: '351',
    flag: '🇵🇹',
    tz: ['Europe/Lisbon', 'Atlantic/Madeira', 'Atlantic/Azores']
  },
  {
    name: 'Puerto Rico',
    dial: '1939',
    flag: '🇵🇷',
    tz: ['America/Puerto_Rico']
  },
  {
    name: 'Qatar',
    dial: '974',
    flag: '🇶🇦',
    tz: ['Asia/Qatar']
  },
  {
    name: 'Romania',
    dial: '40',
    flag: '🇷🇴',
    tz: ['Europe/Bucharest']
  },
  {
    name: 'Rwanda',
    dial: '250',
    flag: '🇷🇼',
    tz: ['Africa/Kigali']
  },
  {
    name: 'Reunion',
    dial: '262',
    flag: '🇷🇪',
    tz: ['Indian/Reunion']
  },
  {
    name: 'Saint Barthelemy',
    dial: '590',
    flag: '🇧🇱',
    tz: ['America/St_Barthelemy']
  },
  {
    name: 'Saint Helena, Ascension and Tristan Da Cunha',
    dial: '290',
    flag: '🇸🇭',
    tz: ['Atlantic/St_Helena']
  },
  {
    name: 'Saint Kitts and Nevis',
    dial: '1869',
    flag: '🇰🇳',
    tz: ['America/St_Kitts']
  },
  {
    name: 'Saint Lucia',
    dial: '1758',
    flag: '🇱🇨',
    tz: ['America/St_Lucia']
  },
  {
    name: 'Saint Martin',
    dial: '590',
    flag: '🇲🇫',
    tz: ['America/Marigot']
  },
  {
    name: 'Saint Pierre and Miquelon',
    dial: '508',
    flag: '🇵🇲',
    tz: ['America/Miquelon']
  },
  {
    name: 'Saint Vincent and the Grenadines',
    dial: '1784',
    flag: '🇻🇨',
    tz: ['America/St_Vincent']
  },
  {
    name: 'Samoa',
    dial: '685',
    flag: '🇼🇸',
    tz: ['Pacific/Apia']
  },
  {
    name: 'San Marino',
    dial: '378',
    flag: '🇸🇲',
    tz: ['Europe/San_Marino']
  },
  {
    name: 'Sao Tome and Principe',
    dial: '239',
    flag: '🇸🇹',
    tz: ['Africa/Sao_Tome']
  },
  {
    name: 'Saudi Arabia',
    dial: '966',
    flag: '🇸🇦',
    tz: ['Asia/Riyadh']
  },
  {
    name: 'Senegal',
    dial: '221',
    flag: '🇸🇳',
    tz: ['Africa/Dakar']
  },
  {
    name: 'Serbia',
    dial: '381',
    flag: '🇷🇸',
    tz: ['Europe/Belgrade']
  },
  {
    name: 'Seychelles',
    dial: '248',
    flag: '🇸🇨',
    tz: ['Indian/Mahe']
  },

  {
    name: 'Sierra Leone',
    dial: '232',
    flag: '🇸🇱',
    tz: ['Africa/Freetown']
  },
  {
    name: 'Singapore',
    dial: '65',
    flag: '🇸🇬',
    tz: ['Asia/Singapore']
  },
  {
    name: 'Slovakia',
    dial: '421',
    flag: '🇸🇰',
    tz: ['Europe/Bratislava']
  },
  {
    name: 'Slovenia',
    dial: '386',
    flag: '🇸🇮',
    tz: ['Europe/Ljubljana']
  },
  {
    name: 'Solomon Islands',
    dial: '677',
    flag: '🇸🇧',
    tz: ['Pacific/Guadalcanal']
  },
  {
    name: 'South Africa',
    dial: '27',
    flag: '🇿🇦',
    tz: ['Africa/Johannesburg']
  },
  {
    name: 'Spain',
    dial: '34',
    flag: '🇪🇸',
    tz: ['Europe/Madrid', 'Africa/Ceuta', 'Atlantic/Canary']
  },
  {
    name: 'Sri Lanka',
    dial: '94',
    flag: '🇱🇰',
    tz: ['Asia/Colombo']
  },
  {
    name: 'Suriname',
    dial: '597',
    flag: '🇸🇷',
    tz: ['America/Paramaribo']
  },
  {
    name: 'Svalbard and Jan Mayen',
    dial: '47',
    flag: '🇸🇯',
    tz: ['Arctic/Longyearbyen']
  },
  {
    name: 'Eswatini',
    dial: '268',
    flag: '🇸🇿',
    tz: ['Africa/Mbabane']
  },
  {
    name: 'Sweden',
    dial: '46',
    flag: '🇸🇪',
    tz: ['Europe/Stockholm']
  },
  {
    name: 'Switzerland',
    dial: '41',
    flag: '🇨🇭',
    tz: ['Europe/Zurich']
  },
  {
    name: 'Taiwan',
    dial: '886',
    flag: '🇹🇼',
    tz: ['Asia/Taipei']
  },
  {
    name: 'Tajikistan',
    dial: '992',
    flag: '🇹🇯',
    tz: ['Asia/Dushanbe']
  },
  {
    name: 'Tanzania, United Republic of',
    dial: '255',
    flag: '🇹🇿',
    tz: ['Africa/Dar_es_Salaam']
  },
  {
    name: 'Thailand',
    dial: '66',
    flag: '🇹🇭',
    tz: ['Asia/Bangkok']
  },
  {
    name: 'Timor-Leste',
    dial: '670',
    flag: '🇹🇱',
    tz: ['Asia/Dili']
  },
  {
    name: 'Togo',
    dial: '228',
    flag: '🇹🇬',
    tz: ['Africa/Lome']
  },
  {
    name: 'Tokelau',
    dial: '690',
    flag: '🇹🇰',
    tz: ['Pacific/Fakaofo']
  },
  {
    name: 'Tonga',
    dial: '676',
    flag: '🇹🇴',
    tz: ['Pacific/Tongatapu']
  },
  {
    name: 'Trinidad and Tobago',
    dial: '1868',
    flag: '🇹🇹',
    tz: ['America/Port_of_Spain']
  },
  {
    name: 'Tunisia',
    dial: '216',
    flag: '🇹🇳',
    tz: ['Africa/Tunis']
  },
  {
    name: 'Turkey',
    dial: '90',
    flag: '🇹🇷',
    tz: ['Europe/Istanbul']
  },
  {
    name: 'Turkmenistan',
    dial: '993',
    flag: '🇹🇲',
    tz: ['Asia/Ashgabat']
  },
  {
    name: 'Turks and Caicos Islands',
    dial: '1649',
    flag: '🇹🇨',
    tz: ['America/Grand_Turk']
  },
  {
    name: 'Tuvalu',
    dial: '688',
    flag: '🇹🇻',
    tz: ['Pacific/Funafuti']
  },
  {
    name: 'Uganda',
    dial: '256',
    flag: '🇺🇬',
    tz: ['Africa/Kampala']
  },
  {
    name: 'Ukraine',
    dial: '380',
    flag: '🇺🇦',
    tz: [
      'Europe/Kyiv',
      'Europe/Kiev',
      'Europe/Uzhgorod',
      'Europe/Zaporozhye'
    ]
  },
  {
    name: 'United Arab Emirates',
    dial: '971',
    flag: '🇦🇪',
    tz: ['Asia/Dubai']
  },
  {
    name: 'United Kingdom',
    dial: '44',
    flag: '🇬🇧',
    tz: ['Europe/London']
  },
  {
    name: 'Uruguay',
    dial: '598',
    flag: '🇺🇾',
    tz: ['America/Montevideo']
  },
  {
    name: 'Uzbekistan',
    dial: '998',
    flag: '🇺🇿',
    tz: ['Asia/Samarkand', 'Asia/Tashkent']
  },
  {
    name: 'Vanuatu',
    dial: '678',
    flag: '🇻🇺',
    tz: ['Pacific/Efate']
  },
  {
    name: 'Vietnam',
    dial: '84',
    flag: '🇻🇳',
    tz: ['Asia/Ho_Chi_Minh']
  },
  {
    name: 'Virgin Islands, British',
    dial: '1284',
    flag: '🇻🇬',
    tz: ['America/Tortola']
  },
  {
    name: 'Virgin Islands, U.S.',
    dial: '1340',
    flag: '🇻🇮',
    tz: ['America/St_Thomas']
  },
  {
    name: 'Wallis and Futuna',
    dial: '681',
    flag: '🇼🇫',
    tz: ['Pacific/Wallis']
  },
  {
    name: 'Yemen',
    dial: '967',
    flag: '🇾🇪',
    tz: ['Asia/Aden']
  },
  {
    name: 'Zambia',
    dial: '260',
    flag: '🇿🇲',
    tz: ['Africa/Lusaka']
  }
]

const countryFlags = countries.reduce((acc, country) => {
  acc[country.flag] = country
  return acc
}, {})

export default { countries, countryFlags }

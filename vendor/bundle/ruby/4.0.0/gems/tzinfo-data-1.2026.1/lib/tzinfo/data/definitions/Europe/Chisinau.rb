# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Europe
        module Chisinau
          include TimezoneDefinition
          
          timezone 'Europe/Chisinau' do |tz|
            tz.offset :o0, 6920, 0, :LMT
            tz.offset :o1, 6900, 0, :CMT
            tz.offset :o2, 6264, 0, :BMT
            tz.offset :o3, 7200, 0, :EET
            tz.offset :o4, 7200, 3600, :EEST
            tz.offset :o5, 3600, 3600, :CEST
            tz.offset :o6, 3600, 0, :CET
            tz.offset :o7, 10800, 0, :MSK
            tz.offset :o8, 10800, 3600, :MSD
            
            tz.transition 1879, 12, :o1, -2840147720, 5200665307, 2160
            tz.transition 1918, 2, :o2, -1637114100, 697432153, 288
            tz.transition 1931, 7, :o3, -1213148664, 970618571, 400
            tz.transition 1932, 5, :o4, -1187056800, 29122181, 12
            tz.transition 1932, 10, :o3, -1175479200, 29123789, 12
            tz.transition 1933, 4, :o4, -1159754400, 29125973, 12
            tz.transition 1933, 9, :o3, -1144029600, 29128157, 12
            tz.transition 1934, 4, :o4, -1127700000, 29130425, 12
            tz.transition 1934, 10, :o3, -1111975200, 29132609, 12
            tz.transition 1935, 4, :o4, -1096250400, 29134793, 12
            tz.transition 1935, 10, :o3, -1080525600, 29136977, 12
            tz.transition 1936, 4, :o4, -1064800800, 29139161, 12
            tz.transition 1936, 10, :o3, -1049076000, 29141345, 12
            tz.transition 1937, 4, :o4, -1033351200, 29143529, 12
            tz.transition 1937, 10, :o3, -1017626400, 29145713, 12
            tz.transition 1938, 4, :o4, -1001901600, 29147897, 12
            tz.transition 1938, 10, :o3, -986176800, 29150081, 12
            tz.transition 1939, 4, :o4, -970452000, 29152265, 12
            tz.transition 1939, 9, :o3, -954727200, 29154449, 12
            tz.transition 1940, 8, :o4, -927165600, 29158277, 12
            tz.transition 1941, 7, :o5, -898138800, 19441539, 8
            tz.transition 1942, 11, :o6, -857257200, 58335973, 24
            tz.transition 1943, 3, :o5, -844556400, 58339501, 24
            tz.transition 1943, 10, :o6, -828226800, 58344037, 24
            tz.transition 1944, 4, :o5, -812502000, 58348405, 24
            tz.transition 1944, 8, :o7, -800157600, 29175917, 12
            tz.transition 1981, 3, :o8, 354920400
            tz.transition 1981, 9, :o7, 370728000
            tz.transition 1982, 3, :o8, 386456400
            tz.transition 1982, 9, :o7, 402264000
            tz.transition 1983, 3, :o8, 417992400
            tz.transition 1983, 9, :o7, 433800000
            tz.transition 1984, 3, :o8, 449614800
            tz.transition 1984, 9, :o7, 465346800
            tz.transition 1985, 3, :o8, 481071600
            tz.transition 1985, 9, :o7, 496796400
            tz.transition 1986, 3, :o8, 512521200
            tz.transition 1986, 9, :o7, 528246000
            tz.transition 1987, 3, :o8, 543970800
            tz.transition 1987, 9, :o7, 559695600
            tz.transition 1988, 3, :o8, 575420400
            tz.transition 1988, 9, :o7, 591145200
            tz.transition 1989, 3, :o8, 606870000
            tz.transition 1989, 9, :o7, 622594800
            tz.transition 1990, 3, :o8, 638319600
            tz.transition 1990, 5, :o4, 641944800
            tz.transition 1990, 9, :o3, 654652800
            tz.transition 1991, 3, :o4, 670377600
            tz.transition 1991, 9, :o3, 686102400
            tz.transition 1992, 3, :o4, 701820000
            tz.transition 1992, 9, :o3, 717541200
            tz.transition 1993, 3, :o4, 733269600
            tz.transition 1993, 9, :o3, 748990800
            tz.transition 1994, 3, :o4, 764719200
            tz.transition 1994, 9, :o3, 780440400
            tz.transition 1995, 3, :o4, 796168800
            tz.transition 1995, 9, :o3, 811890000
            tz.transition 1996, 3, :o4, 828223200
            tz.transition 1996, 10, :o3, 846363600
            tz.transition 1997, 3, :o4, 859680000
            tz.transition 1997, 10, :o3, 877824000
            tz.transition 1998, 3, :o4, 891129600
            tz.transition 1998, 10, :o3, 909273600
            tz.transition 1999, 3, :o4, 922579200
            tz.transition 1999, 10, :o3, 941328000
            tz.transition 2000, 3, :o4, 954028800
            tz.transition 2000, 10, :o3, 972777600
            tz.transition 2001, 3, :o4, 985478400
            tz.transition 2001, 10, :o3, 1004227200
            tz.transition 2002, 3, :o4, 1017532800
            tz.transition 2002, 10, :o3, 1035676800
            tz.transition 2003, 3, :o4, 1048982400
            tz.transition 2003, 10, :o3, 1067126400
            tz.transition 2004, 3, :o4, 1080432000
            tz.transition 2004, 10, :o3, 1099180800
            tz.transition 2005, 3, :o4, 1111881600
            tz.transition 2005, 10, :o3, 1130630400
            tz.transition 2006, 3, :o4, 1143331200
            tz.transition 2006, 10, :o3, 1162080000
            tz.transition 2007, 3, :o4, 1174780800
            tz.transition 2007, 10, :o3, 1193529600
            tz.transition 2008, 3, :o4, 1206835200
            tz.transition 2008, 10, :o3, 1224979200
            tz.transition 2009, 3, :o4, 1238284800
            tz.transition 2009, 10, :o3, 1256428800
            tz.transition 2010, 3, :o4, 1269734400
            tz.transition 2010, 10, :o3, 1288483200
            tz.transition 2011, 3, :o4, 1301184000
            tz.transition 2011, 10, :o3, 1319932800
            tz.transition 2012, 3, :o4, 1332633600
            tz.transition 2012, 10, :o3, 1351382400
            tz.transition 2013, 3, :o4, 1364688000
            tz.transition 2013, 10, :o3, 1382832000
            tz.transition 2014, 3, :o4, 1396137600
            tz.transition 2014, 10, :o3, 1414281600
            tz.transition 2015, 3, :o4, 1427587200
            tz.transition 2015, 10, :o3, 1445731200
            tz.transition 2016, 3, :o4, 1459036800
            tz.transition 2016, 10, :o3, 1477785600
            tz.transition 2017, 3, :o4, 1490486400
            tz.transition 2017, 10, :o3, 1509235200
            tz.transition 2018, 3, :o4, 1521936000
            tz.transition 2018, 10, :o3, 1540684800
            tz.transition 2019, 3, :o4, 1553990400
            tz.transition 2019, 10, :o3, 1572134400
            tz.transition 2020, 3, :o4, 1585440000
            tz.transition 2020, 10, :o3, 1603584000
            tz.transition 2021, 3, :o4, 1616889600
            tz.transition 2021, 10, :o3, 1635638400
            tz.transition 2022, 3, :o4, 1648342800
            tz.transition 2022, 10, :o3, 1667091600
            tz.transition 2023, 3, :o4, 1679792400
            tz.transition 2023, 10, :o3, 1698541200
            tz.transition 2024, 3, :o4, 1711846800
            tz.transition 2024, 10, :o3, 1729990800
            tz.transition 2025, 3, :o4, 1743296400
            tz.transition 2025, 10, :o3, 1761440400
            tz.transition 2026, 3, :o4, 1774746000
            tz.transition 2026, 10, :o3, 1792890000
            tz.transition 2027, 3, :o4, 1806195600
            tz.transition 2027, 10, :o3, 1824944400
            tz.transition 2028, 3, :o4, 1837645200
            tz.transition 2028, 10, :o3, 1856394000
            tz.transition 2029, 3, :o4, 1869094800
            tz.transition 2029, 10, :o3, 1887843600
            tz.transition 2030, 3, :o4, 1901149200
            tz.transition 2030, 10, :o3, 1919293200
            tz.transition 2031, 3, :o4, 1932598800
            tz.transition 2031, 10, :o3, 1950742800
            tz.transition 2032, 3, :o4, 1964048400
            tz.transition 2032, 10, :o3, 1982797200
            tz.transition 2033, 3, :o4, 1995498000
            tz.transition 2033, 10, :o3, 2014246800
            tz.transition 2034, 3, :o4, 2026947600
            tz.transition 2034, 10, :o3, 2045696400
            tz.transition 2035, 3, :o4, 2058397200
            tz.transition 2035, 10, :o3, 2077146000
            tz.transition 2036, 3, :o4, 2090451600
            tz.transition 2036, 10, :o3, 2108595600
            tz.transition 2037, 3, :o4, 2121901200
            tz.transition 2037, 10, :o3, 2140045200
            tz.transition 2038, 3, :o4, 2153350800, 59172253, 24
            tz.transition 2038, 10, :o3, 2172099600, 59177461, 24
            tz.transition 2039, 3, :o4, 2184800400, 59180989, 24
            tz.transition 2039, 10, :o3, 2203549200, 59186197, 24
            tz.transition 2040, 3, :o4, 2216250000, 59189725, 24
            tz.transition 2040, 10, :o3, 2234998800, 59194933, 24
            tz.transition 2041, 3, :o4, 2248304400, 59198629, 24
            tz.transition 2041, 10, :o3, 2266448400, 59203669, 24
            tz.transition 2042, 3, :o4, 2279754000, 59207365, 24
            tz.transition 2042, 10, :o3, 2297898000, 59212405, 24
            tz.transition 2043, 3, :o4, 2311203600, 59216101, 24
            tz.transition 2043, 10, :o3, 2329347600, 59221141, 24
            tz.transition 2044, 3, :o4, 2342653200, 59224837, 24
            tz.transition 2044, 10, :o3, 2361402000, 59230045, 24
            tz.transition 2045, 3, :o4, 2374102800, 59233573, 24
            tz.transition 2045, 10, :o3, 2392851600, 59238781, 24
            tz.transition 2046, 3, :o4, 2405552400, 59242309, 24
            tz.transition 2046, 10, :o3, 2424301200, 59247517, 24
            tz.transition 2047, 3, :o4, 2437606800, 59251213, 24
            tz.transition 2047, 10, :o3, 2455750800, 59256253, 24
            tz.transition 2048, 3, :o4, 2469056400, 59259949, 24
            tz.transition 2048, 10, :o3, 2487200400, 59264989, 24
            tz.transition 2049, 3, :o4, 2500506000, 59268685, 24
            tz.transition 2049, 10, :o3, 2519254800, 59273893, 24
            tz.transition 2050, 3, :o4, 2531955600, 59277421, 24
            tz.transition 2050, 10, :o3, 2550704400, 59282629, 24
            tz.transition 2051, 3, :o4, 2563405200, 59286157, 24
            tz.transition 2051, 10, :o3, 2582154000, 59291365, 24
            tz.transition 2052, 3, :o4, 2595459600, 59295061, 24
            tz.transition 2052, 10, :o3, 2613603600, 59300101, 24
            tz.transition 2053, 3, :o4, 2626909200, 59303797, 24
            tz.transition 2053, 10, :o3, 2645053200, 59308837, 24
            tz.transition 2054, 3, :o4, 2658358800, 59312533, 24
            tz.transition 2054, 10, :o3, 2676502800, 59317573, 24
            tz.transition 2055, 3, :o4, 2689808400, 59321269, 24
            tz.transition 2055, 10, :o3, 2708557200, 59326477, 24
            tz.transition 2056, 3, :o4, 2721258000, 59330005, 24
            tz.transition 2056, 10, :o3, 2740006800, 59335213, 24
            tz.transition 2057, 3, :o4, 2752707600, 59338741, 24
            tz.transition 2057, 10, :o3, 2771456400, 59343949, 24
            tz.transition 2058, 3, :o4, 2784762000, 59347645, 24
            tz.transition 2058, 10, :o3, 2802906000, 59352685, 24
            tz.transition 2059, 3, :o4, 2816211600, 59356381, 24
            tz.transition 2059, 10, :o3, 2834355600, 59361421, 24
            tz.transition 2060, 3, :o4, 2847661200, 59365117, 24
            tz.transition 2060, 10, :o3, 2866410000, 59370325, 24
            tz.transition 2061, 3, :o4, 2879110800, 59373853, 24
            tz.transition 2061, 10, :o3, 2897859600, 59379061, 24
            tz.transition 2062, 3, :o4, 2910560400, 59382589, 24
            tz.transition 2062, 10, :o3, 2929309200, 59387797, 24
            tz.transition 2063, 3, :o4, 2942010000, 59391325, 24
            tz.transition 2063, 10, :o3, 2960758800, 59396533, 24
            tz.transition 2064, 3, :o4, 2974064400, 59400229, 24
            tz.transition 2064, 10, :o3, 2992208400, 59405269, 24
            tz.transition 2065, 3, :o4, 3005514000, 59408965, 24
            tz.transition 2065, 10, :o3, 3023658000, 59414005, 24
            tz.transition 2066, 3, :o4, 3036963600, 59417701, 24
            tz.transition 2066, 10, :o3, 3055712400, 59422909, 24
            tz.transition 2067, 3, :o4, 3068413200, 59426437, 24
            tz.transition 2067, 10, :o3, 3087162000, 59431645, 24
            tz.transition 2068, 3, :o4, 3099862800, 59435173, 24
            tz.transition 2068, 10, :o3, 3118611600, 59440381, 24
            tz.transition 2069, 3, :o4, 3131917200, 59444077, 24
            tz.transition 2069, 10, :o3, 3150061200, 59449117, 24
            tz.transition 2070, 3, :o4, 3163366800, 59452813, 24
            tz.transition 2070, 10, :o3, 3181510800, 59457853, 24
            tz.transition 2071, 3, :o4, 3194816400, 59461549, 24
            tz.transition 2071, 10, :o3, 3212960400, 59466589, 24
            tz.transition 2072, 3, :o4, 3226266000, 59470285, 24
            tz.transition 2072, 10, :o3, 3245014800, 59475493, 24
            tz.transition 2073, 3, :o4, 3257715600, 59479021, 24
            tz.transition 2073, 10, :o3, 3276464400, 59484229, 24
            tz.transition 2074, 3, :o4, 3289165200, 59487757, 24
            tz.transition 2074, 10, :o3, 3307914000, 59492965, 24
            tz.transition 2075, 3, :o4, 3321219600, 59496661, 24
            tz.transition 2075, 10, :o3, 3339363600, 59501701, 24
            tz.transition 2076, 3, :o4, 3352669200, 59505397, 24
            tz.transition 2076, 10, :o3, 3370813200, 59510437, 24
          end
        end
      end
    end
  end
end

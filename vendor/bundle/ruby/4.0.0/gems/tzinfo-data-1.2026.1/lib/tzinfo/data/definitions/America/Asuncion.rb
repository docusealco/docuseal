# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module America
        module Asuncion
          include TimezoneDefinition
          
          timezone 'America/Asuncion' do |tz|
            tz.offset :o0, -13840, 0, :LMT
            tz.offset :o1, -13840, 0, :AMT
            tz.offset :o2, -14400, 0, :'-04'
            tz.offset :o3, -10800, 0, :'-03'
            tz.offset :o4, -14400, 3600, :'-03'
            
            tz.transition 1890, 1, :o1, -2524507760, 2604278153, 1080
            tz.transition 1931, 10, :o2, -1206389360, 2620754633, 1080
            tz.transition 1972, 10, :o3, 86760000
            tz.transition 1974, 4, :o2, 134017200
            tz.transition 1975, 10, :o4, 181368000
            tz.transition 1976, 3, :o2, 194497200
            tz.transition 1976, 10, :o4, 212990400
            tz.transition 1977, 3, :o2, 226033200
            tz.transition 1977, 10, :o4, 244526400
            tz.transition 1978, 3, :o2, 257569200
            tz.transition 1978, 10, :o4, 276062400
            tz.transition 1979, 4, :o2, 291783600
            tz.transition 1979, 10, :o4, 307598400
            tz.transition 1980, 4, :o2, 323406000
            tz.transition 1980, 10, :o4, 339220800
            tz.transition 1981, 4, :o2, 354942000
            tz.transition 1981, 10, :o4, 370756800
            tz.transition 1982, 4, :o2, 386478000
            tz.transition 1982, 10, :o4, 402292800
            tz.transition 1983, 4, :o2, 418014000
            tz.transition 1983, 10, :o4, 433828800
            tz.transition 1984, 4, :o2, 449636400
            tz.transition 1984, 10, :o4, 465451200
            tz.transition 1985, 4, :o2, 481172400
            tz.transition 1985, 10, :o4, 496987200
            tz.transition 1986, 4, :o2, 512708400
            tz.transition 1986, 10, :o4, 528523200
            tz.transition 1987, 4, :o2, 544244400
            tz.transition 1987, 10, :o4, 560059200
            tz.transition 1988, 4, :o2, 575866800
            tz.transition 1988, 10, :o4, 591681600
            tz.transition 1989, 4, :o2, 607402800
            tz.transition 1989, 10, :o4, 625032000
            tz.transition 1990, 4, :o2, 638938800
            tz.transition 1990, 10, :o4, 654753600
            tz.transition 1991, 4, :o2, 670474800
            tz.transition 1991, 10, :o4, 686721600
            tz.transition 1992, 3, :o2, 699418800
            tz.transition 1992, 10, :o4, 718257600
            tz.transition 1993, 3, :o2, 733546800
            tz.transition 1993, 10, :o4, 749448000
            tz.transition 1994, 2, :o2, 762318000
            tz.transition 1994, 10, :o4, 780984000
            tz.transition 1995, 2, :o2, 793767600
            tz.transition 1995, 10, :o4, 812520000
            tz.transition 1996, 3, :o2, 825649200
            tz.transition 1996, 10, :o4, 844574400
            tz.transition 1997, 2, :o2, 856666800
            tz.transition 1997, 10, :o4, 876024000
            tz.transition 1998, 3, :o2, 888721200
            tz.transition 1998, 10, :o4, 907473600
            tz.transition 1999, 3, :o2, 920775600
            tz.transition 1999, 10, :o4, 938923200
            tz.transition 2000, 3, :o2, 952225200
            tz.transition 2000, 10, :o4, 970372800
            tz.transition 2001, 3, :o2, 983674800
            tz.transition 2001, 10, :o4, 1002427200
            tz.transition 2002, 4, :o2, 1018148400
            tz.transition 2002, 9, :o4, 1030852800
            tz.transition 2003, 4, :o2, 1049598000
            tz.transition 2003, 9, :o4, 1062907200
            tz.transition 2004, 4, :o2, 1081047600
            tz.transition 2004, 10, :o4, 1097985600
            tz.transition 2005, 3, :o2, 1110682800
            tz.transition 2005, 10, :o4, 1129435200
            tz.transition 2006, 3, :o2, 1142132400
            tz.transition 2006, 10, :o4, 1160884800
            tz.transition 2007, 3, :o2, 1173582000
            tz.transition 2007, 10, :o4, 1192939200
            tz.transition 2008, 3, :o2, 1205031600
            tz.transition 2008, 10, :o4, 1224388800
            tz.transition 2009, 3, :o2, 1236481200
            tz.transition 2009, 10, :o4, 1255838400
            tz.transition 2010, 4, :o2, 1270954800
            tz.transition 2010, 10, :o4, 1286078400
            tz.transition 2011, 4, :o2, 1302404400
            tz.transition 2011, 10, :o4, 1317528000
            tz.transition 2012, 4, :o2, 1333854000
            tz.transition 2012, 10, :o4, 1349582400
            tz.transition 2013, 3, :o2, 1364094000
            tz.transition 2013, 10, :o4, 1381032000
            tz.transition 2014, 3, :o2, 1395543600
            tz.transition 2014, 10, :o4, 1412481600
            tz.transition 2015, 3, :o2, 1426993200
            tz.transition 2015, 10, :o4, 1443931200
            tz.transition 2016, 3, :o2, 1459047600
            tz.transition 2016, 10, :o4, 1475380800
            tz.transition 2017, 3, :o2, 1490497200
            tz.transition 2017, 10, :o4, 1506830400
            tz.transition 2018, 3, :o2, 1521946800
            tz.transition 2018, 10, :o4, 1538884800
            tz.transition 2019, 3, :o2, 1553396400
            tz.transition 2019, 10, :o4, 1570334400
            tz.transition 2020, 3, :o2, 1584846000
            tz.transition 2020, 10, :o4, 1601784000
            tz.transition 2021, 3, :o2, 1616900400
            tz.transition 2021, 10, :o4, 1633233600
            tz.transition 2022, 3, :o2, 1648350000
            tz.transition 2022, 10, :o4, 1664683200
            tz.transition 2023, 3, :o2, 1679799600
            tz.transition 2023, 10, :o4, 1696132800
            tz.transition 2024, 3, :o2, 1711249200
            tz.transition 2024, 10, :o4, 1728187200
            tz.transition 2024, 10, :o3, 1728961200
          end
        end
      end
    end
  end
end

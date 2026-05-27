# This code was ported from the java version available here:
# http://grepcode.com/file/repo1.maven.org/maven2/com.ibm.icu/icu4j/51.2/com/ibm/icu/text/RBNFChinesePostProcessor.java

# This code is incomplete, untested, and unused. It should remain here until
# I can figure out why it's necessary in ICU and wether to make use of it here or not.

RULE_SET_NAMES = ["traditional", "simplified", "accounting", "time"]
DIAN = 40670  # decimal point
MARKERS = [
  [33836, 20740, 20806, 12295], # marker chars, last char is the 'zero'
  [19975, 20159, 20806, 12295],
  [33836, 20740, 20806, 38646]
  # need markers for time?
]

def process(str, rule_set)
  # markers depend on what rule set we are using
  buf = str.unpack("U*")

  name = rule_set.name
  format = RULE_SET_NAMES.find_index { |rule_set_name| rule_set.name == rule_set_name }
  long_form = format == 1 || format == 3

  if long_form
    i = buf.index("*".ord)
    while i != -1
      buf.delete(i...i + 1)
      i = buf.index("*".ord)
    end
  else

    # remove unwanted lings
    # a '0' (ling) with * might be removed
    # mark off 10,000 'chunks', markers are Z, Y, W (zhao, yii, and wan)
    # already, we avoid two lings in the same chunk -- ling without * wins
    # now, just need  to avoid optional lings in adjacent chunks
    # process right to left

    # decision matrix:
    # state, situation
    #     state         none       opt.          req.
    #     -----         ----       ----          ----
    # none to right     none       opt.          req.
    # opt. to right     none   clear, none  clear right, req.
    # req. to right     none   clear, none       req.

    # mark chunks with '|' for convenience
    m = MARKERS[format]
    0.upto(m.length - 2) do |i|
      n = buf.index(m[i])
      if n != -1
        buf.insert(n + m[i].length, '|'.ord)
      end
    end

    x = buf.index(DIAN)
    x = buf.length if x == -1

    s = 0   # 0 = none to right, 1 = opt. to right, 2 = req. to right
    n = -1  # previous optional ling
    ling = MARKERS[format][3]

    while x >= 0
      m = buf.rindex("|", x)
      nn = buf.rindex(ling, x)
      ns = 0

      if nn > m
        ns = (nn > 0 && buf[nn - 1] != '*'.ord) ? 2 : 1
      end

      x = m - 1

      # actually much simpler, but leave this verbose for now so it's easier to follow
      case s * 3 + ns
        when 0 # none, none
          s = ns # redundant
          n = -1
        when 1 # none, opt.
          s = ns
          n = nn # remember optional ling to right
        when 2 # none, req.
          s = ns
          n = -1
        when 3 # opt., none
          s = ns
          n = -1
        when 4 # opt., opt.
          # n + ling.length
          buf.delete((nn - 1)...(nn + 1)) # delete current optional ling
          s = 0
          n = -1
        when 5 # opt., req.
          # n + ling.length
          buf.delete((n - 1)...(n + 1)) # delete previous optional ling
          s = ns
          n = -1
        when 6 # req., none
          s = ns
          n = -1
        when 7 # req., opt.
          # nn + ling.length
          buf.delete((nn - 1)...(nn + 1)) # delete current optional ling
          s = 0
          n = -1
        when 8 # req., req.
          s = ns
          n = -1
        else
          raise "Illegal state"
      end
    end

    buf.length.downto(0) do |i|
      if buf[i] == "*".ord || buf[i] == "|".ord
        buf.delete(i...i + 1)
      end
    end
  end

  buf.pack("U*")
end

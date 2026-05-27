#!/usr/bin/ruby -w

$: << "." << "lib"

require "minitest/autorun"
require "minitest/find_minimal_combination"

describe Array, :find_minimal_combination do
  def check(*bad)
    lambda { |sample| bad & sample == bad }
  end

  def record_and_check(tests, *bad)
    lambda { |test| tests << test.join; bad & test == bad }
  end

  def parse_trials s
    s.lines.map { |s| s.chomp.sub(/#.*/, '').delete " " }.reject(&:empty?)
  end

  def assert_steps input, bad, exp
    tests = []

    found = input.find_minimal_combination(&record_and_check(tests, *bad))

    assert_equal bad, found, "algorithm is bad"

    assert_equal parse_trials(exp), tests
  end

  HEX = "0123456789ABCDEF".chars.to_a

  # lvl      collection
  #
  #  0 |         A
  #  1 |     B       C
  #  2 |   D   E   F   G
  #  3 |  H I J K L M N O
  #    |
  #  4 |  0123456789ABCDEF

  def test_ordering_best_case_1
    ary = HEX
    bad = %w[0]
    exp = <<~EOT
      #123456789ABCDEF
      01234567         # HIT! -- level 1 = B, C
      0123             # HIT! -- level 2 = D, E
      01               # HIT! -- level 3 = H, I
      0                # HIT!
    EOT

    assert_steps ary, bad, exp
  end

  def test_ordering_best_case_2
    ary = HEX
    bad = %w[0 1]
    exp = <<~EOT
      01234567         # HIT! -- level 1 = B, C
      0123             # HIT! -- level 2 = D, E
      01               # HIT! -- level 3 = H, I
      0                # miss -- level 4 = 0, 1, n_combos = 1
       1               # miss
      01               # HIT! -- level 3 = H,    n_combos = 2
    EOT

    assert_steps ary, bad, exp
  end

  def test_ordering
    ary = HEX
    bad = %w[1 F]
    exp = <<~EOT
      01234567         # miss -- level 1 = B, C
              89ABCDEF # miss
      0123    89AB     # miss -- level 2 = DF, DG, EF, EG
      0123        CDEF # HIT!
      01          CD   # miss -- level 3 = HN, HO
      01            EF # HIT!
      0             E  # miss -- level 4 = 0E, 0F, 1E, 1F
      0              F # miss
       1            E  # miss
       1             F # HIT!
    EOT

    assert_steps ary, bad, exp
  end

  def self.test_find_minimal_combination max, *bad
    define_method "%s_%s_%s" % [__method__, max, bad.join("_")] do
      a = (1..max).to_a

      assert_equal bad, a.find_minimal_combination(&check(*bad))
    end
  end

  def self.test_find_minimal_combination_and_count max, nsteps, *bad
    define_method "%s_%s_%s_%s" % [__method__, max, nsteps, bad.join("_")] do
      a = (1..max).to_a

      found, count = a.find_minimal_combination_and_count(&check(*bad))

      assert_equal bad, found
      assert_equal nsteps, count
    end
  end

  test_find_minimal_combination    8, 5
  test_find_minimal_combination    8, 2, 7
  test_find_minimal_combination    8, 1, 2, 7
  test_find_minimal_combination    8, 1, 4, 7
  test_find_minimal_combination    8, 1, 3, 5, 7

  test_find_minimal_combination    9, 5
  test_find_minimal_combination    9, 9
  test_find_minimal_combination    9, 2, 7
  test_find_minimal_combination    9, 1, 2, 7
  test_find_minimal_combination    9, 1, 4, 7
  test_find_minimal_combination    9, 1, 3, 5, 7

  test_find_minimal_combination 1023, 5
  test_find_minimal_combination 1023, 1005
  test_find_minimal_combination 1023, 802, 907
  test_find_minimal_combination 1023, 7, 15, 166, 1001
  test_find_minimal_combination 1023, 1000, 1001, 1002
  test_find_minimal_combination 1023, 1001, 1003, 1005, 1007
  test_find_minimal_combination 1024, 1001, 1003, 1005, 1007
  test_find_minimal_combination 1024, 1, 1024

  test_find_minimal_combination_and_count 1024, 12, 1, 2
  test_find_minimal_combination_and_count 1024, 23, 1, 1023
  test_find_minimal_combination_and_count 1024, 24, 1, 1024
  test_find_minimal_combination_and_count 1023, 26, 1, 1023

  test_find_minimal_combination_and_count 1024, 93, 1001, 1003, 1005, 1007
  test_find_minimal_combination_and_count 1023, 93, 1001, 1003, 1005, 1007
end

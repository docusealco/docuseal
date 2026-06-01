require "minitest/autorun"
require "minitest/bisect"

module TestMinitest; end

class TestMinitest::TestBisect < Minitest::Test
  attr_accessor :bisect

  def setup
    self.bisect = Minitest::Bisect.new
    bisect.reset
  end

  def test_class_run
    skip "Need to write test_class_run"
  end

  def test_bisect_files
    skip "Need to write test_bisect_files"
  end

  def test_bisect_methods
    skip "Need to write test_bisect_methods"
  end

  def test_build_files_cmd
    files = %w[a.rb b.rb c.rb]
    rb    = %w[-Ilib:test]
    mt    = %w[--seed 42]

    exp = "minitest -Ilib:test a.rb b.rb c.rb --seed 42"
    act = bisect.build_files_cmd(files, rb, mt, cmd:"minitest")

    assert_equal exp, act
  end

  def test_build_methods_cmd
    cmd = "cmd"
    assert_equal "cmd", bisect.build_methods_cmd(cmd)
  end

  def test_build_methods_cmd_verify
    cmd = "cmd"
    cul = []
    bad = %w[A#test_1 B#test_2]

    exp = "cmd -n \"/^(?:A#(?:test_1)|B#(?:test_2))$/\""

    assert_equal exp, bisect.build_methods_cmd(cmd, cul, bad)
  end

  def test_build_methods_cmd_verify_same
    cmd = "cmd"
    cul = []
    bad = %w[C#test_5 C#test_6]

    exp = "cmd -n \"/^(?:C#(?:test_5|test_6))$/\""

    assert_equal exp, bisect.build_methods_cmd(cmd, cul, bad)
  end

  def test_build_methods_cmd_full
    cmd = "cmd"
    cul = %w[A#test_1 A#test_2 B#test_3 B#test_4]
    bad = %w[C#test_5 C#test_6]

    a = "A#(?:test_1|test_2)"
    b = "B#(?:test_3|test_4)"
    c = "C#(?:test_5|test_6)"
    exp = "cmd -n \"/^(?:#{a}|#{b}|#{c})$/\""

    assert_equal exp, bisect.build_methods_cmd(cmd, cul, bad)
  end

  def test_build_re
    bad = %w[A#test_1 B#test_2]

    exp = "/^(?:A#(?:test_1)|B#(?:test_2))$/"

    assert_equal exp, bisect.build_re(bad)
  end

  def test_build_re_same
    bad = %w[C#test_5 C#test_6]

    exp = "/^(?:C#(?:test_5|test_6))$/"

    assert_equal exp, bisect.build_re(bad)
  end

  def test_build_re_class_escaping
    bad = ["{}#[]"]

    exp = "/^(?:\\{\\}#(?:\\[\\]))$/"

    assert_equal exp, bisect.build_re(bad)
  end

  def test_build_re_method_escaping
    bad = ["Some Class#It shouldn't care what the name is"]

    exp = "/^(?:Some Class#(?:It shouldn\\'t care what the name is))$/"

    assert_equal exp, bisect.build_re(bad)
  end

  def test_map_failures
    bisect.failures =
      {
       "file.rb" => { "Class" => %w[test_method1 test_method2] },
       "blah.rb" => { "Apple" => %w[test_method3 test_method4] },
      }

    exp = %w[
           Apple#test_method3
           Apple#test_method4
           Class#test_method1
           Class#test_method2
          ]

    assert_equal exp, bisect.map_failures
  end

  def test_minitest_result
    bisect.minitest_result "file.rb", "TestClass", "test_method", [], 1, 1

    assert_equal false, bisect.tainted
    assert_empty bisect.failures
    assert_equal ["TestClass#test_method"], bisect.culprits
  end

  def test_minitest_result_skip
    fail = Minitest::Skip.new("woot")

    bisect.minitest_result "file.rb", "TestClass", "test_method", [fail], 1, 1

    assert_equal false, bisect.tainted
    assert_empty bisect.failures
    assert_equal ["TestClass#test_method"], bisect.culprits
  end

  def test_minitest_result_fail
    fail = Minitest::Assertion.new "msg"

    bisect.minitest_result "file.rb", "TestClass", "test_method", [fail], 1, 1

    exp = {"file.rb" => {"TestClass" => ["test_method"] }}

    assert_equal true, bisect.tainted
    assert_equal exp, bisect.failures
    assert_empty bisect.culprits
  end

  def test_minitest_result_error
    fail = Minitest::UnexpectedError.new RuntimeError.new("woot")

    bisect.minitest_result "file.rb", "TestClass", "test_method", [fail], 1, 1

    exp = {"file.rb" => {"TestClass" => ["test_method"] }}

    assert_equal true, bisect.tainted
    assert_equal exp, bisect.failures
    assert_empty bisect.culprits
  end

  def test_minitest_start
    bisect.failures["file.rb"]["Class"] << "test_bad1"

    bisect.minitest_start

    assert_empty bisect.failures
  end

  def test_reset
    bisect.seen_bad = true
    bisect.tainted  = true
    bisect.failures["file.rb"]["Class"] << "test_bad1"
    bisect.culprits << "A#test_1" << "B#test_2"

    bisect.reset

    assert_equal false, bisect.seen_bad
    assert_equal false, bisect.tainted
    assert_empty bisect.failures
    assert_equal %w[A#test_1 B#test_2], bisect.culprits
  end

  def test_run
    skip "Need to write test_run"
  end

  def test_time_it
    exp = /\Ado stuff: in 0.\d\d sec\n\z/

    assert_output exp, "" do
      bisect.time_it "do stuff:", "echo you should not see me"
    end
  end
end

class TestMinitest::TestBisect::TestPathExpander < Minitest::Test
  def setup
    @orig_i = $LOAD_PATH.dup
    @orig_w = $VERBOSE
    @orig_d = $DEBUG
  end

  def teardown
    $LOAD_PATH.replace @orig_i
    $VERBOSE = @orig_w
    $DEBUG   = @orig_d
  end

  def test_sanity
    args = %w[1 -Iblah 2 -d 3 -w 4 5 6 lib/hoe] # lib to not have any test files

    mtbpe = Minitest::Bisect::PathExpander
    expander = mtbpe.new args

    files = expander.process.to_a # to_a forces process -> files

    assert_empty files
    assert_empty $LOAD_PATH - @orig_i
    assert_equal %w[-Iblah -d -w], expander.rb_flags
    assert_equal %w[1 2 3 4 5 6], args
    assert_same mtbpe::TEST_GLOB, expander.glob
  end

  def test_process_flags
    args = %w[1 -Iblah 2 -d 3 -w 4 5 6]

    expander = Minitest::Bisect::PathExpander.new args

    exp_files = %w[1 2 3 4 5 6]
    exp_flags = %w[-Iblah -d -w]

    files = expander.process_flags(args)

    assert_equal files, exp_files

    # process_flags only filters and does not mutate args
    assert_same args, expander.args
    refute_equal args, exp_files
    refute_equal files, args

    # separates rb_flags out for separate handling
    assert_equal exp_flags, expander.rb_flags
  end
end

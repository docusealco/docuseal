require "minitest/autorun"
require "minitest/path_expander"

class TestPathExpander < Minitest::Test
  attr_accessor :args
  attr_accessor :expander

  MT_VPE = Minitest::VendoredPathExpander

  def setup
    super

    self.args = []

    self.expander = MT_VPE.new args, "*.rb"

    @pe_tmp_path = "test/pe_tmp"
    @pe_tst_path = "test/pe_tmp/test"

    @orig_pwd = Dir.pwd
    FileUtils.mkdir_p @pe_tst_path
    FileUtils.touch ["#{@pe_tst_path}/test_path_expander.rb", "#{@pe_tst_path}/test_bad.rb"]
    Dir.chdir @pe_tmp_path
  end

  def teardown
    super

    Dir.chdir @orig_pwd

    FileUtils.rm_rf @pe_tmp_path
  end

  def assert_filter_files exp, filter, files = %w[test/dog_and_cat.rb]
    ignore = StringIO.new filter
    act = expander.filter_files files, ignore
    assert_equal exp, act
  end

  def assert_filter_files_absolute_paths exp, filter, files = [File.join(Dir.pwd, 'test/dog_and_cat.rb')]
    assert_filter_files exp, filter, files
  end

  def assert_process_args exp_files, exp_args, *args
    expander.args.concat args

    assert_equal [exp_files.sort, exp_args], expander.process_args
  end

  def test_expand_dirs_to_files
    exp = %w[test/test_bad.rb test/test_path_expander.rb]

    assert_equal exp, expander.expand_dirs_to_files("test")
    assert_equal %w[Rakefile], expander.expand_dirs_to_files("Rakefile")
  end

  def test_expand_dirs_to_files__sorting
    exp = %w[test/test_bad.rb test/test_path_expander.rb]
    input = %w[test/test_path_expander.rb test/test_bad.rb]

    assert_equal exp, expander.expand_dirs_to_files(*input)
    assert_equal %w[Rakefile], expander.expand_dirs_to_files("Rakefile")
  end

  def test_expand_dirs_to_files__leading_dot
    exp = %w[test/test_bad.rb test/test_path_expander.rb]

    assert_equal exp, expander.expand_dirs_to_files("./test")
  end

  def test_filter_files_dir
    assert_filter_files [], "test/"
    assert_filter_files_absolute_paths [], "test/"
  end

  def test_filter_files_files
    example = %w[test/file.rb test/sub/file.rb top/test/perf.rb]
    example_absolute_paths = example.map { |e| File.join(Dir.pwd, e) }

    assert_filter_files [], "test/*.rb"

    assert_filter_files example[1..-1], "test/*.rb", example

    assert_filter_files_absolute_paths [], "test/*.rb"

    assert_filter_files_absolute_paths example_absolute_paths[1..-1], "test/*.rb", example_absolute_paths
  end

  def test_filter_files_glob
    assert_filter_files [], "test*"
    assert_filter_files [], "test*", ["test/lib/woot.rb"]
    assert_filter_files [], "*.rb"
    assert_filter_files [], "*dog*.rb"

    assert_filter_files_absolute_paths [], "test*"
    assert_filter_files_absolute_paths [], "test*", [File.join(Dir.pwd, "test/lib/woot.rb")]
    assert_filter_files_absolute_paths [], "*.rb"
    assert_filter_files_absolute_paths [], "*dog*.rb"
  end

  def test_filter_files_glob_miss
    miss = %w[test/dog_and_cat.rb]
    miss_absolute = [File.join(Dir.pwd, 'test/dog_and_cat.rb')]

    assert_filter_files miss, "test"
    assert_filter_files miss, "nope"

    assert_filter_files_absolute_paths miss_absolute, "test"
    assert_filter_files_absolute_paths miss_absolute, "nope"
  end

  def test_filter_files__ignore_file
    files = expander.expand_dirs_to_files "test"

    File.write ".mtignore", "test/*.rb"

    act = expander.filter_files files, ".mtignore"

    assert_equal [], act
  end

  def test_process
    self.args.concat %w[test --seed 42]

    act = expander.process

    assert_kind_of Enumerator, act
    assert_equal %w[test/test_bad.rb test/test_path_expander.rb], act.to_a
    assert_equal %w[--seed 42], expander.args
    assert_equal %w[--seed 42], args # affected our original array (eg, ARGV)
  end

  def test_process__block
    self.args.concat %w[test --seed 42]

    act = []
    result = expander.process { |x| act << x }

    assert_same expander, result
    assert_equal %w[test/test_bad.rb test/test_path_expander.rb], act.to_a
    assert_equal %w[--seed 42], expander.args
    assert_equal %w[--seed 42], args # affected our original array (eg, ARGV)
  end

  def with_tempfile *lines
    require "tempfile"

    Tempfile.open("tmp") do |f|
      f.puts lines
      f.flush
      f.rewind

      yield f
    end
  end

  def test_process_args_at
    with_tempfile %w[test -test/test_bad.rb --seed 24] do |f|
      assert_process_args(%w[test/test_path_expander.rb],
                          %w[--seed 24],
                          "@#{f.path}")
    end
  end

  def test_process_args_dash_dir
    assert_process_args(%w[],
                        %w[],
                        "test", "-test")
  end

  def test_process_args_dash_file
    assert_process_args(%w[test/test_path_expander.rb],
                        %w[],
                        "test", "-test/test_bad.rb")

  end

  def test_process_args_dash_other
    assert_process_args(%w[],
                        %w[--verbose],
                        "--verbose")
  end

  def test_process_args_dir
    assert_process_args(%w[test/test_bad.rb test/test_path_expander.rb],
                        %w[],
                        "test")
  end

  def test_process_args_file
    assert_process_args(%w[test/test_path_expander.rb],
                        %w[],
                        "test/test_path_expander.rb")
  end

  def test_process_args_other
    assert_process_args(%w[],
                        %w[42],
                        "42")
  end

  def test_process_args_root
    assert_process_args(%w[],
                        %w[-n /./],
                        "-n",
                        "/./")
  end

  def test_process_args_no_files
    self.expander = MT_VPE.new args, "*.rb", "test" # extra test default

    assert_process_args(%w[test/test_bad.rb test/test_path_expander.rb],
                        %w[-v],
                        "-v")
  end

  def test_process_args_dash
    assert_process_args(%w[-],
                        %w[-v],
                        "-", "-v")
  end

  def test_process_flags
    exp = %w[a b c]
    act = expander.process_flags %w[a b c]

    assert_equal exp, act
  end
end

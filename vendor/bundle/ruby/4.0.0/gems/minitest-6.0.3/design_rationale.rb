# Specs:                               # Equivalent Unit Tests:
###############################################################################
describe Thingy do                     # class TestThingy < Minitest::Test
  before do                            #   def setup
                                       #     super
    do_some_setup                      #     do_some_setup
  end                                  #   end
                                       #
  it "should do the first thing" do    #   def test_first_thing
    _(1).must_equal 1                  #     assert_equal 1, 1
  end                                  #   end
                                       # end
                                       #
  describe SubThingy do                # class TestSubThingy < TestThingy
    before do                          #   def setup
                                       #     super
      do_more_setup                    #     do_more_setup
    end                                #   end
                                       #
    it "should do the second thing" do #   def test_second_thing
      _(2).must_equal 2                #     assert_equal 2, 2
    end                                #   end
  end                                  # end
end                                    #
                                       #
###############################################################################
# runs 2 specs                         # runs 3 tests
###############################################################################
# The specs generate:

class ThingySpec < Minitest::Spec
  def setup
    super
    do_some_setup
  end

  def test_should_do_the_first_thing
    _(1).must_equal 1
  end
end

class SubThingySpec < ThingySpec
  def setup
    super
    do_more_setup
  end

  # because only setup/teardown is inherited, not specs
  remove_method :test_should_do_the_first_thing

  def test_should_do_the_second_thing
    _(2).must_equal 2
  end
end

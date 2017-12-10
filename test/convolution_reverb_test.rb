require 'test/unit'
require_relative '../src/convolution_reverb'

class TestConvolutionReverb < Test::Unit::TestCase
  def test_ceil
    actual = ceil(1.0001)
    expected = 2

    assert_equal expected, actual
  end
end

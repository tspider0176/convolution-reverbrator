require 'test/unit'
require_relative '../src/convolution_reverb'

class TestConvolutionReverb < Test::Unit::TestCase
  def test_ceil_cond1
    actual = ceil(1.0001)
    expected = 2

    assert_equal expected, actual
  end

  def test_ceil_cond2
    actual = ceil(2)
    expected = 3

    assert_equal expected, actual
  end

  def test_nextpow2_cond1
    actual = nextpow2(65_536)
    expected = 17

    assert_equal actual, expected
  end

  def test_nextpow2_cond2
    actual = nextpow2(0.5)
    expected = 0

    assert_equal actual, expected
  end

  def test_zeros_cond1
    assert_equal zeros(3), [0, 0, 0]
  end

  def test_zeros_cond2
    assert_equal zeros(0), []
  end
end

require 'test/unit'
require_relative '../src/convolution_reverb'

class TestConvolutionReverb < Test::Unit::TestCase
  def test_ceil_cond1
    assert_equal 2, ceil(1.0001)
  end

  def test_ceil_cond2
    assert_equal 3, ceil(2)
  end

  def test_nextpow2_cond1
    assert_equal 17, nextpow2(65_536)
  end

  def test_nextpow2_cond2
    assert_equal 0, nextpow2(0.5)
  end

  def test_zeros_cond1
    assert_equal [0, 0, 0], zeros(3)
  end

  def test_zeros_cond2
    assert_equal [], zeros(0)
  end
end

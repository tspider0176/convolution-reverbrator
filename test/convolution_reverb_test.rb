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
=begin
  def test_fft
    zero = Complex.polar(0, 0)
    # https://www.wolframalpha.com/input/?i=Fourier%5B%7B1,1,1,1%7D%5D
    assert_equal [2, zero, zero, zero], fft([1, 1, 1, 1])
  end
=end

  def test_normalize_cond1
    actual = normalize([1, -1, 5, -3])
    expected = [1, -1, 5, -3]

    assert_equal expected, actual
  end

  def test_normalize_cond2
    actual = normalize([32_767, -32_768, 1, -1])
    expected = [32_767, -32_768, 1, -1]

    assert_equal expected, actual
  end

  def test_normalize_cond3
    actual = normalize([65_535, -65_536, 32_767, -32_768])
    expected = [32_767, -32_767, 16_383, -16_383]

    assert_equal expected, actual
  end
end

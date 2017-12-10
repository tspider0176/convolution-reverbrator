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

  def test_transform
    actual = transform([32_767, -32_768, 16_383, -16_384])
    expected = [1.0, -1.0, 16_383 / 32_767.0, -16_384 / 32_768.0]

    assert_equal expected, actual
  end

  def test_mul_vec
    actual = mul_vec([1, 2, 3], [2, 3, 4])
    expected = [2, 6, 12]

    assert_equal expected, actual
  end

  def test_extended_impulse
    actual = extended_impulse([1, 1, 1, 1], 8)
    expected = [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0]

    assert_equal expected, actual
  end

  def test_extended_signal
    actual = extended_signal([1, 1, 1, 1], 2, 8)
    expected = [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0]

    assert_equal expected, actual
  end

  def test_calc_frame_num
    actual = calc_frame_num([1, 1, 1, 1], 8)
    expected = 2

    assert_equal expected, actual
  end

  def test_calc_frame_length
    actual = calc_frame_length([1, 1, 1, 1])
    expected = 8

    assert_equal expected, actual
  end
end

require 'rubygems'
require 'wav-file'
require 'matrix'

SIGNED_SHORT_MAX = '111111111111111'.to_i(2)
SIGNED_SHORT_MIN = -1 * '1000000000000000'.to_i(2)

# => test_ceil
def ceil(f)
  f.to_i + 1
end

# => test_nextpow2
def nextpow2(n)
  ceil(Math.log2(n))
end

# => test_zeros
def zeros(n)
  Array.new(n, 0)
end

# => test_fft
# Power:
# fft(...).map{|i| i.abs / n / 2}
def fft(a, tf = 1)
  n = a.size
  t = 2 * Math::PI / n
  return a if n == 1
  a1 = fft((0..n / 2 - 1).map { |i| a[i] + a[i + n / 2] }, tf)
  a2 = fft(
    (0..n / 2 - 1).map do |i|
      (a[i] - a[i + n / 2]) * (Complex.polar(1, (tf == 1 ? -1 : 1) * t)**i)
    end, tf
  )
  a1.zip(a2).flatten
end

def ifft(a)
  fft(a, -1).map { |x| x / a.length }
end

# => test_normalize
def normalize(wavs)
  cond = wavs.max <= SIGNED_SHORT_MAX && wavs.min >= SIGNED_SHORT_MIN
  peak = wavs.max > SIGNED_SHORT_MAX ? wavs.max : wavs.min
  rate = cond ? 1 : SIGNED_SHORT_MAX / peak.to_f
  wavs.map do |data|
    data * rate
  end.map(&:to_i)
end

# => test_transform
def transform(wavs)
  wavs.map do |i|
    i > 0 ? i / SIGNED_SHORT_MAX.to_f : i / SIGNED_SHORT_MIN.abs.to_f
  end
end

def part_fft(signal, start_point, end_point)
  fft(signal[start_point...end_point])
end

# => test_mul_vec
def mul_vec(w1, w2)
  w1.zip(w2).map { |f, s| f * s }
end

def convolution_on_freq(signal, impulse, i, n)
  start_point = n * i
  end_point = n * (i + 2)
  part_fft = part_fft(signal, start_point, end_point)
  result = mul_vec(part_fft, impulse)
  ifft(result).map(&:real)
end

# => test_extended_impulse
def extended_impulse(impulse, n)
  zeros(n) + impulse + zeros(n - impulse.length)
end

# => test_extended_signal
def extended_signal(signal, frame_num, n)
  zeros(n) + signal + zeros(n * frame_num - signal.length - n)
end

# => test_calc_frame_num
def calc_frame_num(signal, n)
  ceil((signal.length + n) / n.to_f).to_i
end

# => test_calc_frame_length
def calc_frame_length(impulse)
  2**nextpow2(impulse.length).to_i
end

def convolution_proc(extended_signal, extended_impulse, frame_num, n)
  impulse_fft = fft(extended_impulse)
  (0...frame_num - 1).map do |i|
    convolution_on_freq(extended_signal, impulse_fft, i, n)[0...n]
  end
end

def convolution_reverb(signal, impulse)
  n = calc_frame_length(impulse)
  extended_impulse = extended_impulse(impulse, n)

  frame_num = calc_frame_num(signal, n)
  extended_signal = extended_signal(signal, frame_num, n)

  r = convolution_proc(extended_signal, extended_impulse, frame_num, n)
  r.flatten[0...extended_signal.length].map { |i| i * SIGNED_SHORT_MAX }.map(&:to_i)
end

def get_wav_array(data_chunk, format)
  data_chunk.data.unpack(bit_per_sample(format))
end

def bit_per_sample(format)
  format.bitPerSample == 16 ? 's*' : 'c*'
end

def read(file_name)
  f = open(file_name)
  format = WavFile.readFormat(f)
  data_chunk = WavFile.readDataChunk(f)
  f.close
  get_wav_array(data_chunk, format)
end

def output(input_file_name, file_name, data)
  f = open(input_file_name)
  format = WavFile.readFormat(f)
  data_chunk = WavFile.readDataChunk(f)
  f.close

  data_chunk.data = data.pack(bit_per_sample(format))
  open(file_name, 'w') do |out|
    WavFile.write(out, format, [data_chunk])
  end
end


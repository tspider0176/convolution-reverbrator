require 'rubygems'
require 'wav-file'
require 'benchmark'
require 'matrix'

SIGNED_SHORT_MAX = '111111111111111'.to_i(2)

def get_wav_array(data_chunk, format)
  data_chunk.data.unpack(bit_per_sample(format))
end

def bit_per_sample(format)
  format.bitPerSample == 16 ? 's*' : 'c*'
end

def ceil(f)
  f.to_i + 1
end

def nextpow2(n)
  Math.log2(2**ceil(Math.log2(n)))
end

def zeros(n)
  Array.new(n, 0)
end

def fft(a, tf = 1)
  n = a.size
  return a if n == 1
  w = tf == 1 ? Complex.polar(1, -2 * Math::PI / n) : Complex.polar(1, 2 * Math::PI / n)
  a1 = fft((0..n / 2 - 1).map { |i| a[i] + a[i + n / 2] }, tf)
  a2 = fft((0..n / 2 - 1).map { |i| (a[i] - a[i + n / 2]) * (w**i) }, tf)
  a1.zip(a2).flatten
end

def ifft(a, n)
  fft(a, -1).map { |x| x / n }
end

def read(file_name)
  f = open(file_name)
  format = WavFile.readFormat(f)
  data_chunk = WavFile.readDataChunk(f)
  f.close
  get_wav_array(data_chunk, format)
end

def convolution_reverb(input, impulse)
  n = 2**nextpow2(impulse.length).to_i

  new_impulse = impulse + zeros(n - impulse.length)
  new_impulse_n2 = zeros(n) + new_impulse
  new_impulse_n2 = new_impulse_n2.map { |i| i / SIGNED_SHORT_MAX.to_f }

  frame_num = ceil((input.length + n) / n.to_f).to_i
  new_sig_length = n * frame_num
  new_signal = zeros(n) + input + zeros(new_sig_length - input.length - n)
  new_signal = new_signal.map { |i| i / SIGNED_SHORT_MAX.to_f }

  impulse_fft = fft(new_impulse_n2)

  r = (0...frame_num - 1).map { |i|
    start_point = n * i
    end_point = n * (i + 2)
    part_fft = fft(new_signal[start_point...end_point])

    convolution = part_fft.zip(impulse_fft).map { |f, s| f * s }

    res = ifft(convolution, 2 * n).map(&:real)

    res[0...n]
  }.flatten

  r[0...input.length].map { |i| i * SIGNED_SHORT_MAX }.map(&:to_i)
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

input = read(ARGV[0])
impulse = read(ARGV[1])

res = convolution_reverb(input, impulse)

output(ARGV[0], 'output.wav', res)

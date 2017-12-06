require 'rubygems'
require 'wav-file'
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
  w = if tf == 1
        Complex.polar(1, -2 * Math::PI / n)
      else
        Complex.polar(1, 2 * Math::PI / n)
      end
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

def normalize(wavs)
  peak = [wavs.max, wavs.min.abs].max
  rate = SIGNED_SHORT_MAX / peak.to_f
  wavs.map do |data|
    data * rate
  end.map(&:to_i)
end

def transform(wavs)
  wavs.map { |i| i / SIGNED_SHORT_MAX.to_f }
end

def part_fft(signal, start_point, end_point)
  fft(signal[start_point...end_point])
end

def mul_vec(w1, w2)
  w1.zip(w2).map { |f, s| f * s }
end

def convolution_on_freq(signal, impulse, i, n)
  start_point = n * i
  end_point = n * (i + 2)
  part_fft = part_fft(signal, start_point, end_point)
  result = mul_vec(part_fft, impulse)
  ifft(result, 2 * n).map(&:real)
end

def extended_impulse(impulse, n)
  zeros(n) + impulse + zeros(n - impulse.length)
end

def extended_signal(signal, frame_num, n)
  zeros(n) + signal + zeros(n * frame_num - signal.length - n)
end

def calc_frame_num(signal, n)
  ceil((signal.length + n) / n.to_f).to_i
end

def calc_frame_length(impulse)
  2**nextpow2(impulse.length).to_i
end

def convolution_proc(extended_signal, extended_impulse, n)
  impulse_fft = fft(extended_impulse)
  (0...frame_num - 1).map do |i|
    convolution_on_freq(extended_signal, impulse_fft, i, n)[0...n]
  end
end

def convolution_reverb(signal, impulse)
  n = calc_frame_length(impulse)
  extended_impulse = extended_impulse(impulse, n)

  frame_num = calc_frame(signal, n)
  extended_signal = extended_signal(signal, frame_num, n)

  convolution_proc(extended_signal, extended_impulse, n)
  r.flatten[0...signal.length].map { |i| i * SIGNED_SHORT_MAX }.map(&:to_i)
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

res = convolution_reverb(transform(input), transform(impulse))

output(ARGV[0], 'output.wav', normalize(res))

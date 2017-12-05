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

f = open(ARGV[0])
format = WavFile.readFormat(f)
data_chunk = WavFile.readDataChunk(f)
input = get_wav_array(data_chunk, format)
f.close

f = open(ARGV[1])
format = WavFile.readFormat(f)
data_chunk = WavFile.readDataChunk(f)
impulse = get_wav_array(data_chunk, format)
f.close

puts 'input length'
p input.length
puts 'impulse length'
p impulse.length


=begin
M = 32
impulse = (0...M).map do |n|
  v = Math.sin(2 * 2 * Math::PI * n / M) * 2
  v + Math.cos(5 * 2 * Math::PI * n / M)
end

input = (0...M).map do |n|
  v = Math.sin(2 * 2 * Math::PI * n / M) * 2
  v + Math.cos(5 * 2 * Math::PI * n / M)
end


fft_im = fft(impulse)
ifft_im = fft(fft_im, -1)
puts "im"
p impulse
puts "ifft_im"
p ifft_im.map{|i| i / M}.map(&:real)
=end

# 1 インパルス応答調節
# 1.1 現在のインパルス応答の長さより大きいもののうち最小の2の累乗を計算
N = 2**nextpow2(impulse.length).to_i

puts "frame length"
puts N

# 1.2 インパルス応答の長さを調節
new_impulse = impulse + zeros(N - impulse.length)

# 1.3 長さを調節した新しいインパルス応答を作成
new_impulse_n2 = zeros(N) + new_impulse

# 1.4 new_impulseの値域を16bit-signed intから-1 ~ 1へ変換
new_impulse_n2 = new_impulse_n2.map { |i| i / SIGNED_SHORT_MAX.to_f }

# 2 入力波形調節
# 2.1 入力波形をフレームごとに区切る
frame_num = ceil((input.length + N) / N.to_f).to_i
puts "# of frames"
puts frame_num

new_sig_length = N * frame_num

# 2.2 さらにoverlap-save法の為に入力波形の長さを調節する
new_signal = zeros(N) + input + zeros(new_sig_length - input.length - N)

# 2.3 インパルス応答と同じくこちらも値域を-1 ~ 1へと変換する
new_signal = new_signal.map { |i| i / SIGNED_SHORT_MAX.to_f }

# 畳み込み
# 3.1 新入力波形の前半部分から2Nだけ取り出し順番にインパルス応答との畳み込みを行う
# あらかじめインパルス応答をfftしておく
impulse_fft = fft(new_impulse_n2)
puts 'Impulse response FFT done.'

r = (0...frame_num - 1).map{ |i|
  puts '----------------------------'
  puts "------- 0#{i + 1} th convolution -------"
  puts '----------------------------'

  # 3.2 2フレーム分切り出し
  start_point = N * i
  end_point = N * (i + 2)
  part_fft = fft(new_signal[start_point...end_point])

  puts "start: #{start_point}"
  puts "end: #{end_point}"
  puts part_fft.length

  # 3.3 2フレーム分のインパルス応答と新入力波形を周波数領域で畳み込み
  convolution = part_fft.zip(impulse_fft).map { |f, s|
    #puts "f: #{f}"
    #puts "s: #{s}"
    #puts "f*s: #{f * s}"
    f * s
  }

  # 3.4 周波数領域畳み込み結果を逆高速フーリエ変換により時間領域へ変換
  res = fft(convolution, -1).map { |c|
    c / (2 * N)
  }.map(&:real)

  # 3.5 前半Nフレームを直線上畳み込み結果として保持し、後半部分を円状畳み込み結果として無視
  # 結果の後半のみを出力として保持、その際、虚数→実数と小数→整数への変換を行う
  res[0...N]
}.flatten

#p r[0...input.length]

new_wavs = r[0...input.length].map { |i| i * SIGNED_SHORT_MAX }.map(&:to_i)

data_chunk.data = new_wavs.pack(bit_per_sample(format))
open('output.wav', 'w') do |out|
  WavFile.write(out, format, [data_chunk])
end




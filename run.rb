require_relative 'src/convolution_reverb'

input = read(ARGV[0])
impulse = read(ARGV[1])

s = Time.now
res = convolution_reverb(transform(input), transform(impulse))
e = Time.now

puts "execution time = #{e - s}"

output(ARGV[0], 'output.wav', normalize(res))

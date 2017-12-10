require_relative 'src/convolution_reverb'

input = read(ARGV[0])
impulse = read(ARGV[1])

res = convolution_reverb(transform(input), transform(impulse))

output(ARGV[0], 'output.wav', normalize(res))
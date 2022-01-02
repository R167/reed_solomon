# frozen_string_literal: true

require "reed_solomon"
require "benchmark/ips"

t = Time.now
lut = ReedSolomon::GF.new
puts Time.now - t
no_lut = ReedSolomon::GF.new(lut: false)

iter = 0

Benchmark.ips do |x|
  x.report("lut") do |times|
    i = 0
    while i < times
      v1 = iter & 0xFF
      v2 = (iter >> 8)
      lut.mul(v1, v2)
      i += 1
      iter = (iter + 1) & 0xFFFF
    end
  end

  x.report("no lut") do |times|
    i = 0
    while i < times
      v1 = iter & 0xFF
      v2 = (iter >> 8)
      no_lut.mul(v1, v2)
      i += 1
      iter = (iter + 1) & 0xFFFF
    end
  end

  x.compare!
end

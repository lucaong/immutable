require "benchmark"
require "../src/immutable/vector"

Benchmark.bm do |bm|
  bm.report("push") do
    vector = Immutable::Vector(Int32).new
    1057.times do |i|
      vector = vector.push(i)
    end
  end
end

Benchmark.ips do |b|
  a = [] of Int32
  a1 = (0..50).to_a
  a2 = (50..100).to_a
  v1 = Immutable::Vector.new(a1)
  v2 = Immutable::Vector.new(a2)

  banner "Vector concatenation:"

  b.report("Array#concat") do
    a1 = (0..50).to_a
    a2 = (50..100).to_a
    a = [0]
    100.times { |_i| a = a1.concat(a2) }
  end

  b.report("Array#+") do
    100.times { |_i| a = a1 + a2 }
  end

  b.report("Vector#+") do
    v1 = Immutable::Vector.new(a1)
    v2 = Immutable::Vector.new(a2)
    v = Immutable::Vector(Int32).new
    100.times { |_i| v = v1 + v2 }
  end
end

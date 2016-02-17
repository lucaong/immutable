Benchmark.ips do |b|
  banner "Vector append:"

  b.report("Array#push") do
    a = [] of Int32
    100.times { |i| a.push(i) }
  end

  b.report("Array#+") do
    a = [] of Int32
    100.times { |i| a = a + [i] }
  end

  b.report("Vector#push") do
    v = Immutable::Vector(Int32).new
    100.times { |i| v.push(i) }
  end

  b.report("Vector#push with Transient") do
    v = Immutable::Vector(Int32).new
    v.transient do |v|
      100.times { |i| v.push(i) }
    end
  end
end

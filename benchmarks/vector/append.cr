Benchmark.ips do |b|
  banner "Vector append:"

  b.report("Array#push") do
    a = [] of Int32
    100.times { |i| a.push(i) }
  end

  b.report("Array#push with dup") do
    a = [] of Int32
    100.times { |i| a = a.dup.push(i) }
  end

  b.report("Vector#push") do
    v = Immutable::Vector(Int32).new
    100.times { |i| v.push(i) }
  end

  b.report("Vector#push with Transient") do
    v = Immutable::Vector(Int32).new
    v.transient do |t|
      100.times { |i| t.push(i) }
    end
  end
end

Benchmark.ips do |b|
  a = (0...100).to_a
  v = Immutable.vector(a)

  banner "Vector update:"

  b.report("Array#[]=") do
    100.times { |i| a[i] = 0 }
  end

  b.report("Vector#set") do
    100.times { |i| v = v.set(i, 0) }
  end

  b.report("Vector#set with Transient") do
    v.transient do |v|
      100.times { |i| v = v.set(i, 0) }
    end
  end
end

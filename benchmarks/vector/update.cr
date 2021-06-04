Benchmark.ips do |b|
  a = (0...100).to_a
  v = Immutable.vector(a)

  banner "Vector update:"

  b.report("Array#[]=") do
    100.times { |i| a[i] = 0 }
  end

  b.report("Array#[]= with dup") do
    100.times { |i| a = a.dup; a[i] = 0 }
  end

  b.report("Vector#set") do
    100.times { |i| v = v.set(i, 0) }
  end

  b.report("Vector#set with Transient") do
    v.transient do |t|
      100.times { |i| t = t.set(i, 0) }
    end
  end
end

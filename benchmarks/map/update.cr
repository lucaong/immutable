Benchmark.ips do |b|
  h = {} of Int32 => Int32
  k = h.dup
  m = Immutable.map(h)

  banner "Map update:"

  b.report("Hash#[]=") do
    100.times { |i| h[i] = 0 }
  end

  b.report("Hash#[]= with dup") do
    100.times { |i| k = k.dup; k[i] = 0 }
  end

  b.report("Map#set") do
    100.times { |i| m = m.set(i, 0) }
  end

  b.report("Map#set with Transient") do
    m.transient do |t|
      100.times { |i| t = t.set(i, 0) }
    end
  end
end

Benchmark.ips do |b|
  h = {} of Int32 => Int32
  m = Immutable.map(h)

  banner "Map update:"

  b.report("Hash#[]=") do
    100.times { |i| h[i] = 0 }
  end

  b.report("Map#set") do
    100.times { |i| m = m.set(i, 0) }
  end

  b.report("Map#set with Transient") do
    m.transient do |m|
      100.times { |i| m = m.set(i, 0) }
    end
  end
end

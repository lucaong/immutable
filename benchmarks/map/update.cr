Benchmark.ips do |b|
  h = (0...100).map { |i| {i, i * 2} }.to_h
  m = Immutable.map(h)

  banner "Map update:"

  b.report("Hash#[]=") do
    100.times { |i| h[i] = 0 }
  end

  b.report("Map#set") do
    100.times { |i| m.set(i, 0) }
  end

  b.report("Vector#set with Transient") do
    m.transient do |m|
      100.times { |i| m.set(i, 0) }
    end
  end
end



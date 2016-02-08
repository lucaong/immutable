Benchmark.ips do |b|
  h = (0...100).map { |i| {i, i * 2} }.to_h
  m = Immutable.map(h)
  o = { 1 => 0, 101 => 0, 150 => 0 }

  banner "Map merge:"

  b.report("Hash#merge") do
    h.merge(o)
  end

  b.report("Map#merge") do
    m.merge(o)
  end
end

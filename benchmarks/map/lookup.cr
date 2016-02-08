Benchmark.ips do |b|
  h = (0...100).map { |i| {i, i * 2} }.to_h
  m = Immutable.map(h)

  banner "Map lookup:"

  b.report("Hash#fetch") do
    100.times { |i| h.fetch(i, 0) }
  end

  b.report("Map#fetch") do
    100.times { |i| m.fetch(i, 0) }
  end
end

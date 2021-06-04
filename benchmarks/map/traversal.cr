Benchmark.ips do |b|
  h = (0...100).map { |i| {i, i * 2} }.to_h
  m = Immutable.map(h)

  banner "Map traversal:"

  b.report("Hash#each") do
    h.each { |_k, _v| nil }
  end

  b.report("Map#each") do
    m.each { |_k, _v| nil }
  end
end

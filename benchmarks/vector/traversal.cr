Benchmark.ips do |b|
  a = (0...100).to_a
  v = Immutable.vector(a)

  banner "Vector traversal:"

  b.report("Array#each") do
    a.each { |el| el }
  end

  b.report("Vector#each") do
    v.each { |el| el }
  end
end

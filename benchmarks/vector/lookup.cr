Benchmark.ips do |b|
  a = (0...100).to_a
  v = Immutable.vector(a)

  banner "Vector lookup:"

  b.report("Array#[]") do
    100.times { |i| a[i] }
  end

  b.report("Vector#[]") do
    100.times { |i| v[i] }
  end
end


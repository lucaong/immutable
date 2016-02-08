Benchmark.ips do |b|
  banner "Vector creation:"

  b.report("Array creation") do
    100.times { a = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] }
  end

  b.report("Vector creation") do
    100.times { v = Immutable.vector([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]) }
  end

  b.report("Vector creation with .of") do
    100.times { v = Immutable::Vector.of(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10) }
  end
end

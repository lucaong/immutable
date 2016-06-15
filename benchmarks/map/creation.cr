Benchmark.ips do |b|
  banner "Map creation:"

  b.report("Hash creation") do
    100.times { h = {:foo => 1, :bar => 2, :baz => 3, :qux => 4, :quux => 5} }
  end

  b.report("Map creation") do
    100.times do
      m = Immutable.map({:foo => 1, :bar => 2, :baz => 3, :qux => 4, :quux => 5})
    end
  end
end

Benchmark.ips do |b|
  banner "Map creation:"

  b.report("Hash creation") do
    x = {:foo => 1}

    100.times {
      x = {:foo => 1, :bar => 2, :baz => 3, :qux => 4, :quux => 5}
    }
  end

  b.report("Map creation") do
    x = {:foo => 1}

    100.times do
      x = Immutable.map({:foo => 1, :bar => 2, :baz => 3, :qux => 4, :quux => 5})
    end
  end
end

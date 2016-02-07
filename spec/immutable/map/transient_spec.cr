require "../../spec_helper"

describe Immutable::Map::Transient do
  describe "#set" do
    it "sets a key-value pair" do
      t = Immutable::Map::Transient(Symbol, Int32).new
      t.set(:foo, 1)[:foo].should eq(1)
    end
  end

  describe "#delete" do
    it "deletes a key-value pair" do
      t = Immutable::Map::Transient(Symbol, Int32).new({ foo: 1, bar: 2 })
      t.delete(:foo).fetch(:foo, nil).should eq(nil)
    end
  end

  describe "#merge" do
    it "merges key-value pairs" do
      t = Immutable::Map::Transient(Symbol, Int32).new({ foo: 1, bar: 2 })
      t.merge({ baz: 3 })[:baz].should eq(3)
    end
  end

  describe "#persist!" do
    it "returns a persistent immutable vector unaffected by further changes" do
      tr = Immutable::Map::Transient(Symbol, Int32).new({ foo: 1, bar: 2 })
      m = tr.persist!
      m.should be_a(Immutable::Map(Symbol, Int32))
      m.should_not be_a(Immutable::Map::Transient(Symbol, Int32))
      tr = tr.delete(:foo).set(:baz, 3).merge({ qux: 4, quux: 5 })
      tr.to_h.should eq({ bar: 2, baz: 3, qux: 4, quux: 5 })
      m.to_h.should eq({ foo: 1, bar: 2 })
    end
  end
end

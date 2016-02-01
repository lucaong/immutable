require "../../spec_helper"

describe Immutable::Hash::Trie do
  empty_trie = Immutable::Hash::Trie(Symbol, Int32).empty
  trie = empty_trie.set(:foo, 42)

  describe "#set" do
    it "set and get the value at the key" do
      t = empty_trie.set(:foo, 1).set(:bar, 2).set(:foo, 3)
      t.size.should eq(2)
      t.get(:foo).should eq(3)
      t.get(:bar).should eq(2)
    end

    it "does not modify the original" do
      t = trie.set(:foo, 0).set(:x, 5)
      trie.get(:foo).should eq(42)
      expect_raises(KeyError) { trie.get(:x) }
    end
  end

  describe "#get" do
    it "gets the value at key" do
      trie.get(:foo).should eq(42)
    end

    it "raises KeyError if the key is not associated with any value" do
      expect_raises(KeyError) { trie.get(:baz) }
    end
  end

  describe "#fetch" do
    it "gets the value at key, if not set it evaluate the block" do
      trie.fetch(:foo) { |key| key }.should eq(42)
      trie.fetch(:baz) { |key| key }.should eq(:baz)
    end
  end

  describe "#has_key?" do
    it "returns true if the given key is associated to a value, else false" do
      trie.has_key?(:foo).should eq(true)
      trie.has_key?(:baz).should eq(false)
    end
  end

  describe "#each" do
    it "iterates through values" do
      t = empty_trie.set(:foo, 1).set(:bar, 2).set(:baz, 3)
      keyvals = [] of { Symbol, Int32 }
      t.each do |k, v|
        keyvals << { k, v }
      end
      keyvals.sort.should eq([{:bar, 2}, {:baz, 3}, {:foo, 1}])
    end
  end
end

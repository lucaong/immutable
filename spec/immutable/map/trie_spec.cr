require "../../spec_helper"

describe Immutable::Map::Trie do
  empty_trie = Immutable::Map::Trie(Symbol, Int32).empty
  trie = empty_trie.set(:foo, 42)

  describe "#set" do
    it "sets the value at the key" do
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

  describe "#delete" do
    it "deletes the value at the key" do
      t = empty_trie.set(:foo, 1).set(:bar, 2)
      t2 = t.delete(:bar)
      t2.size.should eq(1)
      t.get(:foo).should eq(1)
      expect_raises(KeyError) { t2.get(:bar) }
    end

    it "does not modify the original" do
      t = trie.delete(:foo)
      trie.get(:foo).should eq(42)
      expect_raises(KeyError) { trie.get(:x) }
    end

    it "raises KeyError if the key does not exists" do
      expect_raises(KeyError) { trie.delete(:xxx) }
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
    it "iterates through tuples of key and value" do
      t = empty_trie.set(:foo, 1).set(:bar, 2).set(:baz, 3)
      keyvals = [] of { Symbol, Int32 }
      t.each do |kv|
        keyvals << kv
      end
      keyvals.sort.should eq([{:bar, 2}, {:baz, 3}, {:foo, 1}])
    end

    it "returns an iterator if called without block" do
      t = empty_trie.set(:foo, 1).set(:bar, 2).set(:baz, 3)
      t.each.to_a.should eq(t.to_a)
    end
  end

  describe "in-place modifications" do
    describe "when modified by the owner" do
      it "#set! and #delete! modify in place" do
        t = Immutable::Map::Trie(Symbol, Int32).empty(42_u64)
        t.set!(:foo, 0, 42_u64)
        t.set!(:bar, 1, 42_u64)
        t.get(:foo).should eq(0)
        t.get(:bar).should eq(1)
        t.delete!(:foo, 42_u64)
        t.has_key?(:foo).should eq(false)
      end
    end

    describe "when modified by an object that is not the owner" do
      it "#set! and #delete! return a modified copy" do
        t = Immutable::Map::Trie(Symbol, Int32).empty(42_u64)
        x = t.set!(:foo, 0, 0_u64)
        t.has_key?(:foo).should eq(false)
        x.get(:foo).should eq(0)
        t.set!(:foo, 0, 42_u64)
        x = t.delete!(:foo, 0_u64)
        t.get(:foo).should eq(0)
        t.has_key?(:foo).should eq(true)
        x.has_key?(:foo).should eq(false)
      end
    end
  end
end

require "../../spec_helper"

describe Immutable::Vector::Trie do
  empty_trie = Immutable::Vector::Trie(Int32).empty
  trie       = Immutable::Vector::Trie.from((0..49).to_a)

  describe "#size" do
    it "returns the number of elements in the trie" do
      empty_trie.size.should eq(0)
      trie.size.should eq(50)
    end
  end

  describe "#get" do
    it "gets the element with the given index" do
      trie.get(0).should eq(0)
      trie.get(3).should eq(3)
      trie.get(49).should eq(49)
    end

    it "raises IndexError when accessing out of range" do
      expect_raises(IndexError) do
        trie.get(trie.size)
      end

      expect_raises(IndexError) do
        trie.get(-1)
      end
    end
  end

  describe "#update" do
    it "returns a modified copy of the trie" do
      t = trie.update(0, -1)
      t.get(0).should eq(-1)
    end

    it "does not modify the original" do
      trie.update(0, -1)
      trie.get(0).should eq(0)
    end

    it "raises IndexError when updating elements out of range" do
      expect_raises(IndexError) do
        trie.update(trie.size, -1)
      end

      expect_raises(IndexError) do
        trie.update(-1, -1)
      end
    end
  end

  describe "#push_leaf" do
    it "return a copy of the trie with the given values appended" do
      original = Immutable::Vector::Trie(Int32).empty
      t = original.push_leaf((0..31).to_a)
      t.get(0).should eq(0)
      t.get(31).should eq(31)
      t.size.should eq(32)
      original.size.should eq(0)
    end

    it "works across multiple levels" do
      t = Immutable::Vector::Trie(Int32).empty
      (0..1099).each_slice(Immutable::Vector::Trie::BLOCK_SIZE) do |leaf|
        t = t.push_leaf(leaf)
      end
      t.to_a.should eq((0..1099).to_a)
    end

    it "raises if the tree is partial" do
      expect_raises(ArgumentError) do
        trie.push_leaf((0..31).to_a)
      end
    end

    it "raises if the leaf has the wrong size" do
      expect_raises(ArgumentError) do
        empty_trie.push_leaf((0..35).to_a)
      end
    end
  end

  describe "#pop_leaf" do
    it "return a copy of the trie with the given values appended" do
      t = empty_trie
      block_size = Immutable::Vector::Trie::BLOCK_SIZE
      (0...block_size*5).each_slice(block_size) do |leaf|
        t = t.push_leaf(leaf)
      end
      t.pop_leaf.to_a.should eq(t.to_a[0...-1*block_size])
    end

    it "works across multiple levels" do
      t = empty_trie
      block_size = Immutable::Vector::Trie::BLOCK_SIZE
      (0...block_size*(block_size + 1)).each_slice(block_size) do |leaf|
        t = t.push_leaf(leaf)
      end
      (block_size + 1).times do
        t = t.pop_leaf
      end
      t.size.should eq(0)
    end

    it "raises if the tree is partial" do
      expect_raises(ArgumentError) do
        trie.pop_leaf
      end
    end
  end

  describe "#each" do
    it "iterates through each element" do
      array = [] of Int32
      trie.each do |elem|
        array << elem
      end
      array.should eq((0...trie.size).to_a)
    end

    it "return an iterator if called with no arguments" do
      t = Immutable::Vector::Trie.from((0..100).to_a)
      iter = t.each
      iter.to_a.should eq(t.to_a)
    end
  end

  describe ".empty" do
    it "returns an empty trie" do
      t = Immutable::Vector::Trie(Int32).empty
      t.size.should eq(0)
      t.should be_a(Immutable::Vector::Trie(Int32))
    end
  end

  describe ".from" do
    it "returns a trie containing the given elements" do
      t = Immutable::Vector::Trie.from((0..999).to_a)
      t.size.should eq(1000)
      t.should be_a(Immutable::Vector::Trie(Int32))
      t.get(0).should eq(0)
      t.get(999).should eq(999)
    end
  end

  describe "in-place modifications" do
    describe "when modified by the owner" do
      it "#update! modifies in place" do
        t = Immutable::Vector::Trie.from((0..99).to_a, 42_u64)
        t.update!(50, 0, 42_u64)
        t.update!(99, 0, 42_u64)
        t.get(50).should eq(0)
        t.get(99).should eq(0)
      end

      it "#push_leaf! and #pop_leaf! modify in place" do
        block_size = Immutable::Vector::Trie::BLOCK_SIZE
        t = Immutable::Vector::Trie.new([] of Int32, 42_u64)
        not_in_place = 0
        # push_leaf!
        (block_size.to_i + 1).times do |i|
          x = t.push_leaf!((i*block_size...i * block_size + block_size).to_a, 42_u64)
          not_in_place += 1 unless x == t
          t = x
        end
        not_in_place.should eq(3)
        t.size.should eq(block_size * (block_size + 1))
        # pop_leaf!
        not_in_place = 0
        block_size.times do |i|
          x = t.pop_leaf!(42_u64)
          not_in_place += 1 unless x == t
          t = x
        end
        not_in_place.should eq(2)
        t.size.should eq(block_size)
      end
    end

    describe "when modified by an object who's not the owner" do
      it "#update! returns a modified copy" do
        t = Immutable::Vector::Trie.from((0..99).to_a, 42_u64)
        t.update!(50, 0, 2_u64)
        t.update!(99, 0, 2_u64)
        t.get(50).should eq(50)
        t.get(99).should eq(99)
      end

      it "#push_leaf! and #pop_leaf! return a modified copy" do
        block_size = Immutable::Vector::Trie::BLOCK_SIZE
        t = Immutable::Vector::Trie.new([] of Int32, 42_u64)
        3.times do |i|
          t = t.push_leaf!((0...block_size).to_a, 42_u64)
        end
        x = t.push_leaf!((0...block_size).to_a, 1_u64)
        x.should_not eq(t)
        x = t.pop_leaf!(1_u64)
        x.should_not eq(t)
      end
    end
  end
end

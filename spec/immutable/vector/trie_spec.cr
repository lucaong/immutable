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

  describe "#push" do
    it "return a copy of the trie with the given value appended" do
      t = empty_trie.push(1)
      t.get(0).should eq(1)
      t.size.should eq(1)
    end

    it "does not modify the original" do
      empty_trie.push(1)
      empty_trie.size.should eq(0)
    end

    it "works properly across leaves and levels" do
      t = (0..99).reduce(empty_trie) do |t, elem|
        t.push(elem)
      end
      t.size.should eq(100)
      t.get(0).should eq(0)
      t.get(99).should eq(99)
    end
  end

  describe "#pop" do
    it "return a copy of the trie with the last value removed" do
      t = trie.pop
      t.last.should eq(48)
      t.size.should eq(trie.size - 1)
    end

    it "raises IndexError if trie is empty" do
      expect_raises(IndexError) do
        empty_trie.pop
      end
    end

    it "does not modify the original" do
      original_size = trie.size
      trie.pop
      trie.size.should eq(original_size)
    end

    it "works properly across leaves and levels" do
      t = (0..1099).reduce(empty_trie) { |t, i| t.push(i) }
      t.size.times do
        t = t.pop
      end
      t.size.should eq(0)
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
end

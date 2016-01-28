require "../spec_helper"

describe Immutable do
  describe Immutable::Vector do
    empty_vector = Immutable::Vector(Int32).new
    vector = (0..999).reduce(empty_vector) do |vec, i|
      vec.push(i)
    end

    describe ".new" do
      describe "without arguments" do
        it "returns an empty Vector" do
          Immutable::Vector(Int32).new.size.should eq(0)
        end
      end

      describe "with an array of elements" do
        it "returns a Vector containing the elements" do
          vec = Immutable::Vector.new((0..99).to_a)
          vec.size.should eq(100)
          vec.first.should eq(0)
          vec.last.should eq(99)
        end
      end
    end

    describe "#size" do
      it "returns the correct size" do
        empty_vector.size.should eq(0)
        vector.size.should eq(1000)
      end
    end

    describe "#push" do
      it "returns a modified copy without changing the original" do
        v = empty_vector.push(5)
        v.size.should eq(1)
        empty_vector.size.should eq(0)
      end
    end

    describe "#at" do
      it "returns the element at the given index" do
        vector.at(10).should eq(10)
      end

      it "works with negative indexes" do
        vector.at(-1).should eq(vector.at(vector.size - 1))
        vector.at(-1 * vector.size).should eq(vector.at(0))
      end

      it "raises IndexError if accessing indexes out of range" do
        expect_raises(IndexError) { vector.at(vector.size) }
        expect_raises(IndexError) { vector.at(-1 * (vector.size + 1)) }
      end

      it "evaluates block if given and accessing indexes out of range" do
        vector.at(vector.size) { 42 }.should eq(42)
        vector.at(-1 * (vector.size + 1)) { 46 }.should eq(46)
      end
    end

    describe "#[]" do
      it "returns the element at the given index" do
        vector[10].should eq(10)
      end

      it "works with negative indexes" do
        vector[-1].should eq(vector[vector.size - 1])
        vector[-1 * vector.size].should eq(vector[0])
      end

      it "raises IndexError if accessing indexes out of range" do
        expect_raises(IndexError) { vector[vector.size] }
        expect_raises(IndexError) { vector[-1 * (vector.size + 1)] }
      end
    end

    describe "#each" do
      it "iterates through each element" do
        array = [] of Int32
        vector.each do |elem|
          array << elem
        end
        array.should eq((0...vector.size).to_a)
      end

      it "returns self" do
        v = vector.each do |elem|; end
        v.should be(vector)
      end

      it "returns an iterator if called with no arguments" do
        iter = vector.each
        iter.should be_a(Immutable::Vector::ItemIterator(Int32))
        iter.to_a.should eq((0...vector.size).to_a)
      end
    end
  end
end

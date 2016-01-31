require "../spec_helper"
require "json"

describe Immutable do
  describe Immutable::Vector do
    empty_vector = Immutable::Vector(Int32).new
    vector = Immutable::Vector.new((0..99).to_a)

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

    describe ".of" do
      it "returns a Vector of the arguments" do
        vec = Immutable::Vector.of(1, 2, 3)
        vec.size.should eq(3)
        vec.first.should eq(1)
        vec.last.should eq(3)
      end
    end

    describe "#size" do
      it "returns the correct size" do
        empty_vector.size.should eq(0)
        vector.size.should eq(100)
      end
    end

    describe "#push" do
      it "returns a modified copy without changing the original" do
        v = empty_vector.push(5)
        v.size.should eq(1)
        empty_vector.size.should eq(0)
      end

      it "work properly across leaves and levels" do
        v = empty_vector
        1100.times do |i|
          v = v.push(i)
        end
        v.size.should eq(1100)
        v.to_a.should eq((0..1099).to_a)
      end
    end

    describe "#pop" do
      it "returns a tuple of last element and vector but last element" do
        l, v = vector.pop
        v.to_a.should eq(vector.to_a[0...-1])
        l.should eq(vector.last)
      end

      it "work properly across leaves and levels" do
        v = Immutable::Vector.new((0..1099).to_a)
        v.size.times do
          _, v = v.pop
        end
        v.size.should eq(0)
      end

      it "raises IndexError if called on empty vector" do
        expect_raises(IndexError) do
          empty_vector.pop
        end
      end
    end

    describe "#pop?" do
      it "behaves like `pop` if called on non-empty vector" do
        vector.pop?.should eq(vector.pop)
      end

      it "returns { nil, self } if called on empty vector" do
        l, v = empty_vector.pop?
        l.should eq(nil)
        v.should eq(empty_vector)
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

    describe "#[]?" do
      it "returns the element at the given index" do
        vector[10]?.should eq(10)
      end

      it "works with negative indexes" do
        vector[-1]?.should eq(vector[vector.size - 1])
        vector[-1 * vector.size]?.should eq(vector[0])
      end

      it "returns nil if accessing indexes out of range" do
        vector[vector.size]?.should eq(nil)
        vector[-1 * (vector.size + 1)]?.should eq(nil)
      end
    end

    describe "#[]" do
      it "returns a copy with the value set at given index" do
        v = vector.set(10, -1)
        v[10].should eq(-1)
        vector[10].should eq(10)
      end

      it "works with negative indexes" do
        v = vector.set(-1, -1)
        v[-1].should eq(-1)
        vector[-1].should eq(vector[vector.size - 1])
        v = vector.set(-1 * vector.size, -1)
        v[0].should eq(-1)
        vector[0].should eq(0)
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
        v.should eq(vector)
      end

      it "returns an iterator if called with no arguments" do
        iter = vector.each
        iter.should be_a(Immutable::Vector::ItemIterator(Int32))
        iter.to_a.should eq((0...vector.size).to_a)
      end
    end

    describe "#<=>" do
      it "returns 0 if vectors are equal" do
        v1 = Immutable::Vector.new([1, 2, 3])
        v2 = Immutable::Vector.new([1, 2, 3])
        (v1 <=> v2).should eq(0)
      end

      it "returns -1 if the first mismatched element is smaller than the other" do
        v1 = Immutable::Vector.new([4, 1, 5])
        v2 = Immutable::Vector.new([4, 2, 3, 7])
        (v1 <=> v2).should eq(-1)
      end

      it "returns 1 if the first mismatched element bigger than the other" do
        v1 = Immutable::Vector.new([4, 3, 2])
        v2 = Immutable::Vector.new([4, 2, 3, 7])
        (v1 <=> v2).should eq(1)
      end

      describe "when equal up to the shorter Vector" do
        it "returns -1 if shorter than the other" do
          v1 = Immutable::Vector.new([4, 2, 3])
          v2 = Immutable::Vector.new([4, 2, 3, 7])
          (v1 <=> v2).should eq(-1)
        end

        it "returns 1 if longer than the other" do
          v1 = Immutable::Vector.new([4, 2, 3, 7])
          v2 = Immutable::Vector.new([4, 2, 3])
          (v1 <=> v2).should eq(1)
        end
      end
    end

    describe "#==" do
      it "returns false for different types" do
        (vector == 1).should eq(false)
      end

      it "returns true for equal vectors" do
        v1 = Immutable::Vector.new([4, 2, 3])
        v2 = Immutable::Vector.new([4, 2, 3])
        (v1 == v2).should eq(true)
      end
    end

    describe "#+"do
      it "concatenates vectors" do
        v1 = Immutable::Vector.new((0..99).to_a)
        v2 = Immutable::Vector.new((100..149).to_a)
        v3 = v1 + v2
        v3.size.should eq(150)
        v3.to_a.should eq(v1.to_a + v2.to_a)
      end
    end

    describe "#-"do
      it "subtract the given vector from self" do
        v1 = Immutable::Vector.new([1, 2, 3, 4])
        v2 = Immutable::Vector.new([3, 2, 5])
        v3 = v1 - v2
        v3.to_a.should eq(v1.to_a - v2.to_a)
      end
    end

    describe "#&" do
      it "returns the intersection between vectors" do
        v1 = Immutable::Vector.new([1, 2, 3, 2, 4, 0])
        v2 = Immutable::Vector.new([0, 2, 1])
        (v1 & v2).should eq(Immutable::Vector.of(1, 2, 0))
      end

      it "returns an empty vector if self or other is empty" do
        v1 = Immutable::Vector(Int32).new
        v2 = Immutable::Vector.new([0, 2, 1])
        (v1 & v2).should eq(Immutable::Vector(Int32).new)
        (v2 & v1).should eq(Immutable::Vector(Int32).new)
      end
    end

    describe "#|" do
      it "returns the union between vectors" do
        v1 = Immutable::Vector.new([1, 2, 3, 2, 4, 0])
        v2 = Immutable::Vector.new([0, 2, 0, 7, 1])
        (v1 | v2).should eq(Immutable::Vector.of(1, 2, 3, 4, 0, 7))
      end
    end

    describe "#uniq" do
      it "returns a vector of unique elements" do
        v = Immutable::Vector.new([1, 2, 3, 2, 4, 1, 0])
        v.uniq.should eq(Immutable::Vector.of(1, 2, 3, 4, 0))
      end
    end

    describe "#inspect and #to_s" do
      it "return a human-readable string representation" do
        vec = Immutable::Vector.of(1, 2, 3)
        vec.inspect.should eq("Vector [1, 2, 3]")
        vec.to_s.should eq("Vector [1, 2, 3]")
      end
    end

    describe "hash" do
      it "returns the same value for identical vectors" do
        v1 = Immutable::Vector.of(1, 2, 3)
        v2 = Immutable::Vector.of(1, 2, 3)
        v1.hash.should eq(v2.hash)
      end

      it "returns a different value for different vectors" do
        v1 = Immutable::Vector.of(1, 2, 3)
        v2 = Immutable::Vector.of(3, 2, 1)
        v1.hash.should_not eq(v2.hash)
      end
    end

    describe "to_json" do
      it "serializes to JSON in the same way as array" do
        empty_vector.to_json.should eq("[]")
        vector.to_json.should eq(vector.to_a.to_json)
      end
    end
  end
end

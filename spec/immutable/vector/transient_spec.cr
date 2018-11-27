require "../../spec_helper"

describe Immutable::Vector::Transient do
  empty_transient = Immutable::Vector::Transient(Int32).new

  describe "#push" do
    it "pushes elements into the transient" do
      tr = Immutable::Vector::Transient(Int32).new
      100.times { |i| tr = tr.push(i) }
      tr.size.should eq(100)
    end
  end

  describe "#set" do
    it "sets elements of the transient" do
      tr = Immutable::Vector::Transient.new([1, 2, 3])
      tr.set(1, 0)[1].should eq(0)
    end
  end

  describe "#pop" do
    it "sets elements of the transient" do
      tr = Immutable::Vector::Transient.new([1, 2, 3])
      elem, t = tr.pop
      elem.should eq(3)
      t.size.should eq(2)
    end
  end

  describe "#persist!" do
    it "returns a persistent immutable vector and invalidates the transient" do
      tr = Immutable::Vector::Transient(Int32).new
      100.times { |i| tr = tr.push(i) }
      v = tr.persist!
      v.should be_a(Immutable::Vector(Int32))
      v.should_not be_a(Immutable::Vector::Transient(Int32))
      expect_raises Immutable::Vector::Transient::Invalid do
        tr.pop
      end
      expect_raises Immutable::Vector::Transient::Invalid do
        tr.push(100)
      end
      expect_raises Immutable::Vector::Transient::Invalid do
        tr.set(50, 0)
      end
      v.push(100).set(50, 0).set(98, 0)
      tr.size.should eq(100)
      tr.last.should eq(99)
      v.size.should eq(100)
      v[50].should eq(50)
      v.last.should eq(99)
    end
  end
end

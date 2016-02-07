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
    it "returns a persistent immutable vector unaffected by further changes" do
      tr = Immutable::Vector::Transient(Int32).new
      100.times { |i| tr = tr.push(i) }
      v = tr.persist!
      v.should be_a(Immutable::Vector(Int32))
      _, tr = tr.pop
      _, tr = tr.pop
      tr = tr.push(100).set(50, 0).set(98, 0)
      tr.size.should eq(99)
      tr.last.should eq(0)
      v.size.should eq(100)
      v[50].should eq(50)
      v.last.should eq(99)
    end
  end
end

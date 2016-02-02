require "./spec_helper"

describe Immutable do
  it "has a version number" do
    Immutable::VERSION.should_not be(nil)
  end

  describe ".vector" do
    it "creates a vector of the given elements" do
      Immutable.vector([1, 2, 3]).should eq(Immutable::Vector.new([1, 2, 3]))
    end
  end

  describe ".map" do
    it "creates a map of the given key-values" do
      Immutable.map({ foo: "bar" }).should eq(Immutable::Map.new({ foo: "bar" }))
    end
  end
end

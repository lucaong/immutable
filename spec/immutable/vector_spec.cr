require "../spec_helper"

describe Immutable do
  describe Immutable::Vector do
    empty_vector = Immutable::Vector(Int32).new
    vector = (0..999).reduce(empty_vector) do |vec, i|
      vec.push(i)
    end

    describe "#size" do
      it "returns the correct size" do
        empty_vector.size.should eq(0)
        vector.size.should eq(1000)
      end
    end

    describe "#push" do
    end
  end
end

require "./spec_helper"

describe Immutable do
  it "has a version number" do
    Immutable::VERSION.should_not be(nil)
  end
end

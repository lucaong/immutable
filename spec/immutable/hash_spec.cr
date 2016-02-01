require "../spec_helper"
require "json"

describe Immutable do
  describe Immutable::Hash do
    empty_hash = Immutable::Hash(String, Int32).new
    hash       = Immutable::Hash.new({ "foo" => 1, "bar" => 2, "baz" => 3 })

    describe ".new" do
      it "creates an empty hash" do
        h = Immutable::Hash(String, Int32).new
        h.is_a?(Immutable::Hash(String, Int32)).should eq(true)
        h.size.should eq(0)
      end

      it "with a block, it creates a hash with default" do
        h = Immutable::Hash(String, Int32).new { |k| 42 }
        h["xxx"].should eq(42)
      end

      it "with a hash, it creates and initialize an immutable hash" do
        h = Immutable::Hash.new({ foo: 123 })
        h[:foo].should eq(123)
      end

      it "with a hash and a block, it creates and initialize a hash with default" do
        h = Immutable::Hash.new({ foo: 123 }) { |k| 42 }
        h[:foo].should eq(123)
        h[:xxx].should eq(42)
      end
    end

    describe "#fetch" do
      describe "with one argument and no block" do
        it "returns value associated with key if it exists, else raise KeyError" do
          hash.fetch("bar").should eq(2)
          expect_raises(KeyError) { hash.fetch("xxx") }
        end
      end

      describe "with one argument and a block" do
        it "returns value associated with key if it exists, else eval block" do
          hash.fetch("bar") { |k| k }.should eq(2)
          hash.fetch("xxx") { |k| k }.should eq("xxx")
        end
      end

      describe "with two arguments" do
        it "returns value associated with key if it exists, else the default" do
          hash.fetch("bar", 123).should eq(2)
          hash.fetch("xxx", 123).should eq(123)
        end
      end
    end

    describe "#[]" do
      it "returns value associated with key if it exists, else raise KeyError" do
        hash["bar"].should eq(2)
        expect_raises(KeyError) { hash["xxx"] }
      end
    end

    describe "#[]?" do
      it "returns value associated with key if it exists, else nil" do
        hash["bar"].should eq(2)
        hash["xxx"]?.should eq(nil)
      end
    end
  end
end

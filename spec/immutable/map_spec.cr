require "../spec_helper"
require "json"

describe Immutable do
  describe Immutable::Map do
    empty_map = Immutable::Map(String, Int32).new
    map       = Immutable::Map.new({ "foo" => 1, "bar" => 2, "baz" => 3 })

    describe ".new" do
      it "creates an empty map" do
        m = Immutable::Map(String, Int32).new
        m.is_a?(Immutable::Map(String, Int32)).should eq(true)
        m.size.should eq(0)
      end

      it "with a block, it creates a map with default" do
        m = Immutable::Map(String, Int32).new { |k| 42 }
        m["xxx"].should eq(42)
      end

      it "with a hash, it creates and initialize an immutable map" do
        m = Immutable::Map.new({ foo: 123 })
        m[:foo].should eq(123)
      end

      it "with a hash and a block, it creates and initialize a map with default" do
        m = Immutable::Map.new({ foo: 123 }) { |k| 42 }
        m[:foo].should eq(123)
        m[:xxx].should eq(42)
      end
    end

    describe "#fetch" do
      describe "with one argument and no block" do
        it "returns value associated with key if it exists, else raise KeyError" do
          map.fetch("bar").should eq(2)
          expect_raises(KeyError) { map.fetch("xxx") }
        end
      end

      describe "with one argument and a block" do
        it "returns value associated with key if it exists, else eval block" do
          map.fetch("bar") { |k| k }.should eq(2)
          map.fetch("xxx") { |k| k }.should eq("xxx")
        end
      end

      describe "with two arguments" do
        it "returns value associated with key if it exists, else the default" do
          map.fetch("bar", 123).should eq(2)
          map.fetch("xxx", 123).should eq(123)
        end
      end
    end

    describe "#[]" do
      it "returns value associated with key if it exists, else raise KeyError" do
        map["bar"].should eq(2)
        expect_raises(KeyError) { map["xxx"] }
      end
    end

    describe "#[]?" do
      it "returns value associated with key if it exists, else nil" do
        map["bar"].should eq(2)
        map["xxx"]?.should eq(nil)
      end
    end
  end
end

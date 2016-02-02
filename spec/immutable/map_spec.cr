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

    describe "#set" do
      it "returns a modified copy with the given key-value association" do
        m = map.set("abc", 1234)
        m["abc"].should eq(1234)
        m = map.set("abc", 4321)
        m["abc"].should eq(4321)
        map["abc"]?.should eq(nil)
      end
    end

    describe "#delete" do
      it "returns a modified copy with the key-value association removed" do
        m = map.delete("foo")
        m["foo"]?.should eq(nil)
        map["foo"].should eq(1)
      end

      it "raises KeyError if the key does not exist" do
        expect_raises(KeyError) do
          map.delete("abc")
        end
      end
    end

    describe "#each" do
      it "calls the block for each entry in the map" do
        entries = [] of Tuple(String, Int32)
        map.each do |entry|
          entries << entry
        end
        entries.sort.should eq([{"bar", 2}, {"baz", 3}, {"foo", 1}])
      end

      it "returns an iterator if called with no block" do
        map.each.to_a.sort.should eq([{"bar", 2}, {"baz", 3}, {"foo", 1}])
      end
    end

    describe "#each_key" do
      it "calls the block for each key in the map" do
        keys = [] of String
        map.each_key do |key|
          keys << key
        end
        keys.sort.should eq(["bar", "baz", "foo"])
      end

      it "returns an iterator if called with no block" do
        map.each_key.to_a.sort.should eq(["bar", "baz", "foo"])
      end
    end

    describe "#each_value" do
      it "calls the block for each value in the map" do
        vals = [] of Int32
        map.each_value do |val|
          vals << val
        end
        vals.sort.should eq([1, 2, 3])
      end

      it "returns an iterator if called with no block" do
        map.each_value.to_a.sort.should eq([1, 2, 3])
      end
    end

    describe "#keys" do
      it "returs an array of all the keys" do
        map.keys.sort.should eq(["bar", "baz", "foo"])
      end
    end

    describe "#values" do
      it "returs an array of all the values" do
        map.values.sort.should eq([1, 2, 3])
      end
    end

    describe "#==" do
      it "returns false for different types" do
        (map == 1).should eq(false)
      end

      it "returns true for equal maps" do
        m1 = Immutable::Map.new({ foo: 123 })
        m2 = Immutable::Map.new({ foo: 123 })
        (m1 == m2).should eq(true)
      end
    end
  end
end

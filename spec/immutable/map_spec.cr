require "../spec_helper"
require "json"

describe Immutable do
  describe Immutable::Map do
    empty_map = Immutable::Map(String, Int32).new
    map = Immutable::Map.new({"foo" => 1, "bar" => 2, "baz" => 3})

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
        m = Immutable::Map.new({:foo => 123})
        m[:foo].should eq(123)
      end

      it "with a hash and a block, it creates and initialize a map with default" do
        m = Immutable::Map.new({:foo => 123}) { |k| 42 }
        m[:foo].should eq(123)
        m[:xxx].should eq(42)
      end

      it "with an enumerable, it creates and initialize an immutable map" do
        m = Immutable::Map.new([{:foo, 1}, {:bar, 2}])
        m[:bar].should eq(2)
      end
    end

    describe ".[]" do
      it "it creates and initialize an immutable map" do
        m = Immutable::Map[{:foo => 123, :bar => 321}]
        m[:foo].should eq(123)
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

    describe "#merge" do
      it "returns a copy merged with the given hash" do
        m = map.merge({"foo" => 100, "qux" => true})
        m.should eq(Immutable::Map.new({
          "foo" => 100,
          "bar" => 2,
          "baz" => 3,
          "qux" => true,
        }))
        map["foo"].should eq(1)
        map["qux"]?.should eq(nil)
      end

      it "returns a copy merged with the given map" do
        m = map.merge(Immutable::Map.new({"foo" => 100, "qux" => true}))
        m.should eq(Immutable::Map.new({
          "foo" => 100,
          "bar" => 2,
          "baz" => 3,
          "qux" => true,
        }))
        map["foo"].should eq(1)
        map["qux"]?.should eq(nil)
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
        m1 = Immutable::Map.new({:foo => 123})
        m2 = Immutable::Map.new({:foo => 123})
        (m1 == m2).should eq(true)
      end
    end

    describe "#inspect" do
      it "returns a string representation of the map" do
        m = Immutable::Map.new({:foo => 123, :bar => 321})
        m.inspect.should eq("Map {:foo => 123, :bar => 321}")
      end
    end

    describe "#to_a" do
      it "returns an array of entries" do
        m = Immutable::Map.new({:foo => 123, :bar => 321})
        m.to_a.should eq([{:foo, 123}, {:bar, 321}])
      end
    end

    describe "#to_h" do
      it "returns a hash of the same entries" do
        m = Immutable::Map.new({:foo => 123, :bar => 321})
        m.to_h.should eq({:foo => 123, :bar => 321})
      end
    end

    describe "#hash" do
      it "returns a different hash code for different maps" do
        m1 = Immutable::Map.new({"foo" => "bar"})
        m2 = Immutable::Map.new({"baz" => "qux"})
        m1.hash.should_not eq(m2.hash)
      end

      it "returns the same hash code for equal maps" do
        m1 = Immutable::Map.new({"foo" => "bar"})
        m2 = Immutable::Map.new({"foo" => "bar"})
        m1.hash.should eq(m2.hash)
      end
    end

    describe "transient" do
      it "yields a transient map and converts back to an immutable one" do
        map = empty_map.transient do |m|
          m.should be_a(Immutable::Map::Transient(String, Int32))
          100.times { |i| m = m.set(i.to_s, i) }
        end
        map.should be_a(Immutable::Map(String, Int32))
        map.should_not be_a(Immutable::Map::Transient(String, Int32))
        map.size.should eq(100)
        empty_map.size.should eq(0)
      end
    end
  end
end

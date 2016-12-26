# A map is an immutable mapping of keys (of type K) to values (of type V).
#
# Similarly to a hash, a map can use any type as keys, as long as it implements
# a valid `#hash` method.
#
# A map can be constructed from a hash:
#
# ```
# Immutable::Map(Symbol, Int32).new          # => Map {}
# Immutable::Map.new({:foo => 1, :bar => 2}) # => Map {:foo => 1, :bar => 2}
# Immutable::Map[{:foo => 1, :bar => 2 }]    # => Map {:foo => 1, :bar => 2}
# ```
#
# `Immutable::Map` works similarly to a regular hash, except it never mutates in
# place, but rather return modified copies. However, this copies are using
# structural sharing, ensuring performant operations and memory efficiency.
# Under the hood, `Immutable::Map` uses a bit-partitioned hash trie, ensuring
# lookups and updates with a complexity of O(Log32), which for practical
# purposes is equivalent to O(1): for maps of viable sizes (even up to billions
# of elements) the complexity is bound by a small constant.
#
require "./map/trie"

module Immutable
  class Map(K, V)
    @trie  : Trie(K, V)
    @block : (K -> V)?

    include Enumerable(Tuple(K, V))

    # Creates a map with the given key-values
    #
    # ```
    # m = Immutable::Map.new({:a => 1, :b => true}) # Map {:a => 1, :b => true}
    # ```
    def initialize(hash : Hash(K, V) = {} of K => V)
      @trie = hash.reduce(Trie(K, V).empty(object_id)) do |trie, (k, v)|
        trie.set!(k, v, object_id)
      end
      @trie.clear_owner!
      @block = nil
    end

    # Creates a map with the given key-values. When getting a key-value that is
    # not in the map, the given block is executed passing the key, and the
    # return value is returned.
    #
    # ```
    # m = Immutable::Map.new({:a => 123, :b => 321 }) # Map {:a => 123, :b => 321}
    # ```
    def initialize(hash : Hash(K, V) = {} of K => V, &block : K -> V)
      @trie = hash.reduce(Trie(K, V).empty(object_id)) do |trie, (k, v)|
        trie.set!(k, v, object_id)
      end
      @trie.clear_owner!
      @block = block
    end

    # :nodoc:
    def initialize(@trie : Trie(K, V), @block : (K -> V)? = nil)
    end

    # Creates a map with the given key-values.
    #
    # ```
    # m = Immutable::Map.new([{:a, 123}, {:b, 321}]) # Map {:a => 123, :b => 321}
    # ```
    def self.new(e : Enumerable({_, _}))
      Transient.new(e).persist!
    end

    # Creates a map with the given key-values
    #
    # ```
    # m = Immutable::Map[{:a => 123, :b => 321}] # Map {:a => 123, :b => 321}
    # ```
    def self.[](hash : Hash(K, V) = {} of K => V)
      new(hash)
    end

    # Executes the given block passing a transient version of the map, then
    # converts the transient map back to an immutable one and returns it.
    #
    # This is useful to perform several updates on a map in an efficient way: as
    # the transient map supports the same API of map, but performs updates in
    # place, avoiding unnecessary object allocations.
    #
    # ```
    # map = Immutable::Map(Int32, Int32).new
    # m2 = map.transient do |m|
    #   100.times { |i| m = m.set(i, i * 2) }
    # end
    # m2.size # => 100
    # ```
    #
    # Note that, as the transient is mutable, it is not thread-safe.
    def transient
      t = Transient.new(@trie, @block)
      yield t
      t.persist!
    end

    # Returns the number of key-value pairs in the map
    def size
      @trie.size
    end

    # Returns the value associated with the given key, if existing, else raises
    # `KeyError`
    def fetch(key : K)
      fetch(key) do
        if b = @block
          next b.call(key)
        end
        raise KeyError.new("Missing map key: #{key.inspect}")
      end
    end

    # Returns the value associated with the given key, if existing, else
    # executes the given block and returns its value
    def fetch(key : K, &block : K -> _)
      @trie.fetch(key, &block)
    end

    # Returns the value associated with the given key, if existing, else
    # it returns the provided default value
    def fetch(key : K, default)
      fetch(key) { default }
    end

    # Returns the value associated with the given key, if existing, else raises
    # `KeyError`. See also `fetch`
    def [](key : K)
      fetch(key)
    end

    # Returns the value associated with the given key, if existing, else nil
    def []?(key : K)
      fetch(key, nil)
    end

    # Returns a modified copy of the map where key is associated to value
    #
    # ```
    # m  = Immutable::Map[{:foo => 123}]
    # m2 = m.set(:bar, 321) # => Map {:foo => 123, :bar => 321}
    # m                     # => Map {:foo => 123}
    # ```
    def set(key : K, value : V)
      Map.new(@trie.set(key, value), @block)
    end


    # Returns a modified copy of the map with the key-value pair removed. If the
    # key is not existing, it raises `KeyError`
    #
    # ```
    # m  = Immutable::Map[{:foo => 123, :bar => 321 }]
    # m2 = m.delete(:bar) # => Map {:foo => 123}
    # m                   # => Map {:foo => 123, bar: 321}
    # ```
    def delete(key : K)
      Map.new(@trie.delete(key), @block)
    end

    # Returns a new map with the keys and values of this map and the given hash
    # combined.
    # A value in the given hash takes precedence over the one in this map.
    #
    # ```
    # map = Immutable::Map[{"foo" => "bar"}]
    # merged = map.merge({"baz" => "qux"})
    # merged # => Map {"foo" => "bar", "baz" => "qux"}
    # map    # => Map {"foo" => "bar"}
    # ```
    def merge(hash : Hash(K, V))
      trie = hash.reduce(@trie) do |trie, (key, value)|
        trie.set(key, value)
      end
      Map.new(trie, @block)
    end

    # Returns a new map with the keys and values of this map and the given map
    # combined.
    # A value in the given map takes precedence over the one in this map.
    #
    # ```
    # map = Immutable::Map[{"foo" => "bar"}]
    # merged = map.merge(Immutable::Map[{"baz" => "qux"}])
    # merged # => Map {"foo" => "bar", "baz" => "qux"}
    # map    # => Map {"foo" => "bar"}
    # ```
    def merge(map : Map(K, V))
      trie = map.reduce(@trie) do |trie, (key, value)|
        trie.set(key, value)
      end
      Map.new(trie, @block)
    end

    def merge(hash : Hash(L, W)) forall L, W
      Transient(K | L, V | W).new.merge(self).merge(hash).persist!
    end

    def merge(map : Map(L, W)) forall L, W
      Transient(K | L, V | W).new.merge(self).merge(map).persist!
    end

    # Calls the given block for each key-value and passes in a tuple of key and
    # value. The order of iteration is not specified.
    #
    # ```
    # m = Immutable::Map[{"foo" => "bar"}]
    # m.each do |keyval|
    #   keyval[0] # => "foo"
    #   keyval[1] # => "bar"
    # end
    # ```
    def each
      @trie.each { |keyval| yield keyval }
      self
    end

    # Returns an iterator over the map entries, returning a `Tuple` of the key
    # and value. The order of iteration is not specified.
    #
    # ```
    # map = Immutable::Map[{"foo" => "bar", "baz" => "qux"}]
    # iterator = map.each
    #
    # entry = iterator.next
    # entry[0] # => "foo"
    # entry[1] # => "bar"
    #
    # entry = iterator.next
    # entry[0] # => "baz"
    # entry[1] # => "qux"
    # ```
    def each
      @trie.each
    end

    # Calls the given block for each key-value pair and passes in the key.
    #
    # ```
    # m = Immutable::Map[{"foo" => "bar"}]
    # m.each_key do |key|
    #   key # => "foo"
    # end
    # ```
    def each_key(&block : K ->)
      each do |keyval|
        block.call(keyval.first)
      end
    end

    # Returns an iterator over the map keys. The order is not guaranteed.
    #
    # ```
    # map = Immutable::Map[{"foo" => "bar", "baz" => "qux"}]
    # iterator = map.each_key
    #
    # key = iterator.next
    # key # => "foo"
    #
    # key = iterator.next
    # key # => "baz"
    # ```
    def each_key
      each.map(&.first)
    end


    # Calls the given block for each key-value pair and passes in the value.
    #
    # ```
    # m = Immutable::Map[{"foo" => "bar"}]
    # m.each_value do |val|
    #   val # => "bar"
    # end
    # ```
    def each_value(&block : V ->)
      each do |keyval|
        block.call(keyval.last)
      end
    end

    # Returns an iterator over the map values. The order is not specified.
    #
    # ```
    # map = Immutable::Map[{"foo" => "bar", "baz" => "qux"}]
    # iterator = map.each_value
    #
    # val = iterator.next
    # val # => "bar"
    #
    # val = iterator.next
    # val # => "qux"
    # ```
    def each_value
      each.map(&.last)
    end

    # Returns only the keys as an `Array`. The order is not specified.
    #
    # ```
    # m = Immutable::Map[{"foo" => "bar", "baz" => "qux"}]
    # m.keys # => ["foo", "bar"]
    # ```
    def keys
      each_key.to_a
    end

    # Returns only the values as an `Array`. The order is not specified.
    #
    # ```
    # m = Immutable::Map[{"foo" => "bar", "baz" => "qux"}]
    # m.values # => ["bar", "qux"]
    # ```
    def values
      each_value.to_a
    end

    # Appends a `String` representation of this object to the given IO object.
    def inspect(io : IO)
      to_s(io)
    end

    # Appends a String representation of this map
    # to the given IO object.
    def to_s(io : IO)
      io << "Map "
      to_h.to_s(io)
    end

    # See `Object#hash`.
    #
    # ```
    # map = Immutable::Map[{"foo" => "bar"}]
    # map.hash # => 63502
    # ```
    def hash
      reduce(size * 43) do |memo, (key, value)|
        43 * memo + (key.hash ^ value.hash)
      end
    end

    def ==(other : Map)
      return true if @trie.same?(other.trie)
      return false unless size == other.size
      all? do |kv|
        entry = other.trie.find_entry(kv[0])
        entry && (entry.value == kv[1])
      end
    end

    # :nodoc:
    def ==(other)
      false
    end

    protected def trie : Trie(K, V)
      @trie
    end

    class Transient(K, V) < Map(K, V)
      def initialize(hash : Hash(K, V) = {} of K => V)
        @trie = hash.reduce(Trie(K, V).empty(object_id)) do |t, (k, v)|
          t.set!(k, v, object_id)
        end
        @block = nil
      end

      def initialize(hash : Hash(K, V) = {} of K => V, &block : K -> V)
        @trie = hash.reduce(Trie(K, V).empty(object_id)) do |t, (k, v)|
          t.set!(k, v, object_id)
        end
        @block = block
      end

      # :nodoc:
      def initialize(@trie : Trie(K, V), @block : (K -> V)? = nil)
      end

      def self.new(e : Enumerable({L, W})) forall L, W
        e.reduce(Transient(L, W).new) do |m, (k, v)|
          m.set(k, v)
        end
      end

      def persist!
        @trie.clear_owner!
        Map.new(@trie, @block)
      end

      def set(key : K, value : V)
        @trie = @trie.set!(key, value, object_id)
        self
      end

      def delete(key : K)
        @trie = @trie.delete!(key, object_id)
        self
      end

      def merge(hash : Hash(K, V))
        @trie = hash.reduce(@trie) do |trie, (key, value)|
          trie.set!(key, value, object_id)
        end
        self
      end

      def merge(map : Map(K, V))
        @trie = map.reduce(@trie) do |trie, (key, value)|
          trie.set!(key, value, object_id)
        end
        self
      end

      def merge(hash : Hash(L, W)) forall L, W
        Transient(K | L, V | W).new.merge(self).merge(hash)
      end

      def merge(map : Map(L, W)) forall L, W
        Transient(K | L, V | W).new.merge(self).merge(map)
      end
    end
  end
end

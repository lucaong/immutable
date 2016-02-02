# A map is an immutable mapping of keys (of type K) to values (of type V).
#
# Similarly to a hash, a map can use any type as keys, as long as it implements
# a valid `#hash` method.
#
# A map can be constructed from a hash:
#
# ```
# Immutable::Map(Symbol, Int32).new      # => Map {}
# Immutable::Map.new({ foo: 1, bar: 2 }) # => Map {:foo => 1, :bar => 2}
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
  struct Map(K, V)
    @trie  : Trie(K, V)
    @block : (K -> V)?

    # Creates a map with the given key-values
    #
    # ```
    # m = Immutable::Map.new({ foo: 123, bar: 321 }) # Map {foo: 123, bar: 321}
    # ```
    def initialize(hash = {} of K => V : Hash(K, V))
      @trie  = hash.reduce(Trie(K, V).empty) { |h, k, v| h.set(k, v) }
      @block = nil
    end

    # Creates a map with the given key-values. When getting a key-value that is
    # not in the map, the given block is executed passing the key, and the
    # return value is returned.
    #
    # ```
    # m = Immutable::Map.new({ foo: 123, bar: 321 }) # Map {foo: 123, bar: 321}
    # ```
    def initialize(hash = {} of K => V : Hash(K, V), &block : K -> V)
      @trie  = hash.reduce(Trie(K, V).empty) { |h, k, v| h.set(k, v) }
      @block = block
    end

    def initialize(@trie : Trie(K, V), @block = nil : (K -> V)?)
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
    def fetch(key : K, &block : K -> U)
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
    # m  = Immutable::Map.new({ foo: 123 })
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
    # m  = Immutable::Map.new({ foo: 123, bar: 321 })
    # m2 = m.delete(:bar) # => Map {:foo => 123}
    # m                   # => Map {:foo => 123, bar: 321}
    # ```
    def delete(key : K)
      Map.new(@trie.delete(key), @block)
    end

    # Calls the given block for each key-value and passes in a tuple of key and
    # value. The order of iteration is not specified.
    #
    # ```
    # m = Immutable::Map.new({"foo" => "bar"})
    # m.each do |keyval|
    #   keyval[0] # => "foo"
    #   keyval[1] # => "bar"
    # end
    # ```
    def each(&block : Tuple(K, V) ->)
      @trie.each(&block)
      self
    end

    # Returns an iterator over the map entries, returning a `Tuple` of the key
    # and value. The order of iteration is not specified.
    #
    # ```
    # map = Immutable::Map.new({"foo" => "bar", "baz" => "qux"})
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
    # m = Immutable::Map.new({"foo" => "bar"})
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
    # map = Immutable::Map.new({"foo" => "bar", "baz" => "qux"})
    # iterator = map.each_key
    #
    # key = iterator.next
    # key # => "foo"
    #
    # key = iterator.next
    # key # => "baz"
    # ```
    def each_key
      each.map { |keyval| keyval.first }
    end


    # Calls the given block for each key-value pair and passes in the value.
    #
    # ```
    # m = Immutable::Map.new({"foo" => "bar"})
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
    # map = Immutable::Map.new({"foo" => "bar", "baz" => "qux"})
    # iterator = map.each_value
    #
    # val = iterator.next
    # val # => "bar"
    #
    # val = iterator.next
    # val # => "qux"
    # ```
    def each_value
      each.map { |keyval| keyval.last }
    end

    # Returns only the keys as an `Array`. The order is not specified.
    #
    # ```
    # m = Immutable::Map.new({"foo" => "bar", "baz" => "qux"})
    # m.keys # => ["foo", "bar"]
    # ```
    def keys
      each_key.to_a
    end

    # Returns only the values as an `Array`. The order is not specified.
    #
    # ```
    # m = Immutable::Map.new({"foo" => "bar", "baz" => "qux"})
    # m.values # => ["bar", "qux"]
    # ```
    def values
      each_value.to_a
    end

    # Returns a new `Array` of tuples populated with each key-value pair. The
    # order is not specified.
    #
    # ```
    # m = Immutable::Map.new({"foo" => "bar", "baz" => "qux"})
    # m.to_a # => [{"foo", "bar"}, {"baz", "qux"}]
    # ```
    def to_a
      each.to_a
    end
  end
end

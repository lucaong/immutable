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

    def initialize(hash = {} of K => V : Hash(K, V))
      @trie  = hash.reduce(Trie(K, V).empty) { |h, k, v| h.set(k, v) }
      @block = nil
    end

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
  end
end

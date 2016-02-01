# An `Immutable::Hash` is an immutable mapping of keys to values.
#
# An `Immutableble::Hash` can be constructed from a Crystal hash:
#
# ```
# Immutable::Hash(Symbol, Int32).new      # => Hash {}
# Immutable::Hash.new({ foo: 1, bar: 2 }) # => Hash {:foo => 1, :bar => 2}
# ```
#
# `Immutable::Hash` works similarly to a standard Crystal hash, except it never
# mutates in place, but rather return modified copies. However, this copies are
# using structural sharing, ensuring performant operations and memory
# efficiency. Under the hood, `Immutable::Hash` uses a bit-partitioned hash
# trie, ensuring lookups and updates with a complexity of O(Log32), which for
# practical purposes is equivalent to O(1): for hashes of viable sizes (even up
# to billions of elements) the complexity is bound by a small constant.
#
require "./hash/trie"

module Immutable
  struct Hash(K, V)
    @trie  : Trie(K, V)
    @block : (K -> V)?

    def initialize(hash = {} of K => V : ::Hash(K, V))
      @trie  = hash.reduce(Trie(K, V).empty) { |h, k, v| h.set(k, v) }
      @block = nil
    end

    def initialize(hash = {} of K => V : ::Hash(K, V), &block : K -> V)
      @trie  = hash.reduce(Trie(K, V).empty) { |h, k, v| h.set(k, v) }
      @block = block
    end

    def initialize(@trie : Trie(K, V), @block = nil : (K -> V)?)
    end

    # Returns the number of key-value pairs in the hash
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
        raise KeyError.new("Missing hash key: #{key.inspect}")
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

    # Returns a modified copy of the hash where key is associated to value
    #
    # ```
    # h  = Immutable::Hash.new({ foo: 123 })
    # h2 = h.set(:bar, 321) # => Hash {:foo => 123, :bar => 321}
    # h                     # => Hash {:foo => 123}
    # ```
    def set(key : K, value : V)
      Hash.new(@trie.set(key, value), @block)
    end
  end
end

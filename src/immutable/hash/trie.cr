module Immutable
  struct Hash(K, V)
    struct Trie(K, V)
      BITS_PER_LEVEL = 5_u32
      BLOCK_SIZE = (2 ** BITS_PER_LEVEL).to_u32
      INDEX_MASK = BLOCK_SIZE - 1

      getter :size, :levels

      @children : Array(Trie(K, V))
      @bitmap   : UInt32
      @values   : ::Hash(K, V)
      @size     : Int32
      @levels   : Int32

      def initialize(
        @children : Array(Trie(K, V)),
        @values : ::Hash(K, V),
        @bitmap : UInt32,
        @levels : Int32)
        children_size = @children.reduce(0) { |size, child| size + child.size }
        @size         = children_size + @values.size
      end

      def self.empty
        new([] of Trie(K, V), {} of K => V, 0_u32, 0)
      end

      def get(key : K) : V
        lookup(key.hash) { |hash| hash[key] }
      end

      def fetch(key : K, &block : K -> U)
        lookup(key.hash) { |hash| hash.fetch(key, &block) }
      end

      def has_key?(key : K) : Bool
        lookup(key.hash) { |hash| hash.has_key?(key) }
      end

      def set(key : K, value : V) : Trie(K, V)
        set_at_index(key.hash, key, value)
      end

      protected def set_at_index(index : Int32, key : K, value : V) : Trie(K, V)
        if leaf_of?(index)
          set_leaf(index, key, value)
        else
          set_branch(index, key, value)
        end
      end

      protected def lookup(index : Int32, &block : ::Hash(K, V) -> U)
        if leaf_of?(index)
          yield @values
        else
          return yield({} of K => V) unless i = child_index(bit_index(index))
          @children[i].lookup(index, &block)
        end
      end

      private def leaf_of?(index)
        (index.to_u32 >> (@levels * BITS_PER_LEVEL)) == 0
      end

      private def set_leaf(index : Int32, key : K, value : V) : Trie(K, V)
        i = bit_index(index)
        values = @values.dup.tap do |vs|
          vs[key] = value
        end
        Trie.new(@children, values, @bitmap, @levels)
      end

      private def set_branch(index : Int32, key : K, value : V) : Trie(K, V)
        i = bit_index(index)
        if idx = child_index(i)
          children = @children.dup.tap do |cs|
            cs[idx] = cs[idx].set_at_index(index, key, value)
          end
          Trie.new(children, @values, @bitmap, @levels)
        else
          child = Trie.new([] of Trie(K, V), {} of K => V, 0_u32, @levels + 1)
            .set_at_index(index, key, value)
          Trie.new(@children.dup.push(child), @values, @bitmap | bitpos(i), @levels)
        end
      end

      private def bitpos(i : UInt32) : UInt32
        1_u32 << i
      end

      private def child_index(bidx : UInt32) : UInt32?
        pos = bitpos(bidx)
        return nil unless (pos & @bitmap) == pos
        popcount(@bitmap & (pos - 1))
      end

      private def popcount(x : UInt32)
        x = x - ((x >> 1) & 0x55555555_u32)
        x = (x & 0x33333333_u32) + ((x >> 2) & 0x33333333_u32)
        (((x + (x >> 4)) & 0x0F0F0F0F_u32) * 0x01010101_u32) >> 24
      end

      private def bit_index(index : Int32) : UInt32
        (index.to_u32 >> (@levels * BITS_PER_LEVEL)) & INDEX_MASK
      end
    end
  end
end

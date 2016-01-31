module Immutable
  struct Hash(K, V)
    struct Trie(K, V)
      BITS_PER_LEVEL = 5_u32
      BLOCK_SIZE = (2 ** BITS_PER_LEVEL).to_u32
      INDEX_MASK = BLOCK_SIZE - 1

      getter :size, :levels

      @children : Array(Trie(K, V))
      @bitmap   : UInt32
      @values   : Array(::Hash(K, V))
      @size     : Int32
      @levels   : Int32

      def initialize(@children : Array(Trie(K, V)), @bitmap, @levels : Int32)
        @size   = @children.reduce(0) { |size, child| size + child.size }
        @values = [] of ::Hash(K, V)
      end

      def initialize(@values : Array(::Hash(K, V)), @bitmap : UInt32)
        @size     = @values.size
        @levels   = 0
        @children = [] of Trie(K, V)
      end

      def self.empty
        new([] of ::Hash(K, V), 0_u32)
      end

      def get(key : K)
        lookup(key.hash, key) { raise KeyError.new }
      end

      def set(key : K, value : V) : Trie(K, V)
        set(key.hash, key, value)
      end

      def set(index : Int32, key : K, value : V) : Trie(K, V)
        if leaf?
          set_leaf(index, key, value)
        else
          set_branch(index, key, value)
        end
      end

      private def leaf?
        @levels == 0
      end

      protected def lookup(index : Int32, key : K)
        return yield unless i = index_for(child_index(index))
        if leaf?
          @values[i].fetch(key) { |_| yield }
        else
          @children[i].lookup(index, key) { yield }
        end
      end

      private def set_leaf(index : Int32, key : K, value : V) : Trie(K, V)
        i = child_index(index)
        if idx = index_for(i)
          values = @values.dup.tap do |vs|
            vs[idx] = vs[idx].dup
            vs[idx][key] = value
          end
          Trie.new(values, @bitmap)
        else
          bucket = {} of K => V
          bucket[key] = value
          Trie.new(@values.dup.push(bucket), @bitmap | bitpos(i))
        end
      end

      private def set_branch(index : Int32, key : K, value : V) : Trie(K, V)
        i = child_index(index)
        if idx = index_for(i)
          children = @children.dup.tap do |cs|
            cs[idx] = cs[idx].set(index, key, value)
          end
          Trie.new(children, @bitmap, @levels)
        else
          if @levels > 1
            child = Trie.new([] of Trie(K, V), 0_u32, @levels - 1)
          else
            child = Trie.new([] of ::Hash(K, V), 0_u32)
          end
          Trie.new(@children.dup.push(child), @bitmap | bitpos(i), @levels)
        end
      end

      private def bitpos(i : Int32)
        1_u32 << i
      end

      private def index_for(i : Int32)
        pos = bitpos(i)
        return nil unless pos & @bitmap == pos
        popcount(@bitmap & (pos - 1))
      end

      private def popcount(x : UInt32)
        x = x - ((x >> 1) & 0x5555555555555555_u64)
        x = (x & 0x3333333333333333_u64) + ((x >> 2) & 0x3333333333333333_u64)
        (((x + (x >> 4)) & 0x0F0F0F0F0F0F0F0F_u64) * 0x0101010101010101_u64) >> 56
      end

      private def child_index(index : Int32)
        (index >> (@levels * BITS_PER_LEVEL)) & INDEX_MASK
      end
    end
  end
end

module Immutable
  class Map(K, V)
    class Trie(K, V)
      BITS_PER_LEVEL = 5_u32
      BLOCK_SIZE = (2 ** BITS_PER_LEVEL).to_u32
      INDEX_MASK = BLOCK_SIZE - 1

      include Enumerable(Tuple(K, V))

      getter :size, :levels

      @children : Array(Trie(K, V))
      @bitmap   : UInt32
      @values   : Hash(K, V)
      @size     : Int32
      @levels   : Int32
      @owner    : UInt64?

      def initialize(
        @children : Array(Trie(K, V)),
        @values : Hash(K, V),
        @bitmap : UInt32,
        @levels : Int32,
        @owner = nil : UInt64?)
        children_size = @children.reduce(0) { |size, child| size + child.size }
        @size         = children_size + @values.size
      end

      def self.empty(owner = nil : UInt64?)
        new([] of Trie(K, V), {} of K => V, 0_u32, 0, owner)
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

      def set!(key : K, value : V, from : UInt64) : Trie(K, V)
        set_at_index!(key.hash, key, value, from)
      end

      def delete(key : K) : Trie(K, V)
        delete_at_index(key.hash, key)
      end

      def delete!(key : K, from : UInt64) : Trie(K, V)
        delete_at_index!(key.hash, key, from)
      end

      def each
        each.each { |entry| yield entry }
        self
      end

      def each
        children_iter = @children.each.map do |child|
          child.each as Iterator::Chain(Hash::EntryIterator(K, V), EntryIterator(K, V), {K, V}, {K, V})
        end
        @values.each.chain(EntryIterator(K, V).new(children_iter))
      end

      def empty?
        size == 0
      end

      protected def set_at_index(index : Int32, key : K, value : V) : Trie(K, V)
        if leaf_of?(index)
          set_leaf(index, key, value)
        else
          set_branch(index, key, value)
        end
      end

      protected def set_at_index!(index : Int32, key : K, value : V, from : UInt64) : Trie(K, V)
        return set_at_index(index, key, value) unless from == @owner
        if leaf_of?(index)
          @values[key] = value
        else
          set_branch!(index, key, value, from)
        end
        self
      end

      protected def delete_at_index(index : Int32, key : K) : Trie(K, V)
        if leaf_of?(index)
          delete_in_leaf(index, key)
        else
          delete_in_branch(index, key)
        end
      end

      protected def delete_at_index!(index : Int32, key : K, from : UInt64) : Trie(K, V)
        return delete_at_index(index, key) unless from == @owner
        if leaf_of?(index)
          @values.delete(key)
        else
          delete_in_branch!(index, key, from)
        end
        self
      end

      protected def lookup(index : Int32, &block : Hash(K, V) -> U)
        if leaf_of?(index)
          yield @values
        else
          return yield({} of K => V) unless i = child_index?(bit_index(index))
          @children[i].lookup(index, &block)
        end
      end

      private def leaf_of?(index)
        (index.to_u32 >> (@levels * BITS_PER_LEVEL)) == 0
      end

      private def set_leaf(index : Int32, key : K, value : V) : Trie(K, V)
        values = @values.dup.tap do |vs|
          vs[key] = value
        end
        Trie.new(@children, values, @bitmap, @levels)
      end

      private def set_branch(index : Int32, key : K, value : V) : Trie(K, V)
        i = bit_index(index)
        if idx = child_index?(i)
          children = @children.dup.tap do |cs|
            cs[idx] = cs[idx].set_at_index(index, key, value)
          end
          Trie.new(children, @values, @bitmap, @levels)
        else
          child = Trie.new([] of Trie(K, V), {} of K => V, 0_u32, @levels + 1)
            .set_at_index(index, key, value)
          bitmap = @bitmap | bitpos(i)
          Trie.new(@children.dup.insert(child_index(i, bitmap), child), @values, bitmap, @levels)
        end
      end

      private def set_branch!(index : Int32, key : K, value : V, from : UInt64)
        i = bit_index(index)
        if idx = child_index?(i)
          @children[idx] = @children[idx].set_at_index!(index, key, value, from)
        else
          child = Trie.new([] of Trie(K, V), {} of K => V, 0_u32, @levels + 1)
            .set_at_index!(index, key, value, from)
          @bitmap = @bitmap | bitpos(i)
          @children.insert(child_index(i, @bitmap), child)
        end
      end

      private def delete_in_leaf(index : Int32, key : K)
        values = @values.dup.tap do |vs|
          vs.delete(key)
        end
        Trie.new(@children, values, @bitmap, @levels)
      end

      private def delete_in_branch(index : Int32, key : K)
        i = bit_index(index)
        raise KeyError.new("key #{key.inspect} not found") unless idx = child_index?(i)
        child = @children[idx].delete_at_index(index, key)
        if child.empty?
          children = @children.dup.tap { |cs| cs.delete_at(idx) }
          bitmap   = @bitmap & (i ^ INDEX_MASK)
        else
          children = @children.dup.tap { |cs| cs[idx] = child }
          bitmap   = @bitmap
        end
        Trie.new(children, @values, bitmap, @levels)
      end

      private def delete_in_branch!(index : Int32, key : K, from : UInt64)
        i = bit_index(index)
        raise KeyError.new("key #{key.inspect} not found") unless idx = child_index?(i)
        child = @children[idx].delete_at_index!(index, key, from)
        if child.empty?
          @children.delete_at(idx)
          @bitmap = @bitmap & (i ^ INDEX_MASK)
        else
          @children[idx] = child
        end
      end

      private def bitpos(i : UInt32) : UInt32
        1_u32 << i
      end

      private def child_index?(bidx : UInt32) : UInt32?
        pos = bitpos(bidx)
        return nil unless (pos & @bitmap) == pos
        popcount(@bitmap & (pos - 1))
      end

      private def child_index(bidx : UInt32, bitmap : UInt32) : UInt32
        pos = bitpos(bidx)
        popcount(bitmap & (pos - 1))
      end

      private def popcount(x : UInt32)
        x = x - ((x >> 1) & 0x55555555_u32)
        x = (x & 0x33333333_u32) + ((x >> 2) & 0x33333333_u32)
        (((x + (x >> 4)) & 0x0F0F0F0F_u32) * 0x01010101_u32) >> 24
      end

      private def bit_index(index : Int32) : UInt32
        (index.to_u32 >> (@levels * BITS_PER_LEVEL)) & INDEX_MASK
      end

      class EntryIterator(K, V)
        include Iterator(Tuple(K, V))

        @iterator  : Map(Array::ItemIterator(Trie(K, V)), Trie(K, V), Chain(Hash::EntryIterator(K, V), Trie::EntryIterator(K, V), {K, V}, {K, V}))

        @generator : Chain(Hash::EntryIterator(K, V), Trie::EntryIterator(K, V), {K, V}, {K, V}) |
                     Map(Array::ItemIterator(Trie(K, V)), Trie(K, V), Chain(Hash::EntryIterator(K, V), Trie::EntryIterator(K, V), {K, V}, {K, V}))

        @top : Bool

        def initialize(@iterator)
          @generator = @iterator
          @top = true
        end

        def next : Tuple(K, V) | Stop
          value = @generator.next
          if value.is_a?(Stop)
            return stop if @top
            @generator = @iterator
            @top = true
            self.next
          else
            flatten(value)
          end
        end

        private def flatten(value) : Tuple(K, V) | Stop
          if value.is_a? Iterator
            @generator = value
            @top       = false
            self.next
          else
            value
          end
        end
      end
    end
  end
end

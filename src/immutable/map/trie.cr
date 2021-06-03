module Immutable
  class Map(K, V)
    class Trie(K, V)
      BITS_PER_LEVEL = 5_u64
      BLOCK_SIZE     = 2_u64 ** BITS_PER_LEVEL
      INDEX_MASK     = BLOCK_SIZE - 1_u64
      BITMAP_MASK    = (2_u64 ** BLOCK_SIZE - 1_u64)

      include Enumerable(Tuple(K, V))

      getter :size, :levels

      @children : Array(Trie(K, V))
      @bitmap : UInt64
      @values : Values(K, V)
      @size : Int32
      @levels : Int32
      @owner : UInt64?

      def initialize(
        @children : Array(Trie(K, V)),
        @values : Values(K, V),
        @bitmap : UInt64,
        @levels : Int32,
        @owner : UInt64? = nil
      )
        children_size = @children.reduce(0) { |size, child| size + child.size }
        @size = children_size + @values.size
      end

      def self.empty(owner : UInt64? = nil)
        children = [] of Trie(K, V)
        values = Values(K, V).new
        new(children, values, 0_u32, 0, owner)
      end

      def get(key : K) : V
        lookup(key.hash) { |hash| hash[key] }
      end

      def fetch(key : K, &block : K -> _)
        lookup(key.hash) { |hash| hash.fetch(key, &block) }
      end

      def has_key?(key : K) : Bool
        lookup(key.hash) { |hash| hash.has_key?(key) }
      end

      def find_entry(key : K) : Entry(K, V)?
        lookup(key.hash) { |hash| hash.find_entry(key) }
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
          child.each.as(Iterator({K, V}))
        end
        @values.each.chain(EntryIterator(K, V).new(children_iter))
      end

      def empty?
        size == 0
      end

      def clear_owner!
        @owner = nil
        self
      end

      protected def set_at_index(index : UInt64, key : K, value : V, from : UInt64? = nil) : Trie(K, V)
        if leaf_of?(index)
          set_leaf(index, key, value, from)
        else
          set_branch(index, key, value, from)
        end
      end

      protected def set_at_index!(index : UInt64, key : K, value : V, from : UInt64) : Trie(K, V)
        return set_at_index(index, key, value, from) unless from == @owner
        if leaf_of?(index)
          @values[key] = value
        else
          set_branch!(index, key, value, from)
        end
        @size = calculate_size
        self
      end

      protected def delete_at_index(index : UInt64, key : K) : Trie(K, V)
        if leaf_of?(index)
          delete_in_leaf(index, key)
        else
          delete_in_branch(index, key)
        end
      end

      protected def delete_at_index!(index : UInt64, key : K, from : UInt64) : Trie(K, V)
        return delete_at_index(index, key) unless from == @owner
        if leaf_of?(index)
          @values.delete(key)
        else
          delete_in_branch!(index, key, from)
        end
        @size = calculate_size
        self
      end

      protected def lookup(index : UInt64, &block : Values(K, V) -> _)
        if leaf_of?(index)
          yield @values
        else
          return yield(Values(K, V).new) unless i = child_index?(bit_index(index))
          @children[i].lookup(index, &block)
        end
      end

      private def leaf_of?(index)
        (index.to_u32! >> (@levels * BITS_PER_LEVEL)) == 0
      end

      private def set_leaf(index : UInt64, key : K, value : V, from : UInt64?) : Trie(K, V)
        values = @values.dup.tap do |vs|
          vs[key] = value
        end
        Trie.new(@children, values, @bitmap, @levels, from)
      end

      private def set_branch(index : UInt64, key : K, value : V, from : UInt64?) : Trie(K, V)
        i = bit_index(index)
        if idx = child_index?(i)
          children = @children.dup.tap do |cs|
            cs[idx] = cs[idx].set_at_index(index, key, value)
          end
          Trie.new(children, @values, @bitmap, @levels, from)
        else
          child = Trie.new(([] of Trie(K, V)), Values(K, V).new, 0_u32, @levels + 1, from)
            .set_at_index(index, key, value)
          bitmap = @bitmap | bitpos(i)
          Trie.new(@children.dup.insert(child_index(i, bitmap), child), @values, bitmap, @levels, from)
        end
      end

      private def set_branch!(index : UInt64, key : K, value : V, from : UInt64)
        i = bit_index(index)
        if idx = child_index?(i)
          @children[idx] = @children[idx].set_at_index!(index, key, value, from)
        else
          child = Trie.new(([] of Trie(K, V)), Values(K, V).new, 0_u32, @levels + 1)
            .set_at_index!(index, key, value, from)
          @bitmap = @bitmap | bitpos(i)
          @children.insert(child_index(i, @bitmap), child)
        end
      end

      private def delete_in_leaf(index : UInt64, key : K)
        values = @values.dup.tap do |vs|
          vs.delete(key)
        end
        Trie.new(@children, values, @bitmap, @levels)
      end

      private def delete_in_branch(index : UInt64, key : K)
        i = bit_index(index)
        raise KeyError.new("key #{key.inspect} not found") unless idx = child_index?(i)
        child = @children[idx].delete_at_index(index, key)
        if child.empty?
          children = @children.dup.tap { |cs| cs.delete_at(idx) }
          bitmap = @bitmap & (bitpos(i) ^ BITMAP_MASK)
        else
          children = @children.dup.tap { |cs| cs[idx] = child }
          bitmap = @bitmap
        end
        Trie.new(children, @values, bitmap, @levels)
      end

      private def delete_in_branch!(index : UInt64, key : K, from : UInt64)
        i = bit_index(index)
        raise KeyError.new("key #{key.inspect} not found") unless idx = child_index?(i)
        child = @children[idx].delete_at_index!(index, key, from)
        if child.empty?
          @children.delete_at(idx)
          @bitmap = @bitmap & (bitpos(i) ^ BITMAP_MASK)
        else
          @children[idx] = child
        end
      end

      private def bitpos(i : UInt64) : UInt64
        1_u64 << i
      end

      private def child_index?(bidx : UInt64) : UInt64?
        pos = bitpos(bidx)
        return nil unless (pos & @bitmap) == pos
        (@bitmap & (pos - 1)).popcount.to_u64
      end

      private def child_index(bidx : UInt64, bitmap : UInt64) : UInt64
        pos = bitpos(bidx)
        (bitmap & (pos - 1)).popcount.to_u64
      end

      private def bit_index(index : UInt64) : UInt64
        (index.to_u64 >> (@levels * BITS_PER_LEVEL)) & INDEX_MASK
      end

      private def calculate_size
        children_size = @children.reduce(0) { |size, child| size + child.size }
        children_size + @values.size
      end

      struct Entry(K, V)
        @key : K
        @value : V

        getter :key, :value

        def initialize(@key : K, @value : V)
        end
      end

      struct Values(K, V)
        @entries : Array(Entry(K, V))

        def initialize
          @entries = [] of Entry(K, V)
        end

        def initialize(@entries : Array(Entry(K, V)))
        end

        def size
          @entries.size
        end

        def each
          @entries.map { |entry| {entry.key, entry.value} }.each
        end

        def [](key : K) : V
          fetch(key) { raise KeyError.new }
        end

        def []?(key : K) : V?
          fetch(key) { nil }
        end

        def fetch(key : K)
          @entries.each do |entry|
            return entry.value if entry.key == key
          end
          yield key
        end

        def fetch(key : K, default)
          fetch(key) { default }
        end

        def delete(key : K) : V
          @entries.each_with_index do |entry, i|
            if entry.key == key
              @entries.delete_at(i)
              return entry.value
            end
          end
          raise KeyError.new
        end

        def find_entry(key : K) : Entry(K, V)?
          @entries.each do |entry|
            return entry if entry.key == key
          end
          nil
        end

        def has_key?(key : K) : Bool
          return true if find_entry(key)
          false
        end

        def []=(key : K, value : V)
          @entries.each_with_index do |entry, i|
            if entry.key == key
              return @entries[i] = Entry(K, V).new(key, value)
            end
          end

          @entries.push(Entry(K, V).new(key, value))
          value
        end

        def dup
          Values(K, V).new(@entries.dup)
        end
      end

      class EntryIterator(K, V)
        include Iterator(Tuple(K, V))

        @iterator : Iterator(Iterator({K, V}))
        @generator : Iterator({K, V}) | Iterator(Iterator({K, V}))
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
            @top = false
            self.next
          else
            value
          end
        end
      end
    end
  end
end

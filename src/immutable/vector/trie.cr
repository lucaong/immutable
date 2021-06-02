module Immutable
  class Vector(T)
    class Trie(T)
      BITS_PER_LEVEL = 5_u32
      BLOCK_SIZE     = (2 ** BITS_PER_LEVEL).to_u32
      INDEX_MASK     = BLOCK_SIZE - 1

      include Enumerable(T)

      getter :size, :levels

      @children : Array(Trie(T))
      @values : Array(T)
      @size : Int32
      @levels : Int32
      @owner : UInt64?

      def initialize(@children : Array(Trie(T)), @levels : Int32, @owner : UInt64? = nil)
        @size = @children.reduce(0) { |sum, child| sum + child.size }
        @values = [] of T
      end

      def initialize(@values : Array(T), @owner : UInt64? = nil)
        @size = @values.size
        @levels = 0
        @children = [] of Trie(T)
      end

      def at(index : Int)
        return yield if index < 0 || index >= size
        lookup(index)
      end

      def get(index : Int)
        at(index) { raise IndexError.new }
      end

      def update(index : Int, value : T) : Trie(T)
        raise IndexError.new if index < 0 || index >= size
        set(index, value)
      end

      def update!(index : Int, value : T, from : UInt64) : Trie(T)
        raise IndexError.new if index < 0 || index >= size
        set!(index, value, from)
      end

      def each
        i = 0
        while i < size
          leaf_values = leaf_for(i).values
          leaf_values.each do |value|
            yield value
            i += 1
          end
        end
        self
      end

      def each
        FlattenLeaves.new((0...size).step(BLOCK_SIZE).map do |i|
          leaf_for(i).values.each.as(Iterator(T))
        end)
      end

      def push_leaf(leaf : Array(T), from : UInt64? = nil) : Trie(T)
        raise ArgumentError.new if leaf.size > BLOCK_SIZE || size % 32 != 0
        return Trie.new([self], @levels + 1, from).push_leaf(leaf, from) if full?
        return Trie.new(leaf, from) if empty? && leaf?
        Trie.new(@children.dup.tap do |cs|
          if @levels == 1
            cs.push(Trie.new(leaf))
          else
            if cs.empty? || cs.last.full?
              cs << Trie.new([] of Trie(T), @levels - 1)
            end
            cs[-1] = cs[-1].push_leaf(leaf, from)
          end
        end, @levels, from)
      end

      def push_leaf!(leaf : Array(T), from : UInt64) : Trie(T)
        raise ArgumentError.new if leaf.size > BLOCK_SIZE || size % 32 != 0
        return push_leaf(leaf, from) unless from == @owner
        return Trie.new([self], @levels + 1, from).push_leaf!(leaf, from) if full?
        return Trie.new(leaf, @owner) if empty? && leaf?
        if @levels == 1
          @children.push(Trie.new(leaf, from))
        else
          if @children.empty? || @children.last.full?
            @children << Trie.new([] of Trie(T), @levels - 1, from)
          end
          @children[-1] = @children[-1].push_leaf!(leaf, from)
        end
        @size = calculate_size
        self
      end

      def pop_leaf(from : UInt64? = nil) : Trie(T)
        raise ArgumentError.new if empty? || size % 32 != 0
        return Trie.new([] of T, from) if leaf?
        child = @children.last.pop_leaf
        if child.empty?
          return @children.first if @children.size == 2
          return Trie.new(@children[0...-1], @levels, from)
        end
        Trie.new(@children[0...-1].push(child), @levels, from)
      end

      def pop_leaf!(from : UInt64) : Trie(T)
        raise ArgumentError.new if empty? || size % 32 != 0
        return pop_leaf(from) unless from == @owner
        return Trie.new([] of T, from) if leaf?
        @children[-1] = @children[-1].pop_leaf!(from)
        if @children[-1].empty?
          return @children.first if @children.size == 2
          @children.pop
        end
        @size = calculate_size
        self
      end

      def last
        get(size - 1)
      end

      def last_leaf
        leaf_for(@size - 1).values
      end

      def empty?
        @size == 0
      end

      def leaf?
        @levels == 0
      end

      def inspect
        return @values.inspect if leaf?
        "[#{@children.map { |c| c.inspect }.join(", ")}]"
      end

      def clear_owner!
        @owner = nil
        self
      end

      def self.empty(owner : UInt64? = nil)
        Trie.new([] of T, owner)
      end

      def self.from(elems : Array(T))
        trie = Trie(T).empty
        elems.each_slice(BLOCK_SIZE) do |leaf|
          trie = trie.push_leaf(leaf)
        end
        trie
      end

      def self.from(elems : Array(T), owner : UInt64)
        trie = Trie(T).empty(owner)
        elems.each_slice(BLOCK_SIZE) do |leaf|
          trie = trie.push_leaf!(leaf, owner)
        end
        trie
      end

      protected def set(index : Int, value : T, from : UInt64? = nil) : Trie(T)
        child_idx = child_index(index)
        if leaf?
          values = @values.dup.tap { |vs| vs[child_idx] = value }
          Trie.new(values, from)
        else
          children = @children.dup.tap do |cs|
            cs[child_idx] = cs[child_idx].set(index, value)
          end
          Trie.new(children, @levels, from)
        end
      end

      protected def set!(index : Int, value : T, from : UInt64) : Trie(T)
        return set(index, value, from) unless from == @owner
        child_idx = child_index(index)
        if leaf?
          @values[child_idx] = value
        else
          @children[child_idx] = @children[child_idx].set!(index, value, from)
        end
        @size = calculate_size
        self
      end

      private def calculate_size
        if leaf?
          @values.size
        else
          @children.reduce(0) { |sum, child| sum + child.size }
        end
      end

      protected def lookup(index : Int)
        child_idx = child_index(index)
        return @values[child_idx] if leaf?
        @children[child_idx].lookup(index)
      end

      protected def leaf_for(index : Int)
        return self if leaf?
        @children[child_index(index)].leaf_for(index)
      end

      protected def values
        @values
      end

      private def child_index(index)
        (index >> (@levels * BITS_PER_LEVEL)) & INDEX_MASK
      end

      protected def full?
        return @values.size == BLOCK_SIZE if leaf?
        @size >> ((@levels + 1) * BITS_PER_LEVEL) > 0
      end

      # :nodoc:
      class FlattenLeaves(T)
        include Iterator(T)

        @chunk : Iterator(T) | Iterator::Stop

        def initialize(@generator : Iterator(Iterator(T)))
          @chunk = @generator.next
        end

        def next : T | Iterator::Stop
          chunk = @chunk
          if chunk.is_a?(Iterator::Stop)
            Iterator::Stop.new
          else
            elem = chunk.next
            if elem.is_a?(Iterator::Stop)
              @chunk = @generator.next
              self.next
            else
              elem
            end
          end
        end
      end
    end
  end
end

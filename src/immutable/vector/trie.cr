module Immutable
  struct Vector(T)
    struct Trie(T)
      BITS_PER_LEVEL = 5_u32
      BLOCK_SIZE = (2 ** BITS_PER_LEVEL).to_u32
      INDEX_MASK = BLOCK_SIZE - 1

      include Enumerable(T)

      getter :size, :levels

      @children : Array(Trie(T))
      @values   : Array(T)
      @size     : Int32
      @levels   : Int32
      @owner    : UInt64?

      def initialize(@children : Array(Trie(T)), @levels : Int32, @owner = nil : UInt64?)
        @size   = @children.reduce(0) { |size, child| size + child.size }
        @values = [] of T
      end

      def initialize(@values : Array(T), @owner = nil : UInt64?)
        @size     = @values.size
        @levels   = 0
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

      def push(value : T) : Trie(T)
        if full?
          Trie.new([self], @levels + 1).push(value)
        else
          set(@size, value)
        end
      end

      def push!(value : T, from : UInt64) : Trie(T)
        if full?
          Trie.new([self], @levels + 1).push(value)
        else
          set!(@size, value, from)
        end
      end

      def pop
        raise IndexError.new if size == 0
        return Trie.new(@values[0...-1]) if leaf?
        child = @children.last.pop
        if child.empty?
          return @children.first if @children.size == 2
          return Trie.new(@children[0...-1], @levels)
        end
        Trie.new(@children[0...-1].push(child), @levels)
      end

      def pop!(from : UInt64)
        raise IndexError.new if size == 0
        return pop unless from == @owner
        if leaf?
          @values.pop
          return self
        end
        child = @children.last.pop!
        if child.empty?
          return @children.first if @children.size == 2
          @children.pop
        end
        @children[-1] = child
        self
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
        (0...size).step(BLOCK_SIZE).map do |i|
          leaf_for(i).values.each
        end.flatten
      end

      def push_leaf(leaf : Array(T)) : Trie(T)
        raise ArgumentError.new if leaf.size > BLOCK_SIZE || size % 32 != 0
        return Trie.new([self], @levels + 1).push_leaf(leaf) if full?
        return Trie.new(leaf) if empty? && leaf?
        Trie.new(@children.dup.tap do |cs|
          if @levels == 1
            cs.push(Trie.new(leaf))
          else
            if cs.empty? || cs.last.full?
              cs << Trie.new([] of Trie(T), @levels - 1)
            end
            cs[-1] = cs[-1].push_leaf(leaf)
          end
        end, @levels)
      end

      def pop_leaf : Trie(T)
        raise ArgumentError.new if empty? || size % 32 != 0
        return Trie.new([] of T) if leaf?
        child = @children.last.pop_leaf
        if child.empty?
          return @children.first if @children.size == 2
          return Trie.new(@children[0...-1], @levels)
        end
        Trie.new(@children[0...-1].push(child), @levels)
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

      def self.empty
        Trie.new([] of T)
      end

      def self.from(elems : Array(T))
        trie = Trie(T).empty
        elems.each_slice(BLOCK_SIZE) do |leaf|
          trie = trie.push_leaf(leaf)
        end
        trie
      end

      protected def set(index : Int, value : T) : Trie(T)
        child_idx = child_index(index)
        return Trie.new(update_values(child_idx, value)) if leaf?
        Trie.new(update_children(child_idx, value, index), @levels)
      end

      protected def set!(index : Int, value : T, from : UInt64) : Trie(T)
        return set(index, value) unless from == @owner
        child_idx = child_index(index)
        if leaf?
          update_values!(child_idx, value, from)
        else
          update_children!(child_idx, value, index, from)
        end
        self
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

      private def update_children(index : Int, value : T, idx : Int) : Array(Trie(T))
        @children.dup.tap do |cs|
          cs << Trie(T).new([] of Trie(T), @levels - 1) if cs.size == index
          cs[index] = cs[index].set(idx, value)
        end
      end

      private def update_children!(index : Int, value : T, idx : Int, from : UInt64)
        @children << Trie(T).new([] of Trie(T), @levels - 1, @owner) if @children.size == index
        @children[index] = @children[index].set!(idx, value, from)
      end

      private def update_values(index : Int, value : T) : Array(T)
        @values.dup.tap do |vs|
          if vs.size == index
            vs << value
          else
            vs[index] = value
          end
        end
      end

      private def update_values!(index : Int, value : T, from : UInt64)
        if @values.size == index
          @values << value
        else
          @values[index] = value
        end
      end

      protected def full?
        return @values.size == BLOCK_SIZE if leaf?
        @size >> ((@levels + 1) * BITS_PER_LEVEL) > 0
      end
    end
  end
end

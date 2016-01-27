module Immutable
  class Trie(T)
    BITS_PER_LEVEL = 5_u32
    BLOCK_SIZE = (2 ** BITS_PER_LEVEL).to_u32
    INDEX_MASK = BLOCK_SIZE - 1

    getter :size, :levels

    @children : Array(Trie(T))
    @values   : Array(T)
    @size     : Int32
    @levels   : Int32

    def initialize(@children : Array(Trie(T)), @levels : Int32)
      @size   = @children.reduce(0) { |size, child| size + child.size }
      @values = [] of T
    end

    def initialize(@values : Array(T))
      @size     = @values.size
      @levels   = 0
      @children = [] of Trie(T)
    end

    def get(index : Int32)
      raise IndexError.new if index < 0 || index >= size
      lookup(index)
    end

    def update(index : Int32, value : T) : Trie(T)
      raise IndexError.new if index < 0 || index >= size
      set(index, value)
    end

    def push(value : T) : Trie(T)
      if full?
        Trie.new([self], @levels + 1).push(value)
      else
        set(@size, value)
      end
    end

    def push_leaf(leaf : Array(T)) : Trie(T)
      if leaf.size > BLOCK_SIZE
        raise ArgumentError.new("leaf cannot have more than #{BLOCK_SIZE} elements")
      end
      unless size % 32 == 0
        raise ArgumentError.new("cannot push leaf on partially filled tree")
      end
      return Trie.new([self], @levels + 1).push_leaf(leaf) if full?
      return Trie.new(leaf) if empty?
      Trie.new(@children.dup.tap do |cs|
        if @levels > 1
          cs[cs.size - 1] = cs[cs.size - 1].push_leaf(leaf)
        else
          cs.push(Trie.new(leaf))
        end
      end, @levels)
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

    protected def set(index : Int32, value : T) : Trie(T)
      child_idx = child_index(index)
      return Trie.new(update_values(@values, child_idx, value)) if leaf?
      Trie.new(update_children(@children, child_idx, value, index), @levels)
    end

    protected def lookup(index : Int32)
      child_idx = child_index(index)
      return @values[child_idx] if leaf?
      @children[child_idx].lookup(index)
    end

    private def child_index(index)
      (index >> (@levels * BITS_PER_LEVEL)) & INDEX_MASK
    end

    private def update_children(children : Array(Trie(T)), index, value, idx) : Array(Trie(T))
      @children.dup.tap do |cs|
        cs << Trie(T).new([] of Trie(T), @levels - 1) if cs.size == index
        cs[index] = cs[index].set(idx, value)
      end
    end

    private def update_values(values : Array(T), index : Int32, value : T) : Array(T)
      @values.dup.tap do |vs|
        if vs.size == index
          vs << value
        else
          vs[index] = value
        end
      end
    end

    private def full?
      return @values.size == BLOCK_SIZE if leaf?
      @size >> ((@levels + 1) * BITS_PER_LEVEL) > 0
    end
  end
end

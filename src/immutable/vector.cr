module Immutable
  class Vector(T)
    include Enumerable(T)
    include Iterable
    include Comparable(Vector)

    @trie : Trie(T)
    @tail : Array(T)

    def initialize
      @trie = Trie(T).empty
      @tail = [] of T
    end

    def initialize(@trie : Trie(T), @tail : Array(T))
    end

    def initialize(elems : Array(T))
      leaves = elems.size / Trie::BLOCK_SIZE
      @trie = Trie(T).from(elems[0...leaves])
      @tail = elems[leaves..-1]
    end

    def size
      @trie.size + @tail.size
    end

    def each
      @trie.each { |elem| yield elem }
      @tail.each { |elem| yield elem }
      self
    end

    def each
      ItemIterator.new(self)
    end

    def each_index
      i = 0
      while i < size
        yield i
        i += 1
      end
      self
    end

    def push(elem : T)
      new_tail = @tail + [elem]
      if new_tail.size == Immutable::Trie::BLOCK_SIZE
        Vector.new(@trie.push_leaf(new_tail), [] of T)
      else
        Vector.new(@trie, new_tail)
      end
    end

    def <<(elem : T)
      push(elem)
    end

    def [](i : Int)
      at(i)
    end

    def at(i : Int)
      at(i) { raise IndexError.new }
    end

    def at(i : Int)
      i = size + i if i < 0
      return yield if i < 0 || i >= size
      return @tail[i - @trie.size] if in_tail?(i)
      @trie.get(i)
    end

    def first
      self[0]
    end

    def last
      self[-1]
    end

    def equals?(other : Vector)
      return false if size != other.size
      each.zip(other.each).all? do |tuple|
        yield(tuple.first, tuple.last)
      end
    end

    def ==(other : Vector)
      equals?(other) { |x, y| x == y }
    end

    def ==(other)
      false
    end

    def <=>(other : Vector)
      min_size = Math.min(size, other.size)
      each.zip(other.each).each do |tuple|
        n = tuple.first <=> tuple.last
        return n if n != 0
      end
      size <=> other.size
    end

    private def in_tail?(index)
      index >= @trie.size && index < size
    end

    class ItemIterator(T)
      include Iterator(Int32)

      @vector : Vector(T)
      @index : Int32

      def initialize(@vector : Vector(T), @index = 0)
      end

      def next
        value = @vector.at(@index) { stop }
        @index += 1
        value
      end
    end
  end
end

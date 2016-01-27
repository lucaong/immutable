module Immutable
  class Vector(T)
    @trie : Trie(T)
    @tail : Array(T)

    def initialize
      @trie = Trie(T).empty
      @tail = [] of T
    end

    def initialize(@trie : Trie(T), @tail : Array(T))
    end

    def size
      @trie.size + @tail.size
    end

    def each
      each_index do |i|
        yield self[i]
      end
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

    private def [](i : Int)
      raise IndexError.new if i == size || i.abs > size
      i = size - i if i < 0
      return tail[i - @trie.size] if in_tail?(i)
      @trie.get(i)
    end

    private def in_tail?(index)
      index >= @trie.size && index < size
    end
  end
end

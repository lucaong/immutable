# A vector is an ordered, immutable, integer-indexed collection of objects of
# type T.
#
# Similar to an array, vector indexing starts at 0 and negative indexes are
# assumed to be relative to the end of the vector.
#
# A vector can be constructed from an array of its elements:
#
# ```
# Immutable::Vector(Int32).new           # => Vector []
# Immutable::Vector.from([1, 42, 5, 46]) # => Vector [1, 42, 5, 46]
# ```
#
# When a vector is modified, the original remans unchanged and a modified copy
# is returned. However, due to structural sharing, the copy is efficient. This
# makes vector inherently thread-safe and at the same time fast:
#
# ```
# vector = Immutable::Vector.new([1, 2, 3]) # => Vector [1, 2, 3]
# vector.push(4) # => Vector [1, 2, 3, 4]
# vector         # => Vector [1, 2, 3]
# ```
#
# Vector is implemented as a "persistent bit-partitioned vector trie" with a
# ranching factor of 32. This means that updates, appends and lookups are
# performed have a complexity of O(Log32), which for practical purposes is
# effectively equivalent to O(1): in a vector of 1 billion elements these
# operations take no more than 6 steps.
#
module Immutable
  struct Vector(T)
    include Enumerable(T)
    include Iterable
    include Comparable(Vector)

    @trie : Trie(T)
    @tail : Array(T)

    # Creates a new empty vector
    def initialize
      @trie = Trie(T).empty
      @tail = [] of T
    end

    # :nodoc:
    def initialize(@trie : Trie(T), @tail : Array(T))
    end

    # Creates a vector filled with the elements from the given array, in the
    # same position.
    def initialize(elems : Array(T))
      leaves = elems.size / Trie::BLOCK_SIZE
      @trie = Trie(T).from(elems[0...leaves])
      @tail = elems[leaves..-1]
    end

    # Returns the number of elements in the vector
    def size
      @trie.size + @tail.size
    end

    # Calls the given block once for each element in this vector, passing that
    # element as a parameter.
    #
    # ```
    # v = Immutable::Vector.new(["a", "b", "c"])
    # v.each { |x| print x, " -- " }
    # ```
    #
    # produces:
    #
    # ```text
    # a -- b -- c --
    # ```
    def each
      @trie.each { |elem| yield elem }
      @tail.each { |elem| yield elem }
      self
    end

    # Returns an `Iterator` for the elements of this vector.
    #
    # ```
    # v = Immutable::Vector.new(["a", "b", "c"])
    # iter = v.each
    # iter.next # => "a"
    # iter.next # => "b"
    # ```
    def each
      ItemIterator.new(self)
    end


    # Calls the given block once for each index in this vector, passing that
    # index as a parameter.
    #
    # ```
    # v = Immutable::Vector.new(["a", "b", "c"])
    # v.each_index { |x| print x, " -- " }
    # ```
    #
    # produces:
    #
    # ```text
    # 0 -- 1 -- 2 --
    # ```
    def each_index
      i = 0
      while i < size
        yield i
        i += 1
      end
      self
    end

    # Returns a new vector with the given value appended to the end, given that the type of
    # the value is T (which might be a type or a union of types).
    #
    # ```
    # v = Immutable::Vector.new(["a", "b"])
    # v.push("c") # => Vector ["a", "b", "c"]
    # v.push(1)   # => Errors, because the vector only accepts String
    #
    # # The original vector remains unchanged:
    # v           # => Vector ["a", "b"]
    # ```
    def push(elem : T)
      new_tail = @tail + [elem]
      if new_tail.size == Immutable::Trie::BLOCK_SIZE
        Vector.new(@trie.push_leaf(new_tail), [] of T)
      else
        Vector.new(@trie, new_tail)
      end
    end

    # Alias for `push`
    def <<(elem : T)
      push(elem)
    end

    # Returns the element at the given index.
    #
    # Negative indices can be used to start counting from the end of the vector.
    # Raises `IndexError` if trying to access an element outside the vector's range.
    #
    # ```
    # vec = Immutable::Vector.new(['a', 'b', 'c'])
    # vec[0]  # => 'a'
    # vec[2]  # => 'c'
    # vec[-1] # => 'c'
    # vec[-2] # => 'b'
    #
    # vec[3]  # raises IndexError
    # vec[-4] # raises IndexError
    # ```
    def [](i : Int)
      at(i)
    end

    # Returns the element at the given index.
    #
    # Negative indices can be used to start counting from the end of the vector.
    # Returns `nil` if trying to access an element outside the vector's range.
    #
    # ```
    # vec = Immutable::Vector.new(['a', 'b', 'c'])
    # vec[0]?  # => 'a'
    # vec[2]?  # => 'c'
    # vec[-1]? # => 'c'
    # vec[-2]? # => 'b'
    #
    # vec[3]?  # nil
    # vec[-4]? # nil
    # ```
    def []?(i : Int)
      at(i) { nil }
    end

    # Returns the element at the given index, if in bounds,
    # otherwise raises `IndexError`
    #
    # ```
    # v = Immutable::Vector.new([:foo, :bar])
    # v.at(0) { :baz } # => :foo
    # v.at(2) { :baz } # => IndexError
    # ```
    def at(i : Int)
      at(i) { raise IndexError.new }
    end

    # Returns the element at the given index, if in bounds,
    # otherwise executes the given block and returns its value.
    #
    # ```
    # v = Immutable::Vector.new([:foo, :bar])
    # v.at(0) { :baz } # => :foo
    # v.at(2) { :baz } # => :baz
    # ```
    def at(i : Int)
      i = size + i if i < 0
      return yield if i < 0 || i >= size
      return @tail[i - @trie.size] if in_tail?(i)
      @trie.get(i)
    end

    # Returns the first element in the vector, if not empty, else raises
    # `IndexError`
    def first
      self[0]
    end

    # Returns the last element in the vector, if not empty, else raises
    # `IndexError`
    def last
      self[-1]
    end

    # Determines if this vector equals *other* according to a comparison
    # done by the given block.
    #
    # If this vector's size is the same as *other*'s size, this method yields
    # elements from this vector and *other* in tandem: if the block returns true
    # for all of them, this method returns `true`. Otherwise it returns `false`.
    #
    # ```
    # a = Immutable::Vector.new([1, 2, 3])
    # b = Immutable::Vector.new(["a", "ab", "abc"])
    # a.equals?(b) { |x, y| x == y.size } # => true
    # a.equals?(b) { |x, y| x == y }      # => false
    # ```
    def equals?(other : Vector)
      return false if size != other.size
      each.zip(other.each).all? do |tuple|
        yield(tuple.first, tuple.last)
      end
    end

    # Equality. Returns true if it is passed a Vector and `equals?`
    # returns true for both vectors, the caller and the argument.
    #
    # ```
    # vec = Immutable::Vector.new([1, 2, 3])
    # vec == Immutable::Vector.new([1, 2, 3]) # => true
    # vec == Immutable::Vector.new([2, 3])    # => false
    # ```
    def ==(other : Vector)
      equals?(other) { |x, y| x == y }
    end

    # :nodoc:
    def ==(other)
      false
    end

    # Combined comparison operator. Returns 0 if the first vector equals the
    # second, 1 if the first is greater than the second and -1 if the first is
    # smaller than the second.
    #
    # It compares the elements of both vectors in the same position using the
    # `<=>` operator, as soon as one of such comparisons returns a non zero
    # value, that result is the return value of the whole comparison.
    #
    # If all elements are equal, the comparison is based on the size of the
    # vectors.
    #
    # ```
    # Immutable::Vector.new([8]) <=> Immutable::Vector.new([1, 2, 3]) # => 1
    # Immutable::VEctor.new([2]) <=> Immutable::Vector.new([4, 2, 3]) # => -1
    # Immutable::Vector.new([1, 2]) <=> Immutable::Vector.new([1, 2]) # => 0
    # ```
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

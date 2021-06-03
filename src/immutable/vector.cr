# A vector is an ordered, immutable, integer-indexed collection of objects of
# type T.
#
# Similar to an array, vector indexing starts at 0 and negative indexes are
# assumed to be relative to the end of the vector.
#
# A vector can be constructed from an array of its elements:
#
# ```
# Immutable::Vector(Int32).new          # => Vector []
# Immutable::Vector.new([1, 42, 5, 46]) # => Vector [1, 42, 5, 46]
# Immutable::Vector[1, 2, 3]            # => Vector [1, 2, 3]
# ```
#
# When a vector is modified, the original remans unchanged and a modified copy
# is returned. However, due to structural sharing, the copy is efficient. This
# makes vector inherently thread-safe and at the same time fast:
#
# ```
# vector = Immutable::Vector[1, 2, 3] # => Vector [1, 2, 3]
# vector2 = vector.push(4)            # => Vector [1, 2, 3, 4]
# vector                              # => Vector [1, 2, 3]
# ```
#
# Vector is implemented as a "persistent bit-partitioned vector trie" with a
# ranching factor of 32. This means that updates and lookups are performed have
# a complexity of O(Log32), which for practical purposes is effectively
# equivalent to O(1): in a vector of 1 billion elements these operations take no
# more than 6 steps. Due to tail optimization, appends are O(1) 31 times out of
# 32, and O(Log32) 1/32 of times.
require "./vector/trie"

module Immutable
  class Vector(T)
    include Enumerable(T)
    include Iterable(T)
    include Comparable(Vector)

    @trie : Trie(T)
    @tail : Array(T)

    # Alias for `Vector.[]`
    def self.of(*elems : T)
      self[*elems]
    end

    # Creates a new vector from the given arguments
    #
    # ```
    # vec = Immutable::Vector[1, 2, 3, 4]
    def self.[](*elems : T)
      if (elems.size <= Trie::BLOCK_SIZE)
        new(Trie(T).empty, elems.to_a)
      else
        new(elems.to_a)
      end
    end

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
      leaves = elems.size - (elems.size % Trie::BLOCK_SIZE)
      @trie = Trie(T).from(elems[0...leaves], object_id).clear_owner!
      @tail = elems[leaves..-1]
    end

    # Executes the given block passing a transient version of the vector, then
    # converts the transient vector back to an immutable one and returns it.
    #
    # This is useful to perform several updates on a vector in an efficient way:
    # as the transient vector supports the same API of vector, but performs
    # updates in place, avoiding unnecessary object allocations.
    #
    # ```
    # vec = Immutable::Vector(Int32).new
    # v2 = vec.transient do |v|
    #   100.times { |i| v = v.push(i) }
    # end
    # v2.size # => 100
    # ```
    #
    # Note that, as the transient is mutable, it is not thread-safe.
    def transient
      t = Transient.new(@trie, @tail.dup)
      yield t
      t.persist!
    end

    # Returns the number of elements in the vector
    def size
      @trie.size + @tail.size
    end

    # Calls the given block once for each element in this vector, passing that
    # element as a parameter.
    #
    # ```
    # v = Immutable::Vector["a", "b", "c"]
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
    # v = Immutable::Vector["a", "b", "c"]
    # iter = v.each
    # iter.next # => "a"
    # iter.next # => "b"
    # ```
    def each
      @trie.each.chain(@tail.each)
    end

    # Calls the given block once for each index in this vector, passing that
    # index as a parameter.
    #
    # ```
    # v = Immutable::Vector["a", "b", "c"]
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
    # v = Immutable::Vector["a", "b"]
    # v.push("c") # => Vector ["a", "b", "c"]
    # v.push(1)   # => Errors, because the vector only accepts String
    #
    # # The original vector remains unchanged:
    # v # => Vector ["a", "b"]
    # ```
    def push(elem : T)
      new_tail = @tail + [elem]
      if new_tail.size == Trie::BLOCK_SIZE
        Vector.new(@trie.push_leaf(new_tail), [] of T)
      else
        Vector.new(@trie, new_tail)
      end
    end

    # Return a tuple of two things: the last element of the vector and a copy of
    # the vector with the last element removed. Raises `IndexError` if the
    # vector is empty.
    #
    # ```
    # v = Immutable::Vector[1, 2, 3, 4]
    # last, v2 = v.pop
    # last # => 4
    # v2   # => Vector [1, 2, 3]
    # ```
    def pop : Tuple(T, Vector(T))
      vec = drop_last { raise IndexError.new("cannot pop empty vector") }
      {last, vec}
    end

    # Like `pop`, but returns a tuple of nil and empty vector if called on an
    # empty vector
    def pop? : Tuple(T?, Vector(T))
      vec = drop_last { self }
      {last?, vec}
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
    # vec = Immutable::Vector['a', 'b', 'c']
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
    # vec = Immutable::Vector['a', 'b', 'c']
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
    # v = Immutable::Vector[:foo, :bar]
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
    # v = Immutable::Vector[:foo, :bar]
    # v.at(0) { :baz } # => :foo
    # v.at(2) { :baz } # => :baz
    # ```
    def at(i : Int)
      i = size + i if i < 0
      return yield if i < 0 || i >= size
      return @tail[i - @trie.size] if in_tail?(i)
      @trie.get(i)
    end

    # Returns a modified copy of the vector with the element at the given index
    # set to the given value.
    #
    # Negative indices can be used to start counting from the end of the vector.
    # Raises `IndexError` if trying to set an element outside the vector's range.
    #
    # ```
    # vec = Immutable::Vector[1, 2, 3]
    # vec.set(0, 5) # Vector [5, 2, 3]
    # vec           # Vector [1, 2, 3]
    #
    # vec.set(3, 5) # => IndexError
    # ```
    def set(i : Int, value : T)
      i = size + i if i < 0
      raise IndexError.new if i < 0 || i >= size
      if in_tail?(i)
        new_tail = @tail.dup.tap { |t| t[i - @trie.size] = value }
        return Vector.new(@trie, new_tail)
      end
      Vector.new(@trie.update(i, value), @tail)
    end

    # Returns the first element in the vector, if not empty, else raises
    # `IndexError`
    def first
      self[0]
    end

    # Returns the first element in the vector, if not empty, else nil
    def first?
      self[0]?
    end

    # Returns the last element in the vector, if not empty, else raises
    # `IndexError`
    def last
      self[-1]
    end

    # Returns the last element in the vector, if not empty, else nil
    def last?
      self[-1]?
    end

    # Determines if this vector equals *other* according to a comparison
    # done by the given block.
    #
    # If this vector's size is the same as *other*'s size, this method yields
    # elements from this vector and *other* in tandem: if the block returns true
    # for all of them, this method returns `true`. Otherwise it returns `false`.
    #
    # ```
    # a = Immutable::Vector[1, 2, 3]
    # b = Immutable::Vector["a", "ab", "abc"]
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
    # vec = Immutable::Vector[1, 2, 3]
    # vec == Immutable::Vector[1, 2, 3] # => true
    # vec == Immutable::Vector[2, 3]    # => false
    # ```
    def ==(other : Vector)
      return true if @trie.same?(other.trie) && @tail == other.tail
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
    # Immutable::Vector[8] <=> Immutable::Vector[1, 2, 3] # => 1
    # Immutable::Vector[2] <=> Immutable::Vector[4, 2, 3] # => -1
    # Immutable::Vector[1, 2] <=> Immutable::Vector[1, 2] # => 0
    # ```
    def <=>(other : Vector)
      min_size = Math.min(size, other.size)
      each.zip(other.each).each do |tuple|
        n = tuple.first <=> tuple.last
        return n if n != 0
      end
      size <=> other.size
    end

    # Returns true if the vector is empty, else false
    def empty?
      size == 0
    end

    # Returns true if the vector contains at least one element, else false
    def any?
      size != 0
    end

    # Concatenation. Returns a new vector built by concatenating self with
    # other. The type of the new vector is the union of the types of self and
    # other.
    #
    # ```
    # v1 = Immutable::Vector[1, 2]
    # v2 = Immutable::Vector[2, 3]
    # v3 = Immutable::Vector["a"]
    # v1 + v2 # => Vector [1, 2, 2, 3]
    # v1 + v3 # => Vector [1, 2, "a"]
    # ```
    def +(other : Vector(U)) forall U
      trie = @trie.as(Trie(T | U))
      tail = @tail.as(Array(T | U))
      other.each_slice(Trie::BLOCK_SIZE) do |slice|
        leaf_tail = (tail + slice)
        trie = trie.push_leaf!(leaf_tail.first(Trie::BLOCK_SIZE), object_id)
        tail = leaf_tail.skip(Trie::BLOCK_SIZE)
      end
      Vector.new(trie.clear_owner!, tail)
    end

    # Difference. Returns a new vector that is a copy of the original, removing
    # any items that appear in `other`. The order of the original vector is
    # preserved.
    #
    # ```
    # v1 = Immutable::Vector[1, 2, 3]
    # v2 = Immutable::Vector[2, 1]
    # v1 - v2 => Vector [3]
    # ```
    def -(other : Vector(_))
      set = other.to_lookup_set
      elems = reject do |elem|
        set.includes?(elem)
      end
      Vector(T).new(elems)
    end

    # Set intersection: returns a new array containing elements common to the two
    # vectors, excluding any duplicates. The order is preserved from the original
    # vector.
    #
    # ```
    # v1 = Immutable::Vector[1, 1, 3, 5]
    # v2 = Immutable::Vector[1, 2, 3]
    # v1 & v2 # => Vector [1, 3]
    # ```
    def &(other : Vector(_))
      return Vector(T).new if empty? || other.empty?
      set = other.to_lookup_set
      intersection = self.select do |elem|
        in_set = set.includes?(elem)
        set.delete(elem)
        in_set
      end
      Vector(T).new(intersection)
    end

    # Set union: returns a new vector by joining self with other, excluding
    # any duplicates and preserving the order from the original vector.
    #
    # ```
    # v1 = Immutable::Vector["a", "b", "c"]
    # v2 = Immutable::Vector["c", "d", "a"]
    # v1 | v2 # => Vector [1, 3] # => Vector ["a", "b", "c", "d"]
    # ```
    def |(other : Vector(U)) forall U
      set = Set(T | U).new
      union = reduce([] of T | U) do |union, elem|
        union << elem unless set.includes?(elem)
        set.add(elem)
        union
      end
      union = other.reduce(union) do |union, elem|
        union << elem unless set.includes?(elem)
        set.add(elem)
        union
      end
      Vector(T | U).new(union)
    end

    # Returns a new vector by removing duplicate values in self.
    #
    # ```
    # v = Immutable::Vector["a", "a", "b", "b", "c"]
    # v.uniq # => Vector ["a", "b", "c"]
    # v      # => Vector ["a", "a", "b", "b", "c"]
    # ```
    def uniq
      hash = {} of T => Bool
      elems = reject do |elem|
        next true if in_hash = hash.has_key?(elem)
        hash[elem] = true
        in_hash
      end
      Vector(T).new(elems)
    end

    # Appends a String representation of this vector
    # to the given IO object.
    def to_s(io : IO)
      io << "Vector "
      to_a.to_s(io)
    end

    # Appends a JSON string representation of this vector to the given
    # io object
    def to_json(json : JSON::Builder)
      json.array do
        each &.to_json(json)
      end
    end

    # Appends a `String` representation of this object to the given IO object.
    def inspect(io : IO)
      to_s(io)
    end

    # Returns a hash code based on this vector's size and elements.
    #
    # See `Object#hash`.
    def hash
      reduce(41 &* size) do |memo, elem|
        41 &* memo &+ elem.hash
      end
    end

    private def in_tail?(index)
      index >= @trie.size && index < size
    end

    private def drop_last
      return yield if empty?
      return Vector.new(@trie.pop_leaf, @trie.last_leaf) if @tail.size == 1 && size > 1
      Vector.new(@trie, @tail[0...-1])
    end

    protected def to_lookup_set
      reduce(Set(T).new) do |set, elem|
        set.add(elem)
      end
    end

    protected def trie
      @trie
    end

    protected def tail
      @tail
    end

    class Transient(T) < Vector(T)
      @valid : Bool

      def initialize(@trie : Trie(T), @tail : Array(T))
        @valid = true
      end

      def initialize
        @trie = Trie(T).empty(object_id)
        @tail = Array(T).new(Trie::BLOCK_SIZE)
        @valid = true
      end

      def initialize(elems : Array(T))
        leaves = elems.size - (elems.size % Trie::BLOCK_SIZE)
        @trie = Trie(T).from(elems[0...leaves], object_id)
        @tail = elems[leaves..-1]
        @valid = true
      end

      def persist!
        @trie.clear_owner!
        @valid = false
        Vector.new(@trie, @tail.dup)
      end

      def push(elem : T)
        check_validity!
        @tail << elem
        if @tail.size == Trie::BLOCK_SIZE
          @trie = @trie.push_leaf!(@tail, object_id)
          @tail = Array(T).new(Trie::BLOCK_SIZE)
        end
        self
      end

      def pop : Tuple(T, Transient(T))
        check_validity!
        raise IndexError.new("cannot pop empty vector") if empty?
        {last, drop_last { self }}
      end

      def pop? : Tuple(T?, Transient(T))
        check_validity!
        {last?, drop_last { self }}
      end

      def set(i : Int, value : T)
        check_validity!
        i = size + i if i < 0
        raise IndexError.new if i < 0 || i >= size
        if in_tail?(i)
          @tail[i - @trie.size] = value
        else
          @trie = @trie.update!(i, value, object_id)
        end
        self
      end

      private def drop_last
        return yield if empty?
        if @tail.size == 1 && size > 1
          @tail = @trie.last_leaf
          @trie = @trie.pop_leaf!(object_id)
        else
          @tail.pop
        end
        self
      end

      private def check_validity!
        unless @valid
          raise Invalid.new("Attempt to use transient vector after persisting it")
        end
      end

      class Invalid < Exception; end
    end
  end
end

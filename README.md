[![Build Status](https://travis-ci.org/lucaong/immutable.svg?branch=master)](https://travis-ci.org/lucaong/immutable)

# Immutable

Efficient, thread-safe immutable data structures for Crystal.

Whenever an `Immutable` data structure is "modified", the original remains
unchanged and a modified copy is returned. However, the copy is efficient due to
structural sharing. This makes `Immutable` data structures inherently
thread-safe, garbage collector friendly and performant.

At the moment, `Immutable` implements the following persistent data structures:

  - `Immutable::Vector`: array-like ordered, integer-indexed collection
  implementing efficient append, pop, update and lookup operations
  - `Immutable::Map`: hash-like unordered key-value collection implementing
  efficient lookup and update operations


## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  immutable:
    github: lucaong/immutable
```


## Usage

For a list of all classes and methods refer to the [API documentation](http://lucaong.github.io/immutable/api/)

To use the immutable collections, require `immutable` in your code:

```crystal
require "immutable"
```

### Vector ([API docs](http://lucaong.github.io/immutable/api/Immutable/Vector.html))

```crystal
# Vector behaves mostly like an Array:
vector = Immutable::Vector[1, 2, 3, 4, 5]  # => Vector [1, 2, 3, 4, 5]
vector[0]                                  # => 1
vector[-1]                                 # => 5
vector.size                                # => 5
vector.each { |elem| puts elem }

# Updating a Vector always returns a modified copy:
vector2 = vector.set(2, 0)                 # => Vector [1, 2, 0, 4, 5]
vector2 = vector2.push(42)                 # => Vector [1, 2, 0, 4, 5, 42]

# The original vector is unchanged:
vector                                     # => Vector [1, 2, 3, 4, 5]

# Bulk updates can be made faster by using `transient`:
vector3 = vector.transient do |v|
  1000.times { |i| v = v.push(i) }
end
```

### Map ([API docs](http://lucaong.github.io/immutable/api/Immutable/Map.html))

```crystal
# Map behaves mostly like a Hash:
map = Immutable::Map[{ foo: 1, bar: 2 }]   # => Map {foo: 1, bar: 2}
map[:foo]                                  # => 1

# Updating a Map always returns a modified copy:
map2 = map.set(:baz, 3)                    # => Map {foo: 1, bar: 2, baz: 3}
map2 = map2.delete(:bar)                   # => Map {foo: 1, baz: 3}

# The original map in unchanged:
map                                        # => Map {foo: 1, bar: 2}

# Bulk updates can be made faster by using `transient`:
map3 = map.transient do |m|
  1000.times { |i| m = m.set(i.to_sym, i) }
end
```

### Nested structures

```crystal
# Nested arrays/hashes can be turned into immutable versions with the `.from`
# method:

nested = Immutable.from({ name: "Ada", colors: [:blue, :green, :red] })
nested # => Map {:name => "Ada", :colors => Vector [:blue, :green, :red]}
```


## Implementation

`Immutable::Vector` is implemented as a bit-partitioned vector trie with a block
size of 32 bits, that guarantees O(Log32) lookups and updates, which is
effectively constant time for practical purposes. Due to tail optimization,
appends and pop are O(1) 31 times out of 32, and O(Log32) 1/32 of the times.

`Immutable::Map` uses a bit-partitioned hash trie with a block size of 32 bits,
that also guarantees O(Log32) lookups and updates.


## Contributing

1. Fork it ( https://github.com/lucaong/immutable/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request


## Contributors

- [lucaong](https://github.com/lucaong) Luca Ongaro - creator, maintainer


## Acknowledgement

Although not a port, this project takes inspiration from similar libraries and
persistent data structure implementations like:

  - [Clojure persistent collections](http://clojure.org/reference/data_structures)
  - [The Hamster gem for Ruby](https://github.com/hamstergem/hamster)

When researching on the topic of persistent data structure implementation, these
blog posts have been of great help:

  - [Understanding Clojure's Persistent Vector](http://hypirion.com/musings/understanding-persistent-vector-pt-1) (also [Part 2](http://hypirion.com/musings/understanding-persistent-vector-pt-2), [Part 3](http://hypirion.com/musings/understanding-persistent-vector-pt-3) and [Understanding Clojure's Transients](http://hypirion.com/musings/understanding-clojure-transients))
  - [Understanding Clojure's Persistent Hash Map](http://blog.higher-order.net/2009/09/08/understanding-clojures-persistenthashmap-deftwice.html)

Big thanks to their authors for the great job explaining the internals of these
data structures.

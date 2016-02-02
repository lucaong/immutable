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

TODO:

  - `Immutable::Set`: unordered collection without duplicates


## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  immutable:
    github: lucaong/immutable
```


## Usage

For a list of all classes and methods refer to the [API documentation](http://lucaong.github.io/immutable/api/)

```crystal
require "immutable"

# Vector
vector = Immutable.vector([1, 2, 3, 4, 5]) # => Vector [1, 2, 3, 4, 5]
other  = vector.set(2, 0).push(42)         # => Vector [1, 2, 0, 4, 5, 42]
other[2]                                   # => 0

other.each do |elem|
  puts elem
end

# The original vector is unchanged:
vector                                     # => Vector [1, 2, 3, 4, 5]

# Map
map = Immutable.map({ foo: 1, bar: 2 })    # => Map {foo: 1, bar: 2}
map.set(:baz, 3)                           # => Map {foo: 1, bar: 2, baz: 3}

# The original map in unchanged:
map                                        # => Map {foo: 1, bar: 2}
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

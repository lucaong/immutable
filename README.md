[![Build Status](https://travis-ci.org/lucaong/immutable.svg?branch=master)](https://travis-ci.org/lucaong/immutable)

# Immutable

Efficient, thread-safe immutable data structures for Crystal.

Whenever you modify an `Immutable` data structure, the original remains
unchanged and a modified copy is returned. However, the copy is efficient due to
structural sharing. This makes `Immutable` data structures inherently
thread-safe and at the same time fast.


## Project status

At the moment, `Immutable` implements the following persistent data structures:

  - `Vector`: Array-like ordered, integer-indexed collection implementing
    efficient appends, updates and lookups

TODO:

  - `Map` - Hash-like key-value collection
  - `Set` - Unordered collection without duplicates


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

vector = Immutable::Vector.new([1, 2, 3, 4, 5]) # => Vector [1, 2, 3, 4, 5]
other  = vector.set(2, 0).push(42)              # => Vector [1, 2, 0, 4, 5, 42]
other[2]                                        # => 0

# The original vector is unchanged
vector                                          # => Vector [1, 2, 3, 4, 5]
```


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
implementations like:

  - [Clojure persistent collections](http://clojure.org/reference/data_structures)
  - [The Hamster gem for Ruby](https://github.com/hamstergem/hamster)

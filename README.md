# Immutable

Efficient, thread-safe immutable collections for Crystal.

Whenever you modify an `Immutable` collection, the original remains unchanged
and a modified copy is returned. However, the copy is efficient due to
structural sharing. This makes `Immutable` collections inherently thread-safe
and at the same time fast.


## Project status

At the moment, `Immutable` implements the following persistent data structures:

  - `Vector` - Efficient append, update and lookup


## Acknowledgement

Although not a port, this project takes inspiration from similar libraries and
implementations like [Clojure persistent
collections](http://clojure.org/reference/data_structures) and the [hamster gem
for Ruby](https://github.com/hamstergem/hamster)


## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  immutable:
    github: lucaong/immutable
```


## Usage

```crystal
require "immutable"

vector = Immutable::Vector.from([1, 2, 3, 4, 5])
other  = vector.push(42)
```


## Contributing

1. Fork it ( https://github.com/lucaong/immutable/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [lucaong](https://github.com/lucaong) Luca Ongaro - creator, maintainer

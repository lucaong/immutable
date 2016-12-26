require "./immutable/*"

module Immutable
  # Construct an `Immutable::Vector` of the given elements
  def self.vector(elements : Array(T)) forall T
    Vector.new(elements)
  end

  # Construct an `Immutable::Map` of the given key-values
  def self.map(keyvals : Hash(K, V)) forall K, V
    Map.new(keyvals)
  end

  # Recursively traverses the given object and turns hashes into
  # `Immutable::Map` and arrays into `Immutable::Vector`
  def self.from(object)
    case object
    when Array
      Vector.new(object.map { |elem| from(elem) })
    when Hash
      Map.new(object.map { |k, v| {k, from(v)} })
    else
      object
    end
  end
end

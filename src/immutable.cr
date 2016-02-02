require "./immutable/*"

module Immutable
  # Construct an `Immutable::Vector` of the given elements
  def self.vector(elements : Array(T))
    Vector.new(elements)
  end

  # Construct an `Immutable::Map` of the given key-values
  def self.map(keyvals : Hash(K, V))
    Map.new(keyvals)
  end
end

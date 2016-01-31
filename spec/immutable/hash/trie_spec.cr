require "../../spec_helper"

describe Immutable::Hash::Trie do
  empty_trie = Immutable::Hash::Trie(Symbol, Int32).empty

  describe "#set and #get" do
    t = empty_trie.set(:foo, 1)
    t.get(:foo).should eq(1)
  end
end

require "./spec_helper"

describe Immutable do

  describe Immutable::Trie do
    empty_trie = Immutable::Trie(Int32).empty

    trie = (0...50).reduce(empty_trie) do |trie, i|
      trie.push(i)
    end

    describe "#size" do
      it "returns the number of elements in the trie" do
        empty_trie.size.should eq(0)
        trie.size.should eq(50)
      end
    end

    describe "#get" do
      it "gets the element with the given index" do
        trie.get(0).should eq(0)
        trie.get(3).should eq(3)
        trie.get(49).should eq(49)
      end

      it "raises IndexError when accessing out of range" do
        expect_raises(IndexError) do
          trie.get(trie.size)
        end

        expect_raises(IndexError) do
          trie.get(-1)
        end
      end
    end

    describe "#update" do
      it "returns a modified copy of the trie" do
        t = trie.update(0, -1)
        t.get(0).should eq(-1)
        t.should_not be(trie)
      end

      it "does not modify the original" do
        trie.update(0, -1)
        trie.get(0).should eq(0)
      end

      it "raises IndexError when updating elements out of range" do
        expect_raises(IndexError) do
          trie.update(trie.size, -1)
        end

        expect_raises(IndexError) do
          trie.update(-1, -1)
        end
      end
    end

    describe "#push" do
      it "return a copy of the trie with the given value appended" do
        t = empty_trie.push(1)
        t.get(0).should eq(1)
        t.size.should eq(1)
        t.should_not be(empty_trie)
      end

      it "does not modify the original" do
        t = empty_trie.push(1)
        empty_trie.size.should eq(0)
      end
    end
  end
end

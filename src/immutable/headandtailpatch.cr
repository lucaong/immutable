# A naive patch to offer head/tail destructuring.
# This adds `uncons` `head` `tail` `head?` `tail?`
# Performance is not 100% naive-level,
# but it is not going to blow you away either.
# 
# Basically, it will walk the "left side" of the trie and
# update that path only when copying a vector.
#
# Example use:
#    head, tail = test_vector.uncons
#    puts "HEAD: #{head}"
#    while tail != nil
#        list = tail.not_nil!
#        head, tail = list.uncons
#        puts "HEAD: #{head}" if head != nil
#        #if list != nil
#            #list.not_nil!.dump
#        #end
#    end
#

module Immutable

  class Vector(T)
    def dump
        trie.dump 0
        print "tail: "
        @tail.each do |v|
            print "#{v},"
        end
        puts ""
    end

    def uncons
        h = head?
        t = tail?
        { h, t }
    end

    def head
        h = trie.head?
        return h if h != nil
        return @tail[0] if @tail.size > 0
        raise IndexError.new "Empty list makes for a sad head"
    end

    def head?
        h = trie.head?
        return h if h != nil
        return @tail[0] if @tail.size > 0
        nil
    end

    def tail
        Vector(T).new(trie.tail.not_nil!, @tail)
    end

    def tail?
        t = trie.tail?
        if t == nil
            return nil if @tail.size == 0
            Vector(T).new(Trie(T).empty, @tail[1..-1])
        else
            Vector(T).new(t.not_nil!, @tail)
        end
    end

    class Trie(T)
        getter :children

        def dump(increment)
            print " " * increment * 2
            puts "size: #{@size} children: #{@children.size} values: #{@values.size} levels: #{@levels}"
            print " " * increment * 2
            @values.each do |v| print "#{v}," end
            puts ""
            @children.each do |c| c.dump(increment + 1) end
        end

        # TODO Check object_id are same thus re using reference

        def void?
            @children.size == 0 && @values.size == 0
        end

        def appendchild(c)
            @children.push(c)
            @size += c.size
        end

        def valuetailonly
            return { false, nil } if @values.size <= 1
            c = Trie(T).new(@values[1..-1], @owner)
            { true, c }
        end

        def head?
            if @values.size == 0
                if @children.size == 0
                    nil
                else
                    @children[0].head?
                end
            else
                @values[0]
            end
        end

        # create new trie but preserve most references
        def tail
            raise IndexError.new "Empty list has no tail" if @children.size == 0
            _, r = rtail(self)
            r
        end

        def tail?
            nil if @children.size == 0
            _, r = rtail(self)
            r
        end

        def rtail(trie)
            if trie.children.size == 0
                trie.valuetailonly
            else
                t = Trie(T).empty
                result, headchild = rtail(trie.children[0])
                t.appendchild headchild.not_nil! if result == true
                trie.children[1..-1].each do |c|
                    t.appendchild c
                end
                if t.void?
                    { false, t }
                else
                    { true, t }
                end
            end
        end

    end
  end
end

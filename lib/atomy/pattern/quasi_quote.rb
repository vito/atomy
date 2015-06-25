require "atomy/pattern"

require "atomy/node/meta"
require "atomy/pattern/equality"


class Atomy::Pattern
  class QuasiQuote < self
    attr_reader :node

    def self.patterns_through(mod, node)
      constructor = Constructor.new(mod)
      constructor.go(node)
    end

    def self.make(mod, node)
      new(mod.evaluate(patterns_through(mod, node)))
    end

    def initialize(node)
      @node = node
    end

    def matches?(val)
      MatchWalker.new.go(@node, val)
    end

    private

    class Walker
      def initialize
        @depth = 0
      end

      def go(x)
        x.accept(self)
      end

      def visit_quasiquote(qq)
        @depth += 1
        visit(qq)
      ensure
        @depth -= 1
      end

      def visit_unquote(x)
        @depth -= 1

        if @depth == 0
          unquote(x)
        else
          visit(x)
        end
      ensure
        @depth += 1
      end

      def unquote(_)
        raise NotImplementedError
      end

      def push_literal(x)
        case x
        when Array
          x.each { |v| push_literal(v) }
          @gen.make_array(x.size)
        when String
          @gen.push_literal(x)
          @gen.string_dup
        else
          @gen.push_literal(x)
        end
      end

      def unsplat(pats)
        if pats.last.is_a?(Atomy::Grammar::AST::Unquote) && \
            pats.last.node.is_a?(Atomy::Pattern::Splat)
          [pats[0..-2], pats[-1]]
        else
          [pats, nil]
        end
      end
    end

    class Constructor < Walker
      def initialize(mod)
        super()

        @module = mod
      end

      def go(x)
        x.accept(self)
      end

      def visit(x)
        x.through do |v|
          go(v)
        end
      end

      def unquote(x)
        x.through do |p|
          @module.pattern(p)
        end
      end
    end

    class MatchWalker
      def go(a, b)
        if a.is_a?(Atomy::Pattern)
          a.matches?(b)
        elsif b.is_a?(a.class)
          a.each_attribute do |attr, val|
            return false unless val == b.send(attr)
          end

          a.each_child do |attr, val|
            theirval = b.send(attr)

            if val.is_a?(Array) # TODO test that theirval is an array too
              return false unless go_array(val, theirval)
            else
              return false unless go(val, b.send(attr))
            end
          end

          true
        else
          false
        end
      end

      def go_array(as, bs)
        splat = nil
        req_size = 0
        as.each do |a|
          if a.is_a?(Atomy::Pattern::Splat)
            splat = a
            break
          end

          req_size += 1
        end

        if splat
          return false unless bs.size >= req_size
        else
          return false unless bs.size == req_size
        end

        req_size.times do |i|
          return false unless go(as[i], bs[i])
        end

        if splat
          return false unless splat.matches?(bs[req_size..-1])
        end

        true
      end
    end
  end
end

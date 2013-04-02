require "atomy/pattern"

require "atomy/node/meta"
require "atomy/pattern/equality"


class Atomy::Pattern
  class QuasiQuote < self
    attr_reader :node

    def self.make(mod, node)
      new(Constructor.new(mod).go(node))
    end

    def initialize(node)
      @node = node
    end

    def matches?(gen)
      mismatch = gen.new_label
      done = gen.new_label

      Matcher.new(gen, mismatch).go(@node)

      gen.push_true
      gen.goto done

      mismatch.set!
      gen.push_false

      done.set!
    end

    def deconstruct(gen)
      Deconstructor.new(gen).go(@node)
    end

    def precludes?(other)
      if other.is_a?(self.class)
        PrecludeChecker.new.go(@node, other.node)
      elsif other.is_a?(Equality) && other.value.is_a?(Atomy::Grammar::AST::Node)
        PrecludeChecker.new(false).go(@node, other.value)
      else
        false
      end
    end

    def binds?
      Binds.new.go(@node)
    end

    private

    class PrecludeChecker
      def initialize(quasi = true)
        @quasi = quasi
        @depth = 1
      end

      def go(a, b)
        a_quotes = a.is_a?(Atomy::Grammar::AST::Unquote)
        b_quotes = b.is_a?(Atomy::Grammar::AST::Unquote)

        @depth -= 1 if a_quotes

        if @quasi && a_quotes && b_quotes && @depth == 0
          a.node.precludes?(b.node)
        elsif @quasi && b_quotes && @depth == 0
          false
        elsif a_quotes && @depth == 0
          a.node.precludes?(Equality.new(b))
        elsif b.is_a?(a.class)
          a.each_attribute do |attr, val|
            return false unless val == b.send(attr)
          end

          a.each_child do |attr, val|
            return false unless go(val, b.send(attr))
          end

          true
        else
          false
        end
      ensure
        @depth += 1 if a_quotes
      end
    end

    class Walker
      def initialize
        @depth = 1
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
        x.through { |p| @module.pattern(p) }
      end
    end

    class Matcher < Walker
      def initialize(gen, mis)
        super()
        @gen = gen
        @mismatch = mis
      end

      def go(x, mismatch = nil)
        if mismatch
          old, @mismatch = @mismatch, mismatch
        end

        super(x)
      ensure
        @mismatch = old if mismatch
      end

      def match_kind(x, mismatch)
        @gen.dup
        push_class(@gen, x.class)
        @gen.swap
        @gen.kind_of
        @gen.gif mismatch
      end

      def push_class(gen, klass)
        gen.push_cpath_top
        klass.name.split("::").each do |name|
          gen.find_const(name.to_sym)
        end
      end

      def match_attribute(n, val, mismatch)
        @gen.dup
        @gen.send(n, 0)
        push_literal(val)
        @gen.send(:==, 1)
        @gen.gif mismatch
      end

      def match_required(c, pat, mismatch)
        @gen.dup
        @gen.send(c, 0)
        go(pat, mismatch)
      end

      def match_many(c, pats, popmis, popmis2)
        @gen.dup
        @gen.send c, 0

        if pats.last.is_a?(Atomy::Grammar::AST::Unquote) && \
            pats.last.node.is_a?(Atomy::Pattern::Splat)
          splat = pats[-1]
          pats = pats[0..-2]
        end

        @gen.dup
        @gen.send :size, 0
        @gen.push_int(pats.size)
        @gen.send(splat ? :>= : :==, 1)
        @gen.gif popmis2

        pats.each do |pat|
          @gen.shift_array
          go(pat, popmis2)
        end

        if splat
          go(splat, popmis)
        else
          @gen.pop
        end
      end

      # effect on the stack: pop
      def visit(x)
        popmis = @gen.new_label
        popmis2 = @gen.new_label
        done = @gen.new_label

        match_kind(x, popmis)

        x.each_attribute do |a, val|
          match_attribute(a, val, popmis)
        end

        x.each_child do |c, val|
          if val.is_a?(Array)
            match_many(c, val, popmis, popmis2)
          else
            match_required(c, val, popmis)
          end
        end

        @gen.goto done

        popmis2.set!
        @gen.pop

        popmis.set!
        @gen.pop
        @gen.goto @mismatch

        done.set!
        @gen.pop
      end

      def unquote(x)
        x.node.matches?(@gen)
        @gen.gif @mismatch
      end
    end

    class Deconstructor < Walker
      def initialize(gen)
        super()
        @gen = gen
      end

      def unquote(x)
        x.node.deconstruct(@gen)
      end

      def visit(x)
        x.each_child do |c, val|
          if val.is_a?(Array)
            visit_many(c, val)
          else
            visit_one(c, val)
          end
        end
      end

      def visit_one(c, pat)
        return unless binds?(pat)

        @gen.dup
        @gen.send(c, 0)
        go(pat)
        @gen.pop
      end

      def visit_many(c, pats)
        return if pats.empty?
        return if pats.none? { |p| binds?(p) }

        @gen.dup
        @gen.send(c, 0)

        if pats.last.is_a?(Atomy::Grammar::AST::Unquote) && \
            pats.last.node.is_a?(Atomy::Pattern::Splat)
          splat = pats[-1]
          pats = pats[0..-2]
        end

        pats.each do |pat|
          @gen.shift_array
          go(pat)
          @gen.pop
        end

        go(splat) if splat

        @gen.pop
      end

      def binds?(node)
        Binds.new(@depth).go(node)
      end
    end

    class Binds < Walker
      def initialize(depth = 1)
        @depth = depth
      end

      def unquote(u)
        u.node.binds?
      end

      def visit(x)
        x.through do |v|
          return true if go(v)
        end

        false
      end
    end
  end
end

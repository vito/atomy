module Atomy::Patterns
  class QuasiQuote < Pattern
    attributes(:quoted)

    def initialize(x)
      @quoted = x
    end

    def construct(g, mod)
      get(g)
      @quoted.construct(g, mod)
      g.send :new, 1
      g.push_cpath_top
      g.find_const :Atomy
      g.send :current_module, 0
      g.send :in_context, 1
    end

    def expression
      @quoted.expression
    end

    def target(g, mod)
      expression.get(g)
    end

    def matches?(g, mod)
      mismatch = g.new_label
      done = g.new_label

      Matcher.new(g, mod, mismatch).go(@quoted.expression)

      g.push_true
      g.goto done

      mismatch.set!
      g.push_false

      done.set!
    end

    def deconstruct(g, mod, locals = {})
      Deconstructor.new(g, mod).go(@quoted.expression)
    end

    def local_names
      names = Set.new

      @quoted.through_quotes(proc { true }) do |e|
        names += e.pattern.local_names
        e
      end

      names
    end

    def binds?
      @quoted.through_quotes(proc { true }) do |e|
        return true if e.pattern.binds?
        e
      end

      false
    end

    class Walker
      def initialize(g, mod)
        @depth = 1
        @g = g
        @module = mod
      end

      def go(x, mismatch = nil)
        if mismatch
          old, @mismatch = @mismatch, mismatch
        end

        x.accept self
      ensure
        @mismatch = old if mismatch
      end

      def quasiquote(qq)
        @depth += 1
        visit(qq)
        @depth -= 1
      end

      def unquote(qq)
        raise "unquote not overridden"
      end

      def splice(x)
        raise "splice unquote outside of list context"
      end

      def push_literal(x)
        case x
        when Array
          x.each do |v|
            push_literal(x)
          end
          @g.make_array x.size
        else
          @g.push_literal x
        end
      end
    end

    class Matcher < Walker
      def initialize(g, mod, mis)
        super(g, mod)
        @mismatch = mis
      end

      def match_kind(x, mismatch)
        @g.dup
        x.get(@g)
        @g.swap
        @g.kind_of
        @g.gif mismatch
      end

      def match_attribute(x, n, mismatch)
        @g.dup
        @g.send n, 0
        push_literal x.send(n)
        @g.send :==, 1
        @g.gif mismatch
      end

      def match_required(x, c, mismatch)
        @g.dup
        @g.send c, 0
        go(x.send(c), mismatch)
      end

      def match_many(x, c, popmis, popmis2)
        pats = x.send(c)

        if pats.last && pats.last.splice?
          splice = pats.last
          pats = pats[0..-2]
        end

        defaults = 0
        pats.reverse_each do |p|
          if p.unquote? && p.expression.pattern.is_a?(Default)
            defaults += 1
          else
            break
          end
        end

        required = pats.size - defaults

        # do we care about size?
        inexact = splice || defaults > 0

        @g.dup
        @g.send c, 0

        unless inexact && required == 0
          @g.dup
          @g.send :size, 0
          @g.push_int required
          @g.send(inexact ? :>= : :==, 1)
          @g.gif popmis2
        end

        required.times do |i|
          @g.shift_array
          go(pats[i], popmis2)
        end

        defaults.times do |i|
          d = pats[required + i]

          has = @g.new_label
          match = @g.new_label

          @g.dup
          @g.send :size, 0
          @g.push_int(i + 1)
          @g.send :>=, 1
          @g.git has

          @module.compile(@g, d.expression.pattern.default)
          @g.goto match

          has.set!
          @g.shift_array

          match.set!
          go(d, popmis2)
        end

        if splice
          splice.expression.pattern.matches?(@g, @module)
          @g.gif popmis
        else
          @g.pop
        end
      end

      # effect on the stack: pop
      def visit(x)
        popmis = @g.new_label
        popmis2 = @g.new_label
        done = @g.new_label

        childs = x.class.children

        match_kind(x, popmis)

        x.attribute_names.each do |a|
          match_attribute(x, a, popmis)
        end

        childs[:required].each do |c|
          match_required(x, c, popmis)
        end

        childs[:many].each do |c|
          match_many(x, c, popmis, popmis2)
        end

        # TODO: optionals

        @g.goto done

        popmis2.set!
        @g.pop

        popmis.set!
        @g.pop
        @g.goto @mismatch

        done.set!
        @g.pop
      end

      def unquote(x)
        @depth -= 1

        if @depth == 0
          x.expression.pattern.matches?(@g, @module)
          @g.gif @mismatch
        else
          visit(x)
        end

        @depth += 1
      end
    end

    class Deconstructor < Walker
      def unquote(x)
        @depth -= 1

        if @depth == 0
          x.expression.pattern.deconstruct(@g, @module)
        else
          visit(x)
        end

        @depth += 1
      end

      # effect on the stack: pop
      def visit(x)
        # TODO: optionals

        x.class.children[:required].each do |c|
          @g.dup
          @g.send c, 0
          go(x.send(c))
        end

        x.class.children[:many].each do |c|
          pats = x.send(c).dup

          if pats.last && pats.last.splice?
            splice = pats.pop
          end

          # TODO: only handle trailing defaults
          defaults, required = pats.partition do |x|
            x.unquote? && x.expression.pattern.is_a?(Default)
          end

          @g.dup
          @g.send c, 0

          required.each do |p|
            @g.shift_array
            go(p)
          end

          defaults.each.with_index do |d, i|
            has = @g.new_label
            match = @g.new_label

            @g.dup
            @g.send :size, 0
            @g.push_int(i + 1)
            @g.send :>=, 1
            @g.git has

            @module.compile(@g, d.expression.pattern.default)
            @g.goto match

            has.set!
            @g.shift_array

            match.set!
            go(d)
          end

          if splice
            splice.expression.pattern.deconstruct(@g, @module)
          else
            @g.pop
          end
        end

        @g.pop
      end
    end
  end
end

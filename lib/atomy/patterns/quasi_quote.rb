module Atomy::Patterns
  class QuasiQuote < Pattern
    attributes(:quoted)
    generate

    def initialize(x)
      @quoted = x.through_quotes(proc { true }) do |e|
        e.to_pattern.to_node
      end
    end

    def construct(g, mod)
      get(g)
      @quoted.construct(g, mod)
      g.send :new, 1
      g.dup
      g.push_cpath_top
      g.find_const :Atomy
      g.send :current_module, 0
      g.send :in_context, 1
      g.pop
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
        names += e.to_pattern.local_names
        e
      end

      names
    end

    def binds?
      @quoted.through_quotes(proc { true }) do |e|
        return true if e.to_pattern.binds?
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

      # effect on the stack: pop
      def visit(x)
        popmis = @g.new_label
        popmis2 = @g.new_label
        done = @g.new_label

        @g.dup
        x.get(@g)
        @g.swap
        @g.kind_of
        @g.gif popmis

        x.details.each do |n|
          @g.dup
          @g.send n, 0
          push_literal x.send(n)
          @g.send :==, 1
          @g.gif popmis
        end

        # TODO: optionals

        x.class.children[:required].each do |c|
          @g.dup
          @g.send c, 0
          go(x.send(c), popmis)
        end

        x.class.children[:many].each do |c|
          pats = x.send(c).dup

          if pats.last && pats.last.splice?
            splice = pats.pop
          end

          # TODO: only handle trailing defaults
          defaults, required = pats.partition do |x|
            x.unquote? && x.expression.to_pattern.is_a?(Default)
          end

          # do we care about size?
          inexact = splice || !defaults.empty?

          @g.dup
          @g.send c, 0

          unless inexact && required.empty?
            @g.dup
            @g.send :size, 0
            @g.push_int required.size
            @g.send(inexact ? :>= : :==, 1)
            @g.gif popmis2
          end

          required.each do |p|
            @g.shift_array
            go(p, popmis2)
          end

          defaults.each.with_index do |d, i|
            has = @g.new_label
            match = @g.new_label

            @g.dup
            @g.send :size, 0
            @g.push_int(i + 1)
            @g.send :>=, 1
            @g.git has

            @module.compile(@g, d.expression.to_pattern.default)
            @g.goto match

            has.set!
            @g.shift_array

            match.set!
            go(d, popmis2)
          end

          if splice
            splice.expression.to_pattern.matches?(@g, @module)
            @g.gif popmis
          else
            @g.pop
          end
        end

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
          x.expression.to_pattern.matches?(@g, @module)
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
          x.expression.to_pattern.deconstruct(@g, @module)
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
            x.unquote? && x.expression.to_pattern.is_a?(Default)
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

            @module.compile(@g, d.expression.to_pattern.default)
            @g.goto match

            has.set!
            @g.shift_array

            match.set!
            go(d)
          end

          if splice
            splice.expression.to_pattern.deconstruct(@g, @module)
          else
            @g.pop
          end
        end

        @g.pop
      end
    end
  end
end

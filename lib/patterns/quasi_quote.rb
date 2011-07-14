module Atomy::Patterns
  class QuasiQuote < Pattern
    attr_reader :quoted

    def initialize(x)
      @quoted = x.through_quotes(proc { true }) do |e|
        e.to_pattern.to_node
      end
    end

    def construct(g)
      get(g)
      @quoted.construct(g, nil)
      g.send :new, 1
    end

    def ==(b)
      b.kind_of?(QuasiQuote) and \
      @quoted == b.expression
    end

    def expression
      @quoted.expression
    end

    def target(g)
      names = expression.class.name.split("::")
      g.push_const names.slice!(0).to_sym
      names.each do |n|
        g.find_const n.to_sym
      end
    end

    def context(g, w, defaults)
      w.each do |c|
        if c.kind_of?(Array)
          g.send c[0], 0

          dflt = defaults[c[1]]

          if dflt
            valid = g.new_label
            done = g.new_label

            g.dup
            g.send :size, 0
            g.push_int(c[1] + 1)
            g.send :>=, 1
            g.git valid

            g.pop
            dflt.default.compile(g)
            g.goto done

            valid.set!
          end

          g.push_int c[1]
          g.send :[], 1

          done.set! if dflt
        else
          g.send c, 0
        end
      end
    end

    def my_context(e, w)
      x = e
      w.each do |c|
        if c.kind_of?(Array)
          x = x.send(c[0])[c[1]]
        else
          x = x.send(c)
        end
      end
      x
    end

    def required_size(ps)
      req = 0
      vary = false
      defaults = {}
      ps.each_with_index do |x, i|
        if x.is_a?(Atomy::AST::Splice)
          vary = true
        elsif x.is_a?(Atomy::AST::Unquote) and x.expression.pattern.is_a?(Atomy::Patterns::Default)
          vary = true
          defaults[i] = x.expression.pattern
        else
          req += 1 unless vary
        end
      end
      [req, vary, defaults]
    end

    def matches?(g)
      mismatch = g.new_label
      done = g.new_label

      them = g.new_stack_local
      g.set_stack_local them
      g.pop

      where = nil
      splice = false
      defaults = {}

      pre = proc { |e, c, d|
        if c.kind_of?(Array) && c[1] == 0 &&
            pats = my_context(@quoted.expression, (where + [c[0]]))
          req, vary, defaults = required_size(pats)
          g.push_stack_local them
          context(g, where + [c[0]], defaults)
          g.send :size, 0
          g.push_int req
          g.send(vary ? :>= : :==, 1)
          g.gif mismatch
        end

        where << c if c && where

        where = [] if !where and c == :expression

        splice = true if e.kind_of?(Atomy::AST::Splice)

        if !(e.unquote? && d == 1) && where && c != :unquoted
          e.get(g)
          g.push_stack_local them
          context(g, where, defaults)
          g.kind_of
          g.gif mismatch

          e.details.each do |a|
            val = e.send(a)
            if val.kind_of?(Array)
              val.each do |v|
                g.push_literal v
              end
              g.make_array val.size
            else
              g.push_literal val
            end
            g.push_stack_local them
            context(g, where, defaults)
            g.send a, 0
            g.send :==, 1
            g.gif mismatch
          end

          if e.bottom?
            e.construct(g)
            g.push_stack_local them
            context(g, where, defaults)
            g.send :==, 1
            g.gif mismatch
          end
        end

        true
      }

      post = proc { where.pop }

      @quoted.through_quotes(pre, post) do |e|
        ctx = where.last == :unquoted ? where[0..-2] : where
        g.push_stack_local them
        if splice
          context(g, ctx[0..-2], defaults)
          g.send ctx.last[0], 0
          g.push_int ctx.last[1]
          g.send :drop, 1
          splice = false
        else
          context(g, ctx, defaults)
        end
        e.to_pattern.matches?(g)
        g.gif mismatch
        e
      end

      g.push_true
      g.goto done

      mismatch.set!
      g.push_false

      done.set!
    end

    def deconstruct(g, locals = {})
      them = g.new_stack_local
      g.set_stack_local them
      g.pop

      where = nil
      splice = false
      defaults = {}

      pre = proc { |n, c|
        if c.kind_of?(Array) && c[1] == 0 &&
            pats = my_context(@quoted.expression, (where + [c[0]]))
          _, _, defaults = required_size(pats)
        end

        where << c if c && where

        where = [] if !where and c == :expression

        splice = true if n.kind_of?(Atomy::AST::Splice)

        true
      }

      post = proc { where.pop }

      @quoted.through_quotes(pre, post) do |e|
        ctx = where.last == :unquoted ? where[0..-2] : where
        g.push_stack_local them
        if splice &&
          context(g, ctx[0..-2], defaults)
          g.send ctx.last[0], 0
          g.push_int ctx.last[1]
          g.send :drop, 1
          splice = false
        else
          context(g, ctx, defaults)
        end
        e.to_pattern.deconstruct(g)
        e
      end
    end

    def local_names
      names = []

      @quoted.through_quotes(proc { true }) do |e|
        names += e.to_pattern.local_names
        e
      end

      names
    end

    def bindings
      bindings = 0

      @quoted.through_quotes(proc { true }) do |e|
        bindings += e.to_pattern.bindings
        e
      end

      bindings
    end
  end
end

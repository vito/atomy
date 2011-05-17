# TODO: fix splice unquotes
module Atomy::Patterns
  class QuasiQuote < Pattern
    attr_reader :quoted

    def initialize(x)
      @quoted = x
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

    def context(g, w)
      w.each do |c|
        # TODO: fail if out of bounds?
        # e.g. `(foo(~bar, ~baz)) = '(foo(1))
        if c.kind_of?(Array)
          g.send c[0], 0
          g.push_int c[1]
          g.send :[], 1
        else
          g.send c, 0
        end
      end
    end

    def matches?(g)
      mismatch = g.new_label
      done = g.new_label

      them = g.new_stack_local
      g.set_stack_local them
      g.pop

      where = nil
      splice = false

      pre = proc { |e, c, d|
        where << c if c && where

        where = [] if !where and c == :expression

        splice = true if e.kind_of?(Atomy::AST::Splice)

        if !(e.unquote? && d == 1) && where && c != :unquoted
          e.get(g)
          g.push_stack_local them
          context(g, where)
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
            context(g, where)
            g.send a, 0
            g.send :==, 1
            g.gif mismatch
          end

          if e.bottom?
            e.construct(g)
            g.push_stack_local them
            context(g, where)
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
          g.send ctx.last[0], 0
          g.push_int ctx.last[1]
          g.send :drop, 1
          splice = false
        else
          context(g, ctx)
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

      pre = proc { |n, c|
        where << c if c && where

        where = [] if !where and c == :expression

        splice = true if n.kind_of?(Atomy::AST::Splice)

        true
      }

      post = proc { where.pop }

      @quoted.through_quotes(pre, post) do |e|
        ctx = where.last == :unquoted ? where[0..-2] : where
        g.push_stack_local them
        if splice
          g.send ctx.last[0], 0
          g.push_int ctx.last[1]
          g.send :drop, 1
          splice = false
        else
          context(g, ctx)
        end
        e.to_pattern.deconstruct(g)
        e
      end
    end

    def local_names
      names = []

      @quoted.through_quotes(proc { true }) do |e|
        names += e.to_pattern.local_names
      end

      names
    end

    def bindings
      bindings = 0

      @quoted.through_quotes(proc { true }) do |e|
        bindings += e.to_pattern.bindings
      end

      bindings
    end
  end
end

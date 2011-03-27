module Atomo::Patterns
  class QuasiQuote < Pattern
    attr_reader :expression

    def initialize(x)
      @expression = x
    end

    def construct(g)
      get(g)
      @expression.construct(g, nil)
      g.send :new, 1
    end

    def ==(b)
      b.kind_of?(QuasiQuote) and \
      @expression == b.expression
    end

    def target(g)
      names = @expression.class.name.split("::")
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

      where = []
      depth = 1

      pre = proc { |n, c|
        where << c if c
        if n.kind_of?(Atomo::AST::QuasiQuote) ||
            n.kind_of?(Atomo::AST::Unquote)
          true
        else
          n.get(g)
          g.push_stack_local them
          context(g, where)
          g.kind_of
          g.gif mismatch
          false
        end
      }

      post = proc { where.pop }

      action = proc { |e|
        if e.kind_of?(Atomo::AST::Unquote)
          depth -= 1
          if depth == 0
            g.push_stack_local them
            context(g, where)
            e.expression.to_pattern.matches?(g)
            g.gif mismatch
            depth += 1
            next e
          end

          where << :expression
          e.expression.recursively(pre, post, &action)
          depth += 1
        end

        if e.kind_of?(Atomo::AST::QuasiQuote)
          depth += 1
          where << :expression
          e.expression.recursively(pre, post, &action)
          depth -= 1
        end

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

        next unless e.bottom?

        e.construct(g)
        g.push_stack_local them
        context(g, where)
        g.send :==, 1
        g.gif mismatch

        e
      }

      @expression.recursively(pre, post, &action)

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

      where = []
      depth = 1

      pre = proc { |n, c|
        where << c if c
        n.kind_of?(Atomo::AST::QuasiQuote) ||
          n.kind_of?(Atomo::AST::Unquote)
      }

      post = proc { where.pop }

      action = proc { |e|
        if e.kind_of?(Atomo::AST::Unquote)
          depth -= 1
          if depth == 0
            g.push_stack_local them
            context(g, where)
            e.expression.to_pattern.deconstruct(g)
            depth += 1
            next e
          end
          where << :expression
          e.expression.recursively(pre, post, &action)
          depth += 1
        end

        if e.kind_of?(Atomo::AST::QuasiQuote)
          depth += 1
          where << :expression
          e.expression.recursively(pre, post, &action)
          depth -= 1
        end

        e
      }

      @expression.recursively(pre, post, &action)
    end

    def local_names
      names = []

      depth = 1

      pre = proc { |n, c|
        n.kind_of?(Atomo::AST::QuasiQuote) ||
          n.kind_of?(Atomo::AST::Unquote)
      }

      action = proc { |e|
        if e.kind_of?(Atomo::AST::Unquote)
          depth -= 1
          if depth == 0
            names += e.expression.to_pattern.local_names
            depth += 1
            next e
          end
          e.expression.recursively(pre, &action)
          depth += 1
        end

        if e.kind_of?(Atomo::AST::QuasiQuote)
          depth += 1
          e.expression.recursively(pre, &action)
          depth -= 1
        end

        e
      }

      @expression.recursively(pre, &action)

      names
    end

    def bindings
      bindings = 0

      depth = 1

      pre = proc { |n, c|
        n.kind_of?(Atomo::AST::QuasiQuote) ||
          n.kind_of?(Atomo::AST::Unquote)
      }

      action = proc { |e|
        if e.kind_of?(Atomo::AST::Unquote)
          depth -= 1
          if depth == 0
            bindings += e.expression.to_pattern.bindings
            depth += 1
            next e
          end
          e.expression.recursively(pre, &action)
          depth += 1
        end

        if e.kind_of?(Atomo::AST::QuasiQuote)
          depth += 1
          e.expression.recursively(pre, &action)
          depth -= 1
        end

        e
      }

      @expression.recursively(pre, &action)

      bindings
    end
  end
end

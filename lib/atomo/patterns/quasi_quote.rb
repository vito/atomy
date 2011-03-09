module Atomo::Patterns
  class QuasiQuote < Pattern
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
      # TODO
      Constant.new(-1, @expression.class.name.split("::")).target(g)
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
        n.kind_of?(Atomo::AST::QuasiQuote) || n.kind_of?(Atomo::AST::Unquote)
      }

      post = proc { where.pop }

      action = proc { |e|
        if e.kind_of?(Atomo::AST::Unquote)
          depth -= 1
          if depth == 0
            g.push_stack_local them
            where.each do |a|
              g.send a, 0
            end
            Atomo::Patterns.from_node(e.expression).matches?(g)
            g.gif mismatch
            depth += 1
            next e
          end

          e.get(g)
          g.push_stack_local them
          where.each do |a|
            g.send a, 0
          end
          g.kind_of
          g.gif mismatch

          where << :expression
          e.expression.recursively(pre, post, &action)
          depth += 1
        end

        e.get(g)
        g.push_stack_local them
        where.each do |a|
          g.send a, 0
        end
        g.kind_of
        g.gif mismatch

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
          where.each do |c|
            g.send c, 0
          end
          g.send a, 0
          g.send :==, 1
          g.gif mismatch
        end

        next unless e.bottom?

        e.construct(g)
        g.push_stack_local them
        where.each do |a|
          g.send a, 0
        end
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
        n.kind_of?(Atomo::AST::QuasiQuote) || n.kind_of?(Atomo::AST::Unquote)
      }

      post = proc { where.pop }

      action = proc { |e|
        if e.kind_of?(Atomo::AST::Unquote)
          depth -= 1
          if depth == 0
            g.push_stack_local them
            where.each do |a|
              g.send a, 0
            end
            Atomo::Patterns.from_node(e.expression).deconstruct(g)
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
  end
end

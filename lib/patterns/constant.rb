module Atomy::Patterns
  class Constant < Pattern
    attr_reader :constant, :ancestors

    def initialize(constant, ancestors = nil)
      @constant = constant
      @ancestors = ancestors
    end

    def construct(g)
      get(g)
      @constant.construct(g)

      # try and get the constant's ancestors, for precision
      # comparison
      st = g.new_stack_local
      handler = g.new_label
      defined = g.new_label
      done = g.new_label

      g.push_exception_state
      g.set_stack_local st

      g.pop
      g.setup_unwind handler, Rubinius::AST::RescueType

      case @constant
      when Atomy::AST::ScopedConstant
        @constant.parent.bytecode(g)
        g.push_literal @constant.name
        g.push_false
        g.invoke_primitive :vm_const_defined_under, 3
      when Atomy::AST::ToplevelConstant
        g.push_cpath_top
        g.push_literal @constant.name
        g.push_false
        g.invoke_primitive :vm_const_defined_under, 3
      else
        g.push_literal @constant.name
        g.invoke_primitive :vm_const_defined, 1
      end

      g.pop_unwind
      g.goto defined

      handler.set!
      g.clear_exception
      g.push_stack_local st
      g.restore_exception_state
      g.push_nil
      g.goto done

      defined.set!
      g.pop
      @constant.bytecode(g)
      g.send :ancestors, 0
      done.set!

      g.send :new, 2
    end

    def ==(b)
      b.kind_of?(Constant) and \
        @constant == b.constant
    end

    def target(g)
      @constant.bytecode(g)
    end

    def matches?(g)
      target(g)
      g.swap
      g.kind_of
    end
  end
end

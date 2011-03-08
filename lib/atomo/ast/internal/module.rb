module Atomo
  module AST
    class Module < Rubinius::AST::Class
      include NodeLike

      def initialize(line, name, body)
        @line = line

        case name
        when Constant
          @name = Rubinius::AST::ModuleName.new @line, name.name
        when ToplevelConstant
          @name = Rubinius::AST::ToplevelModuleName.new @line, name
        when ScopedConstant
          @name = Rubinius::AST::ScopedModuleName.new @line, name
        else
          @name = name
        end

        @body = Rubinius::AST::ModuleScope.new @line, @name, body
        @_body = body
      end

      def construct(g, d = nil)
        get(g)
        g.push_int @line
        @name.construct(g, d)
        @_body.construct(g, d)
        g.send :new, 3
      end

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        Module.new(
          @line,
          @name,
          @body.body.recursively(stop, &f)
        )
      end
    end
  end
end

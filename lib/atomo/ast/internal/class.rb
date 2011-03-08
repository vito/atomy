module Atomo
  module AST
    class Class < Rubinius::AST::Class
      include NodeLike

      def initialize(line, name, superclass, body)
        @line = line

        @superclass = superclass ? superclass : Primitive.new(line, :nil)

        case name
        when Constant
          @name = Rubinius::AST::ClassName.new @line, name.name, @superclass
        when ToplevelConstant
          @name = Rubinius::AST::ToplevelModuleName.new @line, name, @superclass
        when ScopedConstant
          @name = Rubinius::AST::ScopedClassName.new @line, name, @superclass
        else
          @name = name
        end

        @body = Rubinius::AST::ClassScope.new @line, @name, body

        @_name = name
        @_superclass = superclass
        @_body = body
      end

      def construct(g, d)
        get(g)
        g.push_int @line
        @_name.construct(g, d)
        if @_superclass
          @_superclass.construct(g, d)
        else
          g.push_nil
        end
        @_body.construct(g, d)
        g.send :new, 4
      end

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        Class.new(
          @line,
          @name,
          @superclass,
          @body.body.recursively(stop, &f)
        )
      end
    end
  end
end

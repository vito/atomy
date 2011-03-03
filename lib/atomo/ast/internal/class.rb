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

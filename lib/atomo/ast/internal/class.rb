module Atomo
  module AST
    class Class < Rubinius::AST::Class
      include NodeLike

      def initialize(name, superclass, body)
        @line = 1 # TODO

        @superclass = superclass ? superclass : Primitive.new(:nil)

        if name.kind_of?(Rubinius::AST::ClassName)
          @name = name
        else
          @name = Rubinius::AST::ClassName.new @line, name.chain.last.to_sym, @superclass
        end

        @body = Rubinius::AST::ClassScope.new @line, @name, body
      end

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        Class.new(
          @name,
          @superclass,
          @body.body.recursively(stop, &f)
        )
      end
    end
  end
end
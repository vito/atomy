module Atomy
  module AST
    class Class < Node
      children :name, :body, [:superclass, "Primitive.new(0, :nil)"]
      generate

      def class_name
        case @name
        when Constant
          Rubinius::AST::ClassName.new @line, @name.name, @superclass
        when ToplevelConstant
          Rubinius::AST::ToplevelModuleName.new @line, @name, @superclass
        when ScopedConstant
          Rubinius::AST::ScopedClassName.new @line, @name, @superclass
        else
          @name
        end
      end

      def class_body
        Rubinius::AST::ClassScope.new @line, class_name, @body
      end

      def bytecode(g)
        class_name.bytecode(g)
        class_body.bytecode(g)
      end
    end
  end
end

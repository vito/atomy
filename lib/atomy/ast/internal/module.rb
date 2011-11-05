module Atomy
  module AST
    class Module < Node
      children :name, :body
      generate

      def module_name
        case @name
        when Constant
          Rubinius::AST::ModuleName.new @line, @name.name
        when ToplevelConstant
          Rubinius::AST::ToplevelModuleName.new @line, @name
        when ScopedConstant
          Rubinius::AST::ScopedModuleName.new @line, @name
        else
          @name
        end
      end

      def module_body
        Rubinius::AST::ModuleScope.new @line, module_name, @body
      end

      def bytecode(g)
        module_name.bytecode(g)
        module_body.bytecode(g)
      end
    end
  end
end

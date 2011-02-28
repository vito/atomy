module Atomo
  module AST
    class Module < Rubinius::AST::Class
      include NodeLike

      def initialize(line, name, body)
        @line = line

        if name.kind_of?(Rubinius::AST::ModuleName)
          @name = name
        else
          @name = Rubinius::AST::ModuleName.new @line, name.chain.last.to_sym
        end

        @body = Rubinius::AST::ModuleScope.new @line, @name, body
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
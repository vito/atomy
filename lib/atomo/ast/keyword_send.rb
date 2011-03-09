module Atomo
  module AST
    class KeywordSend < Node
      children :receiver, [:arguments]
      attributes [:names], [:private, "false"]
      generate

      def register_macro(body)
        Atomo::Macro.register(
          method_name,
          ([@receiver] + @arguments).collect do |n|
            Atomo::Macro.macro_pattern n
          end,
          body
        )
      end

      def bytecode(g)
        pos(g)

        @receiver.bytecode(g)

        @arguments.each do |a|
          a.bytecode(g)
        end

        g.send method_name.to_sym, @arguments.size, @private
      end

      def method_name
        @names.collect { |n| n + ":" }.join
      end
    end
  end
end

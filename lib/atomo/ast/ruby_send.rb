module Atomo
  module AST
    class RubySend < AST::Node
      Atomo::Parser.register self

      def self.rule_name
        "ruby_send"
      end

      def initialize(receiver, method, arguments)
        @receiver = receiver
        @method_name = method
        @arguments = arguments
        @line = 1 # TODO
      end

      attr_reader :receiver, :method_name, :arguments

      def self.grammar(g)
        g.ruby_args =
          g.seq(
            "(", :some_expressions, ")"
          ) do |_, as, _| as end

        g.ruby_send =
          g.seq(
            :ruby_send, :sig_sp, :identifier, :ruby_args
          ) do |v, _, n, x|
            RubySend.new(v,n,x)
          end | g.seq(
            :level1, :sig_sp, :identifier, :ruby_args
          ) do |v, _, n, x|
            RubySend.new(v,n,x)
          end
      end

      def bytecode(g)
        pos(g)

        @receiver.bytecode(g)
        if @arguments.last.kind_of? Block
          block = @arguments.pop
        end

        @arguments.each do |a|
          a.bytecode(g)
        end

        if block
          block.bytecode(g)
          g.send_with_block @method_name.to_sym, @arguments.size
        else
          g.send @method_name.to_sym, @arguments.size
        end
      end
    end
  end
end

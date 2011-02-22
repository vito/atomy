module Atomo
  module AST
    class RubySend < AST::Node
      Atomo::Parser.register self

      def self.rule_name
        "ruby_send"
      end

      def initialize(receiver, method, arguments, block = nil, privat = false)
        @receiver = receiver
        @method_name = method
        @arguments = arguments
        @block = block unless block == []
        @private = privat
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
            :ruby_send, :sig_sp, :identifier, :ruby_args,
            g.maybe(g.seq(:sp, g.t(:block)))
          ) do |v, _, n, x, b|
            RubySend.new(v,n,x,b)
          end | g.seq(
            :level1, :sig_sp, :identifier, :ruby_args,
            g.maybe(g.seq(:sp, g.t(:block)))
          ) do |v, _, n, x, b|
            RubySend.new(v,n,x,b)
          end | g.seq(
            :identifier, :ruby_args,
            g.maybe(g.seq(:sp, g.t(:block)))
          ) do |n, x, b|
            RubySend.new(Primitive.new(:self),n,x,b,true)
          end
      end

      def bytecode(g)
        pos(g)

        @receiver.bytecode(g)
        block = @block
        if not block and @arguments.last.kind_of? Block
          block = @arguments.pop
        end

        @arguments.each do |a|
          a.bytecode(g)
        end

        if block
          block.bytecode(g)
          g.send_with_block @method_name.to_sym, @arguments.size, @private
        else
          g.send @method_name.to_sym, @arguments.size, @private
        end
      end
    end
  end
end

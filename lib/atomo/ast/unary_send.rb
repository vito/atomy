module Atomo
  module AST
    class UnarySend < Node
      Atomo::Parser.register self

      def self.rule_name
        "unary_send"
      end

      def initialize(receiver, name, arguments, block = nil, privat = false)
        @receiver = receiver
        @method_name = name
        @arguments = arguments
        @block = block unless block == []
        @private = privat
        @line = 1 # TODO
      end

      attr_reader :receiver, :method_name, :arguments, :block, :private

      def register_macro(body)
        Atomo::Macro.register(
          @method_name,
          ([@receiver] + @arguments).collect do |n|
            Atomo::Macro.macro_pattern n
          end,
          body
        )
      end

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        f.call UnarySend.new(
          @receiver.recursively(stop, &f),
          @method_name,
          @arguments.collect do |n|
            n.recursively(stop, &f)
          end,
          @block ? @block.recursively(stop, &f) : nil,
          @private
        )
      end

      def construct(g, d)
        get(g)
        @receiver.construct(g, d)
        g.push_literal @method_name
        @arguments.each do |a|
          a.construct(g, d)
        end
        g.make_array @arguments.size

        if @block
          @block.construct(g, d)
        else
          g.push_nil
        end

        g.push_literal @private
        g.send :new, 5
      end

      def self.grammar(g)
        g.unary_args =
          g.seq(
            "(", :sp, g.t(:some_expressions), :sp, ")"
          )

        g.unary_send =
          g.seq(
            :unary_send, :sig_sp, :identifier, g.notp(":"), g.maybe(:unary_args),
            g.maybe(g.seq(:sp, g.t(:block)))
          ) do |v, _, n, _, x, b|
            UnarySend.new(v,n,x,b)
          end | g.seq(
            :level1, :sig_sp, :identifier, g.notp(":"), g.maybe(:unary_args),
            g.maybe(g.seq(:sp, g.t(:block)))
          ) do |v, _, n, _, x, b|
            UnarySend.new(v,n,x,b)
          end | g.seq(
            :identifier, :unary_args,
            g.maybe(g.seq(:sp, g.t(:block)))
          ) do |n, x, b|
            UnarySend.new(Primitive.new(:self),n,x,b,true)
          end
      end

      def bytecode(g)
        pos(g)

        @receiver.bytecode(g)
        block = @block
        if @arguments.last.kind_of? BlockPass
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

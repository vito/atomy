module Atomo
  module AST
    class KeywordSend < Node
      attr_reader :receiver, :method_name, :arguments, :private

      def initialize(receiver, name, arguments, privat = false)
        @receiver = receiver
        @method_name = name
        @arguments = arguments
        @private = privat
        @line = 1 # TODO
      end

      def ==(b)
        b.kind_of?(KeywordSend) and \
        @receiver == b.receiver and \
        @method_name == b.method_name and \
        @arguments == b.arguments
      end

      Pair = Struct.new(:name, :value)

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

        f.call KeywordSend.new(
          @receiver.recursively(stop, &f),
          @method_name,
          @arguments.collect do |n|
            n.recursively(stop, &f)
          end,
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
        g.push_literal @private
        g.send :new, 4
      end

      def loop_cond(g, if_true)
        return false unless @receiver.kind_of? AST::Block
        return false unless @arguments[0].kind_of? AST::Block

        top_lbl  = g.new_label
        done_lbl = g.new_label

        top_lbl.set!

        @receiver.body.each_with_index do |e,idx|
          g.pop unless idx == 0
          e.bytecode(g)
        end

        if if_true
          g.gif done_lbl
        else
          g.git done_lbl
        end

        @arguments[0].body.each_with_index do |e,idx|
          e.bytecode(g)
          g.pop
        end

        g.goto top_lbl

        done_lbl.set!
        g.push :nil

        return true
      end

      def bytecode(g)
        pos(g)

        case @method_name
        when "whileTrue:"
          return if loop_cond g, true
        when "whileFalse:"
          return if loop_cond g, false
        end

        @receiver.bytecode(g)

        @arguments.each do |a|
          a.bytecode(g)
        end

        g.send @method_name.to_sym, @arguments.size, @private
      end
    end
  end
end

module Atomo
  module AST
    class KeywordSend < AST::Node
      attr_reader :receiver, :method_name, :arguments

      Atomo::Parser.register self

      def self.rule_name
        "keyword_send"
      end

      def initialize(receiver, name, arguments = [])
        @receiver = receiver
        @method_name = name
        @arguments = arguments
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
          end
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
        g.send :new, 3
      end

      def self.collect(pairs)
        name = ""
        args = []

        if pairs.kind_of? Array
          pairs.each do |pair|
            name << "#{pair.name}:"
            args << pair.value
          end
        else
          name << "#{pairs.name}:"
          args << pairs.value
        end

        [name, args]
      end

      def self.grammar(g)
        g.name_var_pair =
          g.seq(
            :sp, g.t(:identifier), ":", :sp,
            g.t(:level2)
          ) do |n, v|
            Pair.new(n,v)
          end

        g.send_args = g.many(:name_var_pair) do |*pairs|
          collect(pairs)
        end

        g.keyword_send =
          g.seq(:level2, :sig_sp, :send_args) do |v, _, arg|
            new(v, arg.first, arg.last)
          end | g.seq(:send_args) do |arg|
            new(Primitive.new(:self), arg.first, arg.last)
          end
      end

      def self.send_method(g, name, args)
        args.each do |a|
          a.bytecode(g)
        end

        g.send name.to_sym, args.size
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

        KeywordSend.send_method g, @method_name, @arguments
      end
    end
  end
end

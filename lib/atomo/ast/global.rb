module Atomo
  module AST
    def self.grammar(g)
      g.sp = g.kleene g.any(" ", "\n")
      g.sig_sp = g.many g.any(" ", "\n")

      ident_start = /(?![&@$~:])[\p{L}\p{S}_!@#%&*-.\/\?]/u
      ident_letters = /[\p{L}\p{S}_!@#%&*-.\/\?]*/u

      g.identifier =
        g.seq(
          # look ahead to make sure it's not actually an operator
          g.notp(g.seq(:operator, :sig_sp)),
          ident_start, ident_letters
        ) do |_, c, cs|
          c + cs
        end

      op_start = /(?!`@$~)[\p{S}!@#%&*-.\/\?:]/u
      op_letters = /((?!`)[\p{S}!@#%&*-.\/\?:])*/u

      g.operator =
        g.seq(op_start, op_letters) do |c, cs|
          c + cs
        end

      g.grouped = g.seq("(", :sp, g.t(:expression), :sp, ")")
      g.level1 = g.any(:true, :false, :self, :nil, :number,
                       :string, :symbol, :constant, :variable,
                       :tuple, :grouped, :block, :list)

      g.level2 = g.any(:ruby_send, :unary_send, :level1)

      g.level3 = g.any(:keyword_send, :level2)

      g.expression = g.any(:binary_send, :level3)

      g.delim = g.any(",", ";")

      g.expressions =
        g.seq(
          :expression,
          :sp,
          g.kleene(
            g.seq(:sp, :delim, :sp, g.t(:expression), :sp)
          )
        ) do |x, _, m|
          m = Array(m)
          m.unshift x
          m
        end

      g.some_expressions = g.maybe(:expressions)

      g.root = g.expressions
    end
  end
end
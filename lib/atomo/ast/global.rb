module Atomo
  module AST
    def self.grammar(g)
      g.sp = g.kleene g.any(" ", "\n")
      g.sig_sp = g.many g.any(" ", "\n")
      g.method_name = /~?[a-zA-Z_][a-zA-Z0-9_]*[?!]?/

      g.grouped = g.seq("(", :sp, g.t(:expression), :sp, ")")
      g.level1 = g.any(:true, :false, :self, :nil, :number,
                       :string, :symbol, :variable, :constant,
                       :tuple, :grouped, :block, :list)

      g.level2 = g.any(:unary_send, :ruby_send, :level1)

      g.level3 = g.any(:keyword_send, :level2)

      g.expression = g.any(:operator, :level3)

      g.delim = g.any(";", ",")

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
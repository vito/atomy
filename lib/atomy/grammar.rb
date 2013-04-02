require 'kpeg/compiled_parser'

class Atomy::Grammar < KPeg::CompiledParser


  module AST
    class Node
      attr_accessor :line
    end
  end

  def make(what, line, *args)
    node = send(what, *args)
    node.line ||= line
    node
  end

  def current_position(target = pos)
    cur_offset = 0
    cur_line = 0

    line_lengths.each do |len|
      cur_line += 1
      return [cur_line, target - cur_offset] if cur_offset + len > target
      cur_offset += len
    end

    [cur_line, cur_offset]
  end

  def line_lengths
    @line_lengths ||= lines.collect { |l| l.size }
  end

  def current_line(x = pos)
    current_position(x)[0]
  end

  def current_column(x = pos)
    current_position(x)[1]
  end

  def continue?(x)
    y = current_position
    y[0] >= x[0] && y[1] > x[1]
  end


  # :stopdoc:

  module AST
    class Node; end
    class Apply < Node
      def initialize(node, arguments)
        @node = node
        @arguments = arguments
      end
      attr_reader :node
      attr_reader :arguments
    end
    class Block < Node
      def initialize(nodes)
        @nodes = nodes
      end
      attr_reader :nodes
    end
    class Compose < Node
      def initialize(left, right)
        @left = left
        @right = right
      end
      attr_reader :left
      attr_reader :right
    end
    class Constant < Node
      def initialize(text)
        @text = text
      end
      attr_reader :text
    end
    class Infix < Node
      def initialize(left, right, operator)
        @left = left
        @right = right
        @operator = operator
      end
      attr_reader :left
      attr_reader :right
      attr_reader :operator
    end
    class List < Node
      def initialize(nodes)
        @nodes = nodes
      end
      attr_reader :nodes
    end
    class Literal < Node
      def initialize(value)
        @value = value
      end
      attr_reader :value
    end
    class Number < Node
      def initialize(value)
        @value = value
      end
      attr_reader :value
    end
    class Postfix < Node
      def initialize(node, operator)
        @node = node
        @operator = operator
      end
      attr_reader :node
      attr_reader :operator
    end
    class Prefix < Node
      def initialize(node, operator)
        @node = node
        @operator = operator
      end
      attr_reader :node
      attr_reader :operator
    end
    class QuasiQuote < Node
      def initialize(node)
        @node = node
      end
      attr_reader :node
    end
    class Quote < Node
      def initialize(node)
        @node = node
      end
      attr_reader :node
    end
    class Sequence < Node
      def initialize(nodes)
        @nodes = nodes
      end
      attr_reader :nodes
    end
    class StringLiteral < Node
      def initialize(value)
        @value = value
      end
      attr_reader :value
    end
    class Unquote < Node
      def initialize(node)
        @node = node
      end
      attr_reader :node
    end
    class Word < Node
      def initialize(text)
        @text = text
      end
      attr_reader :text
    end
  end
  def application(node, arguments)
    AST::Apply.new(node, arguments)
  end
  def block(nodes)
    AST::Block.new(nodes)
  end
  def compose(left, right)
    AST::Compose.new(left, right)
  end
  def constant(text)
    AST::Constant.new(text)
  end
  def infix(left, right, operator)
    AST::Infix.new(left, right, operator)
  end
  def list(nodes)
    AST::List.new(nodes)
  end
  def literal(value)
    AST::Literal.new(value)
  end
  def number(value)
    AST::Number.new(value)
  end
  def postfix(node, operator)
    AST::Postfix.new(node, operator)
  end
  def prefix(node, operator)
    AST::Prefix.new(node, operator)
  end
  def quasiquote(node)
    AST::QuasiQuote.new(node)
  end
  def quote(node)
    AST::Quote.new(node)
  end
  def sequence(nodes)
    AST::Sequence.new(nodes)
  end
  def strliteral(value)
    AST::StringLiteral.new(value)
  end
  def unquote(node)
    AST::Unquote.new(node)
  end
  def word(text)
    AST::Word.new(text)
  end

  # root = shebang? wsp expressions?:es wsp !. { sequence(Array(es)) }
  def _root

    _save = self.pos
    while true # sequence
      _save1 = self.pos
      _tmp = apply(:_shebang)
      unless _tmp
        _tmp = true
        self.pos = _save1
      end
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_wsp)
      unless _tmp
        self.pos = _save
        break
      end
      _save2 = self.pos
      _tmp = apply(:_expressions)
      @result = nil unless _tmp
      unless _tmp
        _tmp = true
        self.pos = _save2
      end
      es = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_wsp)
      unless _tmp
        self.pos = _save
        break
      end
      _save3 = self.pos
      _tmp = get_byte
      _tmp = _tmp ? nil : true
      self.pos = _save3
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  sequence(Array(es)) ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_root unless _tmp
    return _tmp
  end

  # shebang = "#!" /.*?$/
  def _shebang

    _save = self.pos
    while true # sequence
      _tmp = match_string("#!")
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = scan(/\A(?-mix:.*?$)/)
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_shebang unless _tmp
    return _tmp
  end

  # expressions = {current_column}:c expression:x (delim(c) expression)*:xs {                     [x] + Array(xs)                   }
  def _expressions

    _save = self.pos
    while true # sequence
      @result = begin; current_column; end
      _tmp = true
      c = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_expression)
      x = @result
      unless _tmp
        self.pos = _save
        break
      end
      _ary = []
      while true

        _save2 = self.pos
        while true # sequence
          _tmp = apply_with_args(:_delim, c)
          unless _tmp
            self.pos = _save2
            break
          end
          _tmp = apply(:_expression)
          unless _tmp
            self.pos = _save2
          end
          break
        end # end sequence

        _ary << @result if _tmp
        break unless _tmp
      end
      _tmp = true
      @result = _ary
      xs = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; 
                    [x] + Array(xs)
                  ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_expressions unless _tmp
    return _tmp
  end

  # delim = (wsp "," wsp | (sp "\n" sp)+ &{ current_column >= c })
  def _delim(c)

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_wsp)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = match_string(",")
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_wsp)
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save2 = self.pos
      while true # sequence
        _save3 = self.pos

        _save4 = self.pos
        while true # sequence
          _tmp = apply(:_sp)
          unless _tmp
            self.pos = _save4
            break
          end
          _tmp = match_string("\n")
          unless _tmp
            self.pos = _save4
            break
          end
          _tmp = apply(:_sp)
          unless _tmp
            self.pos = _save4
          end
          break
        end # end sequence

        if _tmp
          while true

            _save5 = self.pos
            while true # sequence
              _tmp = apply(:_sp)
              unless _tmp
                self.pos = _save5
                break
              end
              _tmp = match_string("\n")
              unless _tmp
                self.pos = _save5
                break
              end
              _tmp = apply(:_sp)
              unless _tmp
                self.pos = _save5
              end
              break
            end # end sequence

            break unless _tmp
          end
          _tmp = true
        else
          self.pos = _save3
        end
        unless _tmp
          self.pos = _save2
          break
        end
        _save6 = self.pos
        _tmp = begin;  current_column >= c ; end
        self.pos = _save6
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_delim unless _tmp
    return _tmp
  end

  # expression = level4
  def _expression
    _tmp = apply(:_level4)
    set_failed_rule :_expression unless _tmp
    return _tmp
  end

  # one_expression = wsp expression:e wsp !. { e }
  def _one_expression

    _save = self.pos
    while true # sequence
      _tmp = apply(:_wsp)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_expression)
      e = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_wsp)
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos
      _tmp = get_byte
      _tmp = _tmp ? nil : true
      self.pos = _save1
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  e ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_one_expression unless _tmp
    return _tmp
  end

  # line = {current_line}
  def _line
    @result = begin; current_line; end
    _tmp = true
    set_failed_rule :_line unless _tmp
    return _tmp
  end

  # cont = (scont(p) | !"(")
  def _cont(p)

    _save = self.pos
    while true # choice
      _tmp = apply_with_args(:_scont, p)
      break if _tmp
      self.pos = _save
      _save1 = self.pos
      _tmp = match_string("(")
      _tmp = _tmp ? nil : true
      self.pos = _save1
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_cont unless _tmp
    return _tmp
  end

  # scont = (("\n" sp)+ &{ continue?(p) } | sig_sp cont(p)?)
  def _scont(p)

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _save2 = self.pos

        _save3 = self.pos
        while true # sequence
          _tmp = match_string("\n")
          unless _tmp
            self.pos = _save3
            break
          end
          _tmp = apply(:_sp)
          unless _tmp
            self.pos = _save3
          end
          break
        end # end sequence

        if _tmp
          while true

            _save4 = self.pos
            while true # sequence
              _tmp = match_string("\n")
              unless _tmp
                self.pos = _save4
                break
              end
              _tmp = apply(:_sp)
              unless _tmp
                self.pos = _save4
              end
              break
            end # end sequence

            break unless _tmp
          end
          _tmp = true
        else
          self.pos = _save2
        end
        unless _tmp
          self.pos = _save1
          break
        end
        _save5 = self.pos
        _tmp = begin;  continue?(p) ; end
        self.pos = _save5
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save6 = self.pos
      while true # sequence
        _tmp = apply(:_sig_sp)
        unless _tmp
          self.pos = _save6
          break
        end
        _save7 = self.pos
        _tmp = apply_with_args(:_cont, p)
        unless _tmp
          _tmp = true
          self.pos = _save7
        end
        unless _tmp
          self.pos = _save6
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_scont unless _tmp
    return _tmp
  end

  # sp = (" " | "\t" | comment)*
  def _sp
    while true

      _save1 = self.pos
      while true # choice
        _tmp = match_string(" ")
        break if _tmp
        self.pos = _save1
        _tmp = match_string("\t")
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_comment)
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      break unless _tmp
    end
    _tmp = true
    set_failed_rule :_sp unless _tmp
    return _tmp
  end

  # wsp = (" " | "\t" | "\n" | comment)*
  def _wsp
    while true

      _save1 = self.pos
      while true # choice
        _tmp = match_string(" ")
        break if _tmp
        self.pos = _save1
        _tmp = match_string("\t")
        break if _tmp
        self.pos = _save1
        _tmp = match_string("\n")
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_comment)
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      break unless _tmp
    end
    _tmp = true
    set_failed_rule :_wsp unless _tmp
    return _tmp
  end

  # sig_sp = (" " | "\t" | comment)+
  def _sig_sp
    _save = self.pos

    _save1 = self.pos
    while true # choice
      _tmp = match_string(" ")
      break if _tmp
      self.pos = _save1
      _tmp = match_string("\t")
      break if _tmp
      self.pos = _save1
      _tmp = apply(:_comment)
      break if _tmp
      self.pos = _save1
      break
    end # end choice

    if _tmp
      while true

        _save2 = self.pos
        while true # choice
          _tmp = match_string(" ")
          break if _tmp
          self.pos = _save2
          _tmp = match_string("\t")
          break if _tmp
          self.pos = _save2
          _tmp = apply(:_comment)
          break if _tmp
          self.pos = _save2
          break
        end # end choice

        break unless _tmp
      end
      _tmp = true
    else
      self.pos = _save
    end
    set_failed_rule :_sig_sp unless _tmp
    return _tmp
  end

  # sig_wsp = (" " | "\t" | "\n" | comment)+
  def _sig_wsp
    _save = self.pos

    _save1 = self.pos
    while true # choice
      _tmp = match_string(" ")
      break if _tmp
      self.pos = _save1
      _tmp = match_string("\t")
      break if _tmp
      self.pos = _save1
      _tmp = match_string("\n")
      break if _tmp
      self.pos = _save1
      _tmp = apply(:_comment)
      break if _tmp
      self.pos = _save1
      break
    end # end choice

    if _tmp
      while true

        _save2 = self.pos
        while true # choice
          _tmp = match_string(" ")
          break if _tmp
          self.pos = _save2
          _tmp = match_string("\t")
          break if _tmp
          self.pos = _save2
          _tmp = match_string("\n")
          break if _tmp
          self.pos = _save2
          _tmp = apply(:_comment)
          break if _tmp
          self.pos = _save2
          break
        end # end choice

        break unless _tmp
      end
      _tmp = true
    else
      self.pos = _save
    end
    set_failed_rule :_sig_wsp unless _tmp
    return _tmp
  end

  # comment = (/--.*?$/ | multi_comment)
  def _comment

    _save = self.pos
    while true # choice
      _tmp = scan(/\A(?-mix:--.*?$)/)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_multi_comment)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_comment unless _tmp
    return _tmp
  end

  # multi_comment = "{-" in_multi
  def _multi_comment

    _save = self.pos
    while true # sequence
      _tmp = match_string("{-")
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_in_multi)
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_multi_comment unless _tmp
    return _tmp
  end

  # in_multi = (/[^\-\{\}]*/ "-}" | /[^\-\{\}]*/ "{-" in_multi /[^\-\{\}]*/ "-}" | /[^\-\{\}]*/ /[-{}]/ in_multi)
  def _in_multi

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = scan(/\A(?-mix:[^\-\{\}]*)/)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = match_string("-}")
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save2 = self.pos
      while true # sequence
        _tmp = scan(/\A(?-mix:[^\-\{\}]*)/)
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = match_string("{-")
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_in_multi)
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = scan(/\A(?-mix:[^\-\{\}]*)/)
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = match_string("-}")
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save3 = self.pos
      while true # sequence
        _tmp = scan(/\A(?-mix:[^\-\{\}]*)/)
        unless _tmp
          self.pos = _save3
          break
        end
        _tmp = scan(/\A(?-mix:[-{}])/)
        unless _tmp
          self.pos = _save3
          break
        end
        _tmp = apply(:_in_multi)
        unless _tmp
          self.pos = _save3
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_in_multi unless _tmp
    return _tmp
  end

  # op_letter = < /[$+<=>^|~!@#%&*\-\\.\/\?]/ > { text.to_sym }
  def _op_letter

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = scan(/\A(?-mix:[$+<=>^|~!@#%&*\-\\.\/\?])/)
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  text.to_sym ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_op_letter unless _tmp
    return _tmp
  end

  # operator = < op_letter+ > { text.to_sym }
  def _operator

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _save1 = self.pos
      _tmp = apply(:_op_letter)
      if _tmp
        while true
          _tmp = apply(:_op_letter)
          break unless _tmp
        end
        _tmp = true
      else
        self.pos = _save1
      end
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  text.to_sym ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_operator unless _tmp
    return _tmp
  end

  # identifier = < /[a-z_][a-zA-Z\d\-_]*/ > { text.tr("-", "_").to_sym }
  def _identifier

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = scan(/\A(?-mix:[a-z_][a-zA-Z\d\-_]*)/)
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  text.tr("-", "_").to_sym ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_identifier unless _tmp
    return _tmp
  end

  # language = "#language" wsp identifier:n {set_lang(n)} %lang.root
  def _language

    _save = self.pos
    while true # sequence
      _tmp = match_string("#language")
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_wsp)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_identifier)
      n = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; set_lang(n); end
      _tmp = true
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = @_grammar_lang.external_invoke(self, :_root)
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_language unless _tmp
    return _tmp
  end

  # level0 = (number | quote | quasi_quote | unquote | string | constant | word | block | list | prefix)
  def _level0

    _save = self.pos
    while true # choice
      _tmp = apply(:_number)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_quote)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_quasi_quote)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_unquote)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_string)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_constant)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_word)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_block)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_list)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_prefix)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_level0 unless _tmp
    return _tmp
  end

  # level1 = (apply | grouped | level0)
  def _level1

    _save = self.pos
    while true # choice
      _tmp = apply(:_apply)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_grouped)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_level0)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_level1 unless _tmp
    return _tmp
  end

  # level2 = (postfix | level1)
  def _level2

    _save = self.pos
    while true # choice
      _tmp = apply(:_postfix)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_level1)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_level2 unless _tmp
    return _tmp
  end

  # level3 = (compose | level2)
  def _level3

    _save = self.pos
    while true # choice
      _tmp = apply(:_compose)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_level2)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_level3 unless _tmp
    return _tmp
  end

  # level4 = (language | infix | level3)
  def _level4

    _save = self.pos
    while true # choice
      _tmp = apply(:_language)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_infix)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_level3)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_level4 unless _tmp
    return _tmp
  end

  # grouped = "(" wsp expression:x wsp ")" { x }
  def _grouped

    _save = self.pos
    while true # sequence
      _tmp = match_string("(")
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_wsp)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_expression)
      x = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_wsp)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string(")")
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  x ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_grouped unless _tmp
    return _tmp
  end

  # number = (line:l < /[\+\-]?0[oO][0-7]+/ > {make(:number, l, text.to_i(8))} | line:l < /[\+\-]?0[xX][\da-fA-F]+/ > {make(:number, l, text.to_i(16))} | line:l < /[\+\-]?\d+(\.\d+)?[eE][\+\-]?\d+/ > {make(:literal, l, text.to_f)} | line:l < /[\+\-]?\d+\.\d+/ > {make(:literal, l, text.to_f)} | line:l < /[\+\-]?\d+/ > {make(:number, l, text.to_i)})
  def _number

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_line)
        l = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _text_start = self.pos
        _tmp = scan(/\A(?-mix:[\+\-]?0[oO][0-7]+)/)
        if _tmp
          text = get_text(_text_start)
        end
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; make(:number, l, text.to_i(8)); end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save2 = self.pos
      while true # sequence
        _tmp = apply(:_line)
        l = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _text_start = self.pos
        _tmp = scan(/\A(?-mix:[\+\-]?0[xX][\da-fA-F]+)/)
        if _tmp
          text = get_text(_text_start)
        end
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin; make(:number, l, text.to_i(16)); end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save3 = self.pos
      while true # sequence
        _tmp = apply(:_line)
        l = @result
        unless _tmp
          self.pos = _save3
          break
        end
        _text_start = self.pos
        _tmp = scan(/\A(?-mix:[\+\-]?\d+(\.\d+)?[eE][\+\-]?\d+)/)
        if _tmp
          text = get_text(_text_start)
        end
        unless _tmp
          self.pos = _save3
          break
        end
        @result = begin; make(:literal, l, text.to_f); end
        _tmp = true
        unless _tmp
          self.pos = _save3
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save4 = self.pos
      while true # sequence
        _tmp = apply(:_line)
        l = @result
        unless _tmp
          self.pos = _save4
          break
        end
        _text_start = self.pos
        _tmp = scan(/\A(?-mix:[\+\-]?\d+\.\d+)/)
        if _tmp
          text = get_text(_text_start)
        end
        unless _tmp
          self.pos = _save4
          break
        end
        @result = begin; make(:literal, l, text.to_f); end
        _tmp = true
        unless _tmp
          self.pos = _save4
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save5 = self.pos
      while true # sequence
        _tmp = apply(:_line)
        l = @result
        unless _tmp
          self.pos = _save5
          break
        end
        _text_start = self.pos
        _tmp = scan(/\A(?-mix:[\+\-]?\d+)/)
        if _tmp
          text = get_text(_text_start)
        end
        unless _tmp
          self.pos = _save5
          break
        end
        @result = begin; make(:number, l, text.to_i); end
        _tmp = true
        unless _tmp
          self.pos = _save5
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_number unless _tmp
    return _tmp
  end

  # string = line:line "\"" < ("\\" . | /[^\\"]/)*:c > "\"" {make(:strliteral, line, text.gsub("\\\"", "\""))}
  def _string

    _save = self.pos
    while true # sequence
      _tmp = apply(:_line)
      line = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string("\"")
      unless _tmp
        self.pos = _save
        break
      end
      _text_start = self.pos
      _ary = []
      while true

        _save2 = self.pos
        while true # choice

          _save3 = self.pos
          while true # sequence
            _tmp = match_string("\\")
            unless _tmp
              self.pos = _save3
              break
            end
            _tmp = get_byte
            unless _tmp
              self.pos = _save3
            end
            break
          end # end sequence

          break if _tmp
          self.pos = _save2
          _tmp = scan(/\A(?-mix:[^\\"])/)
          break if _tmp
          self.pos = _save2
          break
        end # end choice

        _ary << @result if _tmp
        break unless _tmp
      end
      _tmp = true
      @result = _ary
      c = @result
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string("\"")
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; make(:strliteral, line, text.gsub("\\\"", "\"")); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_string unless _tmp
    return _tmp
  end

  # constant = line:l < /[A-Z][a-zA-Z0-9_]*/ > {make(:constant, l, text.to_sym)}
  def _constant

    _save = self.pos
    while true # sequence
      _tmp = apply(:_line)
      l = @result
      unless _tmp
        self.pos = _save
        break
      end
      _text_start = self.pos
      _tmp = scan(/\A(?-mix:[A-Z][a-zA-Z0-9_]*)/)
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; make(:constant, l, text.to_sym); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_constant unless _tmp
    return _tmp
  end

  # word = line:l identifier:n {make(:word, l, n)}
  def _word

    _save = self.pos
    while true # sequence
      _tmp = apply(:_line)
      l = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_identifier)
      n = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; make(:word, l, n); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_word unless _tmp
    return _tmp
  end

  # quote = line:l "'" level2:e {make(:make, l, :quote, l, e)}
  def _quote

    _save = self.pos
    while true # sequence
      _tmp = apply(:_line)
      l = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string("'")
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_level2)
      e = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; make(:make, l, :quote, l, e); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_quote unless _tmp
    return _tmp
  end

  # quasi_quote = line:l "`" level2:e {make(:quasiquote, l, e)}
  def _quasi_quote

    _save = self.pos
    while true # sequence
      _tmp = apply(:_line)
      l = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string("`")
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_level2)
      e = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; make(:quasiquote, l, e); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_quasi_quote unless _tmp
    return _tmp
  end

  # unquote = line:l "~" level2:e {make(:unquote, l, e)}
  def _unquote

    _save = self.pos
    while true # sequence
      _tmp = apply(:_line)
      l = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string("~")
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_level2)
      e = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; make(:unquote, l, e); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_unquote unless _tmp
    return _tmp
  end

  # prefix = line:l op_letter:o level2:e {make(:prefix, l, e, o)}
  def _prefix

    _save = self.pos
    while true # sequence
      _tmp = apply(:_line)
      l = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_op_letter)
      o = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_level2)
      e = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; make(:prefix, l, e, o); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_prefix unless _tmp
    return _tmp
  end

  # postfix = (line:l postfix:e op_letter:o {make(:postfix, l, e, o)} | line:l level1:e op_letter:o {make(:postfix, l, e, o)})
  def _postfix

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_line)
        l = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_postfix)
        e = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_op_letter)
        o = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; make(:postfix, l, e, o); end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save2 = self.pos
      while true # sequence
        _tmp = apply(:_line)
        l = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_level1)
        e = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_op_letter)
        o = @result
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin; make(:postfix, l, e, o); end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_postfix unless _tmp
    return _tmp
  end

  # block = (line:l ":" wsp expressions?:es (wsp ";")? {make(:block, l, Array(es))} | line:l "{" wsp expressions?:es wsp "}" {make(:block, l, Array(es))})
  def _block

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_line)
        l = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = match_string(":")
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_wsp)
        unless _tmp
          self.pos = _save1
          break
        end
        _save2 = self.pos
        _tmp = apply(:_expressions)
        @result = nil unless _tmp
        unless _tmp
          _tmp = true
          self.pos = _save2
        end
        es = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _save3 = self.pos

        _save4 = self.pos
        while true # sequence
          _tmp = apply(:_wsp)
          unless _tmp
            self.pos = _save4
            break
          end
          _tmp = match_string(";")
          unless _tmp
            self.pos = _save4
          end
          break
        end # end sequence

        unless _tmp
          _tmp = true
          self.pos = _save3
        end
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; make(:block, l, Array(es)); end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save5 = self.pos
      while true # sequence
        _tmp = apply(:_line)
        l = @result
        unless _tmp
          self.pos = _save5
          break
        end
        _tmp = match_string("{")
        unless _tmp
          self.pos = _save5
          break
        end
        _tmp = apply(:_wsp)
        unless _tmp
          self.pos = _save5
          break
        end
        _save6 = self.pos
        _tmp = apply(:_expressions)
        @result = nil unless _tmp
        unless _tmp
          _tmp = true
          self.pos = _save6
        end
        es = @result
        unless _tmp
          self.pos = _save5
          break
        end
        _tmp = apply(:_wsp)
        unless _tmp
          self.pos = _save5
          break
        end
        _tmp = match_string("}")
        unless _tmp
          self.pos = _save5
          break
        end
        @result = begin; make(:block, l, Array(es)); end
        _tmp = true
        unless _tmp
          self.pos = _save5
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_block unless _tmp
    return _tmp
  end

  # list = line:l "[" wsp expressions?:es wsp "]" {make(:list, l, Array(es))}
  def _list

    _save = self.pos
    while true # sequence
      _tmp = apply(:_line)
      l = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string("[")
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_wsp)
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos
      _tmp = apply(:_expressions)
      @result = nil unless _tmp
      unless _tmp
        _tmp = true
        self.pos = _save1
      end
      es = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_wsp)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string("]")
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; make(:list, l, Array(es)); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_list unless _tmp
    return _tmp
  end

  # apply = (line:l apply:a args:as {make(:application, l, a, as)} | line:l name:n args:as {make(:application, l, n, as)})
  def _apply

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_line)
        l = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_apply)
        a = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_args)
        as = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; make(:application, l, a, as); end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save2 = self.pos
      while true # sequence
        _tmp = apply(:_line)
        l = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_name)
        n = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_args)
        as = @result
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin; make(:application, l, n, as); end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_apply unless _tmp
    return _tmp
  end

  # name = (line:l name:n op_letter:o {make(:postfix, l, n, o)} | grouped | level0)
  def _name

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_line)
        l = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_name)
        n = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_op_letter)
        o = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; make(:postfix, l, n, o); end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      _tmp = apply(:_grouped)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_level0)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_name unless _tmp
    return _tmp
  end

  # args = "(" wsp expressions?:as wsp ")" { Array(as) }
  def _args

    _save = self.pos
    while true # sequence
      _tmp = match_string("(")
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_wsp)
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos
      _tmp = apply(:_expressions)
      @result = nil unless _tmp
      unless _tmp
        _tmp = true
        self.pos = _save1
      end
      as = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_wsp)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string(")")
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  Array(as) ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_args unless _tmp
    return _tmp
  end

  # compose = @composes(current_position)
  def _compose
    _tmp = _composes(current_position)
    set_failed_rule :_compose unless _tmp
    return _tmp
  end

  # composes = (line:line compose:l cont(p) level2:r {make(:compose, line, l, r)} | line:line level2:l cont(p) level2:r {make(:compose, line, l, r)})
  def _composes(p)

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_line)
        line = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_compose)
        l = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply_with_args(:_cont, p)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_level2)
        r = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; make(:compose, line, l, r); end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save2 = self.pos
      while true # sequence
        _tmp = apply(:_line)
        line = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_level2)
        l = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply_with_args(:_cont, p)
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_level2)
        r = @result
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin; make(:compose, line, l, r); end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_composes unless _tmp
    return _tmp
  end

  # infix = @infixes(current_position)
  def _infix
    _tmp = _infixes(current_position)
    set_failed_rule :_infix unless _tmp
    return _tmp
  end

  # infixes = (line:line level3:l scont(p) operator:o scont(p) level3:r {make(:infix, line, l, r, o)} | line:line operator:o scont(p) level3:r {make(:infix, line, nil, r, o)})
  def _infixes(p)

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_line)
        line = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_level3)
        l = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply_with_args(:_scont, p)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_operator)
        o = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply_with_args(:_scont, p)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_level3)
        r = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; make(:infix, line, l, r, o); end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save2 = self.pos
      while true # sequence
        _tmp = apply(:_line)
        line = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_operator)
        o = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply_with_args(:_scont, p)
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_level3)
        r = @result
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin; make(:infix, line, nil, r, o); end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_infixes unless _tmp
    return _tmp
  end

  Rules = {}
  Rules[:_root] = rule_info("root", "shebang? wsp expressions?:es wsp !. { sequence(Array(es)) }")
  Rules[:_shebang] = rule_info("shebang", "\"\#!\" /.*?$/")
  Rules[:_expressions] = rule_info("expressions", "{current_column}:c expression:x (delim(c) expression)*:xs {                     [x] + Array(xs)                   }")
  Rules[:_delim] = rule_info("delim", "(wsp \",\" wsp | (sp \"\\n\" sp)+ &{ current_column >= c })")
  Rules[:_expression] = rule_info("expression", "level4")
  Rules[:_one_expression] = rule_info("one_expression", "wsp expression:e wsp !. { e }")
  Rules[:_line] = rule_info("line", "{current_line}")
  Rules[:_cont] = rule_info("cont", "(scont(p) | !\"(\")")
  Rules[:_scont] = rule_info("scont", "((\"\\n\" sp)+ &{ continue?(p) } | sig_sp cont(p)?)")
  Rules[:_sp] = rule_info("sp", "(\" \" | \"\\t\" | comment)*")
  Rules[:_wsp] = rule_info("wsp", "(\" \" | \"\\t\" | \"\\n\" | comment)*")
  Rules[:_sig_sp] = rule_info("sig_sp", "(\" \" | \"\\t\" | comment)+")
  Rules[:_sig_wsp] = rule_info("sig_wsp", "(\" \" | \"\\t\" | \"\\n\" | comment)+")
  Rules[:_comment] = rule_info("comment", "(/--.*?$/ | multi_comment)")
  Rules[:_multi_comment] = rule_info("multi_comment", "\"{-\" in_multi")
  Rules[:_in_multi] = rule_info("in_multi", "(/[^\\-\\{\\}]*/ \"-}\" | /[^\\-\\{\\}]*/ \"{-\" in_multi /[^\\-\\{\\}]*/ \"-}\" | /[^\\-\\{\\}]*/ /[-{}]/ in_multi)")
  Rules[:_op_letter] = rule_info("op_letter", "< /[$+<=>^|~!@\#%&*\\-\\\\.\\/\\?]/ > { text.to_sym }")
  Rules[:_operator] = rule_info("operator", "< op_letter+ > { text.to_sym }")
  Rules[:_identifier] = rule_info("identifier", "< /[a-z_][a-zA-Z\\d\\-_]*/ > { text.tr(\"-\", \"_\").to_sym }")
  Rules[:_language] = rule_info("language", "\"\#language\" wsp identifier:n {set_lang(n)} %lang.root")
  Rules[:_level0] = rule_info("level0", "(number | quote | quasi_quote | unquote | string | constant | word | block | list | prefix)")
  Rules[:_level1] = rule_info("level1", "(apply | grouped | level0)")
  Rules[:_level2] = rule_info("level2", "(postfix | level1)")
  Rules[:_level3] = rule_info("level3", "(compose | level2)")
  Rules[:_level4] = rule_info("level4", "(language | infix | level3)")
  Rules[:_grouped] = rule_info("grouped", "\"(\" wsp expression:x wsp \")\" { x }")
  Rules[:_number] = rule_info("number", "(line:l < /[\\+\\-]?0[oO][0-7]+/ > {make(:number, l, text.to_i(8))} | line:l < /[\\+\\-]?0[xX][\\da-fA-F]+/ > {make(:number, l, text.to_i(16))} | line:l < /[\\+\\-]?\\d+(\\.\\d+)?[eE][\\+\\-]?\\d+/ > {make(:literal, l, text.to_f)} | line:l < /[\\+\\-]?\\d+\\.\\d+/ > {make(:literal, l, text.to_f)} | line:l < /[\\+\\-]?\\d+/ > {make(:number, l, text.to_i)})")
  Rules[:_string] = rule_info("string", "line:line \"\\\"\" < (\"\\\\\" . | /[^\\\\\"]/)*:c > \"\\\"\" {make(:strliteral, line, text.gsub(\"\\\\\\\"\", \"\\\"\"))}")
  Rules[:_constant] = rule_info("constant", "line:l < /[A-Z][a-zA-Z0-9_]*/ > {make(:constant, l, text.to_sym)}")
  Rules[:_word] = rule_info("word", "line:l identifier:n {make(:word, l, n)}")
  Rules[:_quote] = rule_info("quote", "line:l \"'\" level2:e {make(:make, l, :quote, l, e)}")
  Rules[:_quasi_quote] = rule_info("quasi_quote", "line:l \"`\" level2:e {make(:quasiquote, l, e)}")
  Rules[:_unquote] = rule_info("unquote", "line:l \"~\" level2:e {make(:unquote, l, e)}")
  Rules[:_prefix] = rule_info("prefix", "line:l op_letter:o level2:e {make(:prefix, l, e, o)}")
  Rules[:_postfix] = rule_info("postfix", "(line:l postfix:e op_letter:o {make(:postfix, l, e, o)} | line:l level1:e op_letter:o {make(:postfix, l, e, o)})")
  Rules[:_block] = rule_info("block", "(line:l \":\" wsp expressions?:es (wsp \";\")? {make(:block, l, Array(es))} | line:l \"{\" wsp expressions?:es wsp \"}\" {make(:block, l, Array(es))})")
  Rules[:_list] = rule_info("list", "line:l \"[\" wsp expressions?:es wsp \"]\" {make(:list, l, Array(es))}")
  Rules[:_apply] = rule_info("apply", "(line:l apply:a args:as {make(:application, l, a, as)} | line:l name:n args:as {make(:application, l, n, as)})")
  Rules[:_name] = rule_info("name", "(line:l name:n op_letter:o {make(:postfix, l, n, o)} | grouped | level0)")
  Rules[:_args] = rule_info("args", "\"(\" wsp expressions?:as wsp \")\" { Array(as) }")
  Rules[:_compose] = rule_info("compose", "@composes(current_position)")
  Rules[:_composes] = rule_info("composes", "(line:line compose:l cont(p) level2:r {make(:compose, line, l, r)} | line:line level2:l cont(p) level2:r {make(:compose, line, l, r)})")
  Rules[:_infix] = rule_info("infix", "@infixes(current_position)")
  Rules[:_infixes] = rule_info("infixes", "(line:line level3:l scont(p) operator:o scont(p) level3:r {make(:infix, line, l, r, o)} | line:line operator:o scont(p) level3:r {make(:infix, line, nil, r, o)})")
  # :startdoc:
end

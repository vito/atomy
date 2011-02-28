require 'kpeg/compiled_parser'
class Atomo::Parser < KPeg::CompiledParser
  def _line
    @result = begin;  current_line ; end
    _tmp = true
    return _tmp
  end
  def _sp
    while true

    _save1 = self.pos
    while true # choice
    _tmp = match_string(" ")
    break if _tmp
    self.pos = _save1
    _tmp = match_string("\n")
    break if _tmp
    self.pos = _save1
    _tmp = apply('comment', :_comment)
    break if _tmp
    self.pos = _save1
    break
    end # end choice

    break unless _tmp
    end
    _tmp = true
    return _tmp
  end
  def _sig_sp
    _save2 = self.pos

    _save3 = self.pos
    while true # choice
    _tmp = match_string(" ")
    break if _tmp
    self.pos = _save3
    _tmp = match_string("\n")
    break if _tmp
    self.pos = _save3
    _tmp = apply('comment', :_comment)
    break if _tmp
    self.pos = _save3
    break
    end # end choice

    if _tmp
      while true
    
    _save4 = self.pos
    while true # choice
    _tmp = match_string(" ")
    break if _tmp
    self.pos = _save4
    _tmp = match_string("\n")
    break if _tmp
    self.pos = _save4
    _tmp = apply('comment', :_comment)
    break if _tmp
    self.pos = _save4
    break
    end # end choice

        break unless _tmp
      end
      _tmp = true
    else
      self.pos = _save2
    end
    return _tmp
  end
  def _ident_start

    _save5 = self.pos
    while true # sequence
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[[a-z]_])/)
    if _tmp
      set_text(_text_start)
    end
    unless _tmp
      self.pos = _save5
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save5
    end
    break
    end # end sequence

    return _tmp
  end
  def _ident_letters

    _save6 = self.pos
    while true # sequence
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:((?!`)[[:alnum:]\$\+\<=\>\^`~_!@#%&*\-.\/\?])*)/)
    if _tmp
      set_text(_text_start)
    end
    unless _tmp
      self.pos = _save6
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save6
    end
    break
    end # end sequence

    return _tmp
  end
  def _op_start

    _save7 = self.pos
    while true # sequence
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:(?![@#\$~`])[\$\+\<=\>\^`~_!@#%&*\-.\/\?:])/)
    if _tmp
      set_text(_text_start)
    end
    unless _tmp
      self.pos = _save7
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save7
    end
    break
    end # end sequence

    return _tmp
  end
  def _op_letters

    _save8 = self.pos
    while true # sequence
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:((?!`)[\$\+\<=\>\^`~_!@#%&*\-.\/\?:])*)/)
    if _tmp
      set_text(_text_start)
    end
    unless _tmp
      self.pos = _save8
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save8
    end
    break
    end # end sequence

    return _tmp
  end
  def _f_ident_start

    _save9 = self.pos
    while true # sequence
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:(?![&@#\$~`:])[[:alpha:]\$\+\<=\>\^`~_!@#%&*\-.\/\?])/)
    if _tmp
      set_text(_text_start)
    end
    unless _tmp
      self.pos = _save9
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save9
    end
    break
    end # end sequence

    return _tmp
  end
  def _operator

    _save10 = self.pos
    while true # sequence
    _text_start = self.pos

    _save11 = self.pos
    while true # sequence
    _tmp = apply('op_start', :_op_start)
    unless _tmp
      self.pos = _save11
      break
    end
    _tmp = apply('op_letters', :_op_letters)
    unless _tmp
      self.pos = _save11
    end
    break
    end # end sequence

    if _tmp
      set_text(_text_start)
    end
    unless _tmp
      self.pos = _save10
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save10
    end
    break
    end # end sequence

    return _tmp
  end
  def _identifier

    _save12 = self.pos
    while true # sequence
    _text_start = self.pos

    _save13 = self.pos
    while true # sequence
    _tmp = apply('ident_start', :_ident_start)
    unless _tmp
      self.pos = _save13
      break
    end
    _tmp = apply('ident_letters', :_ident_letters)
    unless _tmp
      self.pos = _save13
    end
    break
    end # end sequence

    if _tmp
      set_text(_text_start)
    end
    unless _tmp
      self.pos = _save12
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save12
    end
    break
    end # end sequence

    return _tmp
  end
  def _f_identifier

    _save14 = self.pos
    while true # sequence
    _text_start = self.pos

    _save15 = self.pos
    while true # sequence
    _tmp = apply('f_ident_start', :_f_ident_start)
    unless _tmp
      self.pos = _save15
      break
    end
    _tmp = apply('ident_letters', :_ident_letters)
    unless _tmp
      self.pos = _save15
    end
    break
    end # end sequence

    if _tmp
      set_text(_text_start)
    end
    unless _tmp
      self.pos = _save14
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save14
    end
    break
    end # end sequence

    return _tmp
  end
  def _grouped

    _save16 = self.pos
    while true # sequence
    _tmp = match_string("(")
    unless _tmp
      self.pos = _save16
      break
    end
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save16
      break
    end
    _tmp = apply('expression', :_expression)
    x = @result
    unless _tmp
      self.pos = _save16
      break
    end
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save16
      break
    end
    _tmp = match_string(")")
    unless _tmp
      self.pos = _save16
      break
    end
    @result = begin;  x ; end
    _tmp = true
    unless _tmp
      self.pos = _save16
    end
    break
    end # end sequence

    return _tmp
  end
  def _comment

    _save17 = self.pos
    while true # choice
    _tmp = scan(/\A(?-mix:--.*?$)/)
    break if _tmp
    self.pos = _save17
    _tmp = apply('multi_comment', :_multi_comment)
    break if _tmp
    self.pos = _save17
    break
    end # end choice

    return _tmp
  end
  def _multi_comment

    _save18 = self.pos
    while true # sequence
    _tmp = match_string("{-")
    unless _tmp
      self.pos = _save18
      break
    end
    _tmp = apply('in_multi', :_in_multi)
    unless _tmp
      self.pos = _save18
    end
    break
    end # end sequence

    return _tmp
  end
  def _in_multi

    _save19 = self.pos
    while true # choice

    _save20 = self.pos
    while true # sequence
    _tmp = scan(/\A(?-mix:[^\-\{\}]*)/)
    unless _tmp
      self.pos = _save20
      break
    end
    _tmp = match_string("-}")
    unless _tmp
      self.pos = _save20
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save19

    _save21 = self.pos
    while true # sequence
    _tmp = scan(/\A(?-mix:[^\-\{\}]*)/)
    unless _tmp
      self.pos = _save21
      break
    end
    _tmp = match_string("{-")
    unless _tmp
      self.pos = _save21
      break
    end
    _tmp = apply('in_multi', :_in_multi)
    unless _tmp
      self.pos = _save21
      break
    end
    _tmp = scan(/\A(?-mix:[^\-\{\}]*)/)
    unless _tmp
      self.pos = _save21
      break
    end
    _tmp = match_string("-}")
    unless _tmp
      self.pos = _save21
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save19

    _save22 = self.pos
    while true # sequence
    _tmp = scan(/\A(?-mix:[^\-\{\}]*)/)
    unless _tmp
      self.pos = _save22
      break
    end
    _tmp = scan(/\A(?-mix:[-{}])/)
    unless _tmp
      self.pos = _save22
      break
    end
    _tmp = apply('in_multi', :_in_multi)
    unless _tmp
      self.pos = _save22
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save19
    break
    end # end choice

    return _tmp
  end
  def _delim

    _save23 = self.pos
    while true # choice
    _tmp = match_string(",")
    break if _tmp
    self.pos = _save23
    _tmp = match_string(";")
    break if _tmp
    self.pos = _save23
    break
    end # end choice

    return _tmp
  end
  def _expression
    _tmp = apply('level4', :_level4)
    return _tmp
  end
  def _expressions

    _save24 = self.pos
    while true # sequence
    _tmp = apply('expression', :_expression)
    x = @result
    unless _tmp
      self.pos = _save24
      break
    end
    _ary = []
    while true

    _save26 = self.pos
    while true # sequence
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save26
      break
    end
    _tmp = apply('delim', :_delim)
    unless _tmp
      self.pos = _save26
      break
    end
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save26
      break
    end
    _tmp = apply('expression', :_expression)
    y = @result
    unless _tmp
      self.pos = _save26
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
      self.pos = _save24
      break
    end
    _save27 = self.pos
    _tmp = apply('delim', :_delim)
    unless _tmp
      _tmp = true
      self.pos = _save27
    end
    unless _tmp
      self.pos = _save24
      break
    end
    @result = begin;  [x] + Array(xs) ; end
    _tmp = true
    unless _tmp
      self.pos = _save24
    end
    break
    end # end sequence

    return _tmp
  end
  def _level1

    _save28 = self.pos
    while true # choice
    _tmp = apply('true', :_true)
    break if _tmp
    self.pos = _save28
    _tmp = apply('false', :_false)
    break if _tmp
    self.pos = _save28
    _tmp = apply('self', :_self)
    break if _tmp
    self.pos = _save28
    _tmp = apply('nil', :_nil)
    break if _tmp
    self.pos = _save28
    _tmp = apply('number', :_number)
    break if _tmp
    self.pos = _save28
    _tmp = apply('macro', :_macro)
    break if _tmp
    self.pos = _save28
    _tmp = apply('for_macro', :_for_macro)
    break if _tmp
    self.pos = _save28
    _tmp = apply('quote', :_quote)
    break if _tmp
    self.pos = _save28
    _tmp = apply('quasi_quote', :_quasi_quote)
    break if _tmp
    self.pos = _save28
    _tmp = apply('unquote', :_unquote)
    break if _tmp
    self.pos = _save28
    _tmp = apply('string', :_string)
    break if _tmp
    self.pos = _save28
    _tmp = apply('particle', :_particle)
    break if _tmp
    self.pos = _save28
    _tmp = apply('block_pass', :_block_pass)
    break if _tmp
    self.pos = _save28
    _tmp = apply('constant', :_constant)
    break if _tmp
    self.pos = _save28
    _tmp = apply('variable', :_variable)
    break if _tmp
    self.pos = _save28
    _tmp = apply('g_variable', :_g_variable)
    break if _tmp
    self.pos = _save28
    _tmp = apply('c_variable', :_c_variable)
    break if _tmp
    self.pos = _save28
    _tmp = apply('i_variable', :_i_variable)
    break if _tmp
    self.pos = _save28
    _tmp = apply('tuple', :_tuple)
    break if _tmp
    self.pos = _save28
    _tmp = apply('grouped', :_grouped)
    break if _tmp
    self.pos = _save28
    _tmp = apply('block', :_block)
    break if _tmp
    self.pos = _save28
    _tmp = apply('list', :_list)
    break if _tmp
    self.pos = _save28
    break
    end # end choice

    return _tmp
  end
  def _level2

    _save29 = self.pos
    while true # choice
    _tmp = apply('unary_send', :_unary_send)
    break if _tmp
    self.pos = _save29
    _tmp = apply('level1', :_level1)
    break if _tmp
    self.pos = _save29
    break
    end # end choice

    return _tmp
  end
  def _level3

    _save30 = self.pos
    while true # choice
    _tmp = apply('keyword_send', :_keyword_send)
    break if _tmp
    self.pos = _save30
    _tmp = apply('level2', :_level2)
    break if _tmp
    self.pos = _save30
    break
    end # end choice

    return _tmp
  end
  def _level4

    _save31 = self.pos
    while true # choice
    _tmp = apply('binary_send', :_binary_send)
    break if _tmp
    self.pos = _save31
    _tmp = apply('level3', :_level3)
    break if _tmp
    self.pos = _save31
    break
    end # end choice

    return _tmp
  end
  def _true

    _save32 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save32
      break
    end
    _tmp = match_string("True")
    unless _tmp
      self.pos = _save32
      break
    end
    @result = begin;  Atomo::AST::Primitive.new(line, :true) ; end
    _tmp = true
    unless _tmp
      self.pos = _save32
    end
    break
    end # end sequence

    return _tmp
  end
  def _false

    _save33 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save33
      break
    end
    _tmp = match_string("False")
    unless _tmp
      self.pos = _save33
      break
    end
    @result = begin;  Atomo::AST::Primitive.new(line, :false) ; end
    _tmp = true
    unless _tmp
      self.pos = _save33
    end
    break
    end # end sequence

    return _tmp
  end
  def _self

    _save34 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save34
      break
    end
    _tmp = match_string("self")
    unless _tmp
      self.pos = _save34
      break
    end
    @result = begin;  Atomo::AST::Primitive.new(line, :self) ; end
    _tmp = true
    unless _tmp
      self.pos = _save34
    end
    break
    end # end sequence

    return _tmp
  end
  def _nil

    _save35 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save35
      break
    end
    _tmp = match_string("nil")
    unless _tmp
      self.pos = _save35
      break
    end
    @result = begin;  Atomo::AST::Primitive.new(line, :nil) ; end
    _tmp = true
    unless _tmp
      self.pos = _save35
    end
    break
    end # end sequence

    return _tmp
  end
  def _number

    _save36 = self.pos
    while true # choice

    _save37 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save37
      break
    end
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[\+\-]?\d+)/)
    if _tmp
      set_text(_text_start)
    end
    unless _tmp
      self.pos = _save37
      break
    end
    @result = begin;  Atomo::AST::Primitive.new(line, text.to_i) ; end
    _tmp = true
    unless _tmp
      self.pos = _save37
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save36

    _save38 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save38
      break
    end
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[\+\-]?0[oO][\da-fA-F]+)/)
    if _tmp
      set_text(_text_start)
    end
    unless _tmp
      self.pos = _save38
      break
    end
    @result = begin;  Atomo::AST::Primitive.new(line, text.to_i(8)) ; end
    _tmp = true
    unless _tmp
      self.pos = _save38
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save36

    _save39 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save39
      break
    end
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[\+\-]?0[xX][0-7]+)/)
    if _tmp
      set_text(_text_start)
    end
    unless _tmp
      self.pos = _save39
      break
    end
    @result = begin;  Atomo::AST::Primitive.new(line, text.to_i(16)) ; end
    _tmp = true
    unless _tmp
      self.pos = _save39
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save36

    _save40 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save40
      break
    end
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[\+\-]?\d+(\.\d+)?[eE][\+\-]?\d+)/)
    if _tmp
      set_text(_text_start)
    end
    unless _tmp
      self.pos = _save40
      break
    end
    @result = begin;  Atomo::AST::Primitive.new(line, text.to_f) ; end
    _tmp = true
    unless _tmp
      self.pos = _save40
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save36
    break
    end # end choice

    return _tmp
  end
  def _macro

    _save41 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save41
      break
    end
    _tmp = match_string("macro")
    unless _tmp
      self.pos = _save41
      break
    end
    _tmp = apply('sig_sp', :_sig_sp)
    unless _tmp
      self.pos = _save41
      break
    end
    _tmp = match_string("(")
    unless _tmp
      self.pos = _save41
      break
    end
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save41
      break
    end
    _tmp = apply('expression', :_expression)
    p = @result
    unless _tmp
      self.pos = _save41
      break
    end
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save41
      break
    end
    _tmp = match_string(")")
    unless _tmp
      self.pos = _save41
      break
    end
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save41
      break
    end
    _tmp = apply('expression', :_expression)
    b = @result
    unless _tmp
      self.pos = _save41
      break
    end
    @result = begin;  b; Atomo::AST::Macro.new(line, p, b) ; end
    _tmp = true
    unless _tmp
      self.pos = _save41
    end
    break
    end # end sequence

    return _tmp
  end
  def _for_macro

    _save42 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save42
      break
    end
    _tmp = match_string("for-macro")
    unless _tmp
      self.pos = _save42
      break
    end
    _tmp = apply('sig_sp', :_sig_sp)
    unless _tmp
      self.pos = _save42
      break
    end
    _tmp = apply('expression', :_expression)
    b = @result
    unless _tmp
      self.pos = _save42
      break
    end
    @result = begin;  Atomo::AST::ForMacro.new(line, b) ; end
    _tmp = true
    unless _tmp
      self.pos = _save42
    end
    break
    end # end sequence

    return _tmp
  end
  def _quote

    _save43 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save43
      break
    end
    _tmp = match_string("'")
    unless _tmp
      self.pos = _save43
      break
    end
    _tmp = apply('level1', :_level1)
    e = @result
    unless _tmp
      self.pos = _save43
      break
    end
    @result = begin;  Atomo::AST::Quote.new(line, e) ; end
    _tmp = true
    unless _tmp
      self.pos = _save43
    end
    break
    end # end sequence

    return _tmp
  end
  def _quasi_quote

    _save44 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save44
      break
    end
    _tmp = match_string("`")
    unless _tmp
      self.pos = _save44
      break
    end
    _tmp = apply('level1', :_level1)
    e = @result
    unless _tmp
      self.pos = _save44
      break
    end
    @result = begin;  Atomo::AST::QuasiQuote.new(line, e) ; end
    _tmp = true
    unless _tmp
      self.pos = _save44
    end
    break
    end # end sequence

    return _tmp
  end
  def _unquote

    _save45 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save45
      break
    end
    _tmp = match_string("~")
    unless _tmp
      self.pos = _save45
      break
    end
    _tmp = apply('level1', :_level1)
    e = @result
    unless _tmp
      self.pos = _save45
      break
    end
    @result = begin;  Atomo::AST::Unquote.new(line, e) ; end
    _tmp = true
    unless _tmp
      self.pos = _save45
    end
    break
    end # end sequence

    return _tmp
  end
  def _escapes

    _save46 = self.pos
    while true # choice

    _save47 = self.pos
    while true # sequence
    _tmp = match_string("n")
    unless _tmp
      self.pos = _save47
      break
    end
    @result = begin;  "\n" ; end
    _tmp = true
    unless _tmp
      self.pos = _save47
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save48 = self.pos
    while true # sequence
    _tmp = match_string("s")
    unless _tmp
      self.pos = _save48
      break
    end
    @result = begin;  " " ; end
    _tmp = true
    unless _tmp
      self.pos = _save48
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save49 = self.pos
    while true # sequence
    _tmp = match_string("r")
    unless _tmp
      self.pos = _save49
      break
    end
    @result = begin;  "\r" ; end
    _tmp = true
    unless _tmp
      self.pos = _save49
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save50 = self.pos
    while true # sequence
    _tmp = match_string("t")
    unless _tmp
      self.pos = _save50
      break
    end
    @result = begin;  "\t" ; end
    _tmp = true
    unless _tmp
      self.pos = _save50
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save51 = self.pos
    while true # sequence
    _tmp = match_string("v")
    unless _tmp
      self.pos = _save51
      break
    end
    @result = begin;  "\v" ; end
    _tmp = true
    unless _tmp
      self.pos = _save51
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save52 = self.pos
    while true # sequence
    _tmp = match_string("f")
    unless _tmp
      self.pos = _save52
      break
    end
    @result = begin;  "\f" ; end
    _tmp = true
    unless _tmp
      self.pos = _save52
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save53 = self.pos
    while true # sequence
    _tmp = match_string("b")
    unless _tmp
      self.pos = _save53
      break
    end
    @result = begin;  "\b" ; end
    _tmp = true
    unless _tmp
      self.pos = _save53
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save54 = self.pos
    while true # sequence
    _tmp = match_string("a")
    unless _tmp
      self.pos = _save54
      break
    end
    @result = begin;  "\a" ; end
    _tmp = true
    unless _tmp
      self.pos = _save54
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save55 = self.pos
    while true # sequence
    _tmp = match_string("e")
    unless _tmp
      self.pos = _save55
      break
    end
    @result = begin;  "\e" ; end
    _tmp = true
    unless _tmp
      self.pos = _save55
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save56 = self.pos
    while true # sequence
    _tmp = match_string("\\")
    unless _tmp
      self.pos = _save56
      break
    end
    @result = begin;  "\\" ; end
    _tmp = true
    unless _tmp
      self.pos = _save56
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save57 = self.pos
    while true # sequence
    _tmp = match_string("\"")
    unless _tmp
      self.pos = _save57
      break
    end
    @result = begin;  "\"" ; end
    _tmp = true
    unless _tmp
      self.pos = _save57
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save58 = self.pos
    while true # sequence
    _tmp = match_string("BS")
    unless _tmp
      self.pos = _save58
      break
    end
    @result = begin;  "\b" ; end
    _tmp = true
    unless _tmp
      self.pos = _save58
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save59 = self.pos
    while true # sequence
    _tmp = match_string("HT")
    unless _tmp
      self.pos = _save59
      break
    end
    @result = begin;  "\t" ; end
    _tmp = true
    unless _tmp
      self.pos = _save59
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save60 = self.pos
    while true # sequence
    _tmp = match_string("LF")
    unless _tmp
      self.pos = _save60
      break
    end
    @result = begin;  "\n" ; end
    _tmp = true
    unless _tmp
      self.pos = _save60
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save61 = self.pos
    while true # sequence
    _tmp = match_string("VT")
    unless _tmp
      self.pos = _save61
      break
    end
    @result = begin;  "\v" ; end
    _tmp = true
    unless _tmp
      self.pos = _save61
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save62 = self.pos
    while true # sequence
    _tmp = match_string("FF")
    unless _tmp
      self.pos = _save62
      break
    end
    @result = begin;  "\f" ; end
    _tmp = true
    unless _tmp
      self.pos = _save62
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save63 = self.pos
    while true # sequence
    _tmp = match_string("CR")
    unless _tmp
      self.pos = _save63
      break
    end
    @result = begin;  "\r" ; end
    _tmp = true
    unless _tmp
      self.pos = _save63
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save64 = self.pos
    while true # sequence
    _tmp = match_string("SO")
    unless _tmp
      self.pos = _save64
      break
    end
    @result = begin;  "\016" ; end
    _tmp = true
    unless _tmp
      self.pos = _save64
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save65 = self.pos
    while true # sequence
    _tmp = match_string("SI")
    unless _tmp
      self.pos = _save65
      break
    end
    @result = begin;  "\017" ; end
    _tmp = true
    unless _tmp
      self.pos = _save65
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save66 = self.pos
    while true # sequence
    _tmp = match_string("EM")
    unless _tmp
      self.pos = _save66
      break
    end
    @result = begin;  "\031" ; end
    _tmp = true
    unless _tmp
      self.pos = _save66
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save67 = self.pos
    while true # sequence
    _tmp = match_string("FS")
    unless _tmp
      self.pos = _save67
      break
    end
    @result = begin;  "\034" ; end
    _tmp = true
    unless _tmp
      self.pos = _save67
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save68 = self.pos
    while true # sequence
    _tmp = match_string("GS")
    unless _tmp
      self.pos = _save68
      break
    end
    @result = begin;  "\035" ; end
    _tmp = true
    unless _tmp
      self.pos = _save68
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save69 = self.pos
    while true # sequence
    _tmp = match_string("RS")
    unless _tmp
      self.pos = _save69
      break
    end
    @result = begin;  "\036" ; end
    _tmp = true
    unless _tmp
      self.pos = _save69
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save70 = self.pos
    while true # sequence
    _tmp = match_string("US")
    unless _tmp
      self.pos = _save70
      break
    end
    @result = begin;  "\037" ; end
    _tmp = true
    unless _tmp
      self.pos = _save70
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save71 = self.pos
    while true # sequence
    _tmp = match_string("SP")
    unless _tmp
      self.pos = _save71
      break
    end
    @result = begin;  " " ; end
    _tmp = true
    unless _tmp
      self.pos = _save71
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save72 = self.pos
    while true # sequence
    _tmp = match_string("NUL")
    unless _tmp
      self.pos = _save72
      break
    end
    @result = begin;  "\000" ; end
    _tmp = true
    unless _tmp
      self.pos = _save72
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save73 = self.pos
    while true # sequence
    _tmp = match_string("SOH")
    unless _tmp
      self.pos = _save73
      break
    end
    @result = begin;  "\001" ; end
    _tmp = true
    unless _tmp
      self.pos = _save73
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save74 = self.pos
    while true # sequence
    _tmp = match_string("STX")
    unless _tmp
      self.pos = _save74
      break
    end
    @result = begin;  "\002" ; end
    _tmp = true
    unless _tmp
      self.pos = _save74
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save75 = self.pos
    while true # sequence
    _tmp = match_string("ETX")
    unless _tmp
      self.pos = _save75
      break
    end
    @result = begin;  "\003" ; end
    _tmp = true
    unless _tmp
      self.pos = _save75
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save76 = self.pos
    while true # sequence
    _tmp = match_string("EOT")
    unless _tmp
      self.pos = _save76
      break
    end
    @result = begin;  "\004" ; end
    _tmp = true
    unless _tmp
      self.pos = _save76
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save77 = self.pos
    while true # sequence
    _tmp = match_string("ENQ")
    unless _tmp
      self.pos = _save77
      break
    end
    @result = begin;  "\005" ; end
    _tmp = true
    unless _tmp
      self.pos = _save77
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save78 = self.pos
    while true # sequence
    _tmp = match_string("ACK")
    unless _tmp
      self.pos = _save78
      break
    end
    @result = begin;  "\006" ; end
    _tmp = true
    unless _tmp
      self.pos = _save78
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save79 = self.pos
    while true # sequence
    _tmp = match_string("BEL")
    unless _tmp
      self.pos = _save79
      break
    end
    @result = begin;  "\a" ; end
    _tmp = true
    unless _tmp
      self.pos = _save79
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save80 = self.pos
    while true # sequence
    _tmp = match_string("DLE")
    unless _tmp
      self.pos = _save80
      break
    end
    @result = begin;  "\020" ; end
    _tmp = true
    unless _tmp
      self.pos = _save80
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save81 = self.pos
    while true # sequence
    _tmp = match_string("DC1")
    unless _tmp
      self.pos = _save81
      break
    end
    @result = begin;  "\021" ; end
    _tmp = true
    unless _tmp
      self.pos = _save81
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save82 = self.pos
    while true # sequence
    _tmp = match_string("DC2")
    unless _tmp
      self.pos = _save82
      break
    end
    @result = begin;  "\022" ; end
    _tmp = true
    unless _tmp
      self.pos = _save82
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save83 = self.pos
    while true # sequence
    _tmp = match_string("DC3")
    unless _tmp
      self.pos = _save83
      break
    end
    @result = begin;  "\023" ; end
    _tmp = true
    unless _tmp
      self.pos = _save83
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save84 = self.pos
    while true # sequence
    _tmp = match_string("DC4")
    unless _tmp
      self.pos = _save84
      break
    end
    @result = begin;  "\024" ; end
    _tmp = true
    unless _tmp
      self.pos = _save84
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save85 = self.pos
    while true # sequence
    _tmp = match_string("NAK")
    unless _tmp
      self.pos = _save85
      break
    end
    @result = begin;  "\025" ; end
    _tmp = true
    unless _tmp
      self.pos = _save85
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save86 = self.pos
    while true # sequence
    _tmp = match_string("SYN")
    unless _tmp
      self.pos = _save86
      break
    end
    @result = begin;  "\026" ; end
    _tmp = true
    unless _tmp
      self.pos = _save86
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save87 = self.pos
    while true # sequence
    _tmp = match_string("ETB")
    unless _tmp
      self.pos = _save87
      break
    end
    @result = begin;  "\027" ; end
    _tmp = true
    unless _tmp
      self.pos = _save87
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save88 = self.pos
    while true # sequence
    _tmp = match_string("CAN")
    unless _tmp
      self.pos = _save88
      break
    end
    @result = begin;  "\030" ; end
    _tmp = true
    unless _tmp
      self.pos = _save88
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save89 = self.pos
    while true # sequence
    _tmp = match_string("SUB")
    unless _tmp
      self.pos = _save89
      break
    end
    @result = begin;  "\032" ; end
    _tmp = true
    unless _tmp
      self.pos = _save89
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save90 = self.pos
    while true # sequence
    _tmp = match_string("ESC")
    unless _tmp
      self.pos = _save90
      break
    end
    @result = begin;  "\e" ; end
    _tmp = true
    unless _tmp
      self.pos = _save90
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46

    _save91 = self.pos
    while true # sequence
    _tmp = match_string("DEL")
    unless _tmp
      self.pos = _save91
      break
    end
    @result = begin;  "\177" ; end
    _tmp = true
    unless _tmp
      self.pos = _save91
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save46
    break
    end # end choice

    return _tmp
  end
  def _number_escapes

    _save92 = self.pos
    while true # choice

    _save93 = self.pos
    while true # sequence
    _tmp = scan(/\A(?-mix:[xX])/)
    unless _tmp
      self.pos = _save93
      break
    end
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[0-9a-fA-F]{1,5})/)
    if _tmp
      set_text(_text_start)
    end
    unless _tmp
      self.pos = _save93
      break
    end
    @result = begin;  text.to_i(16).chr ; end
    _tmp = true
    unless _tmp
      self.pos = _save93
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save92

    _save94 = self.pos
    while true # sequence
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:\d{1,6})/)
    if _tmp
      set_text(_text_start)
    end
    unless _tmp
      self.pos = _save94
      break
    end
    @result = begin;  text.to_i.chr ; end
    _tmp = true
    unless _tmp
      self.pos = _save94
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save92

    _save95 = self.pos
    while true # sequence
    _tmp = scan(/\A(?-mix:[oO])/)
    unless _tmp
      self.pos = _save95
      break
    end
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[0-7]{1,7})/)
    if _tmp
      set_text(_text_start)
    end
    unless _tmp
      self.pos = _save95
      break
    end
    @result = begin;  text.to_i(16).chr ; end
    _tmp = true
    unless _tmp
      self.pos = _save95
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save92

    _save96 = self.pos
    while true # sequence
    _tmp = scan(/\A(?-mix:[uU])/)
    unless _tmp
      self.pos = _save96
      break
    end
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[0-9a-fA-F]{4})/)
    if _tmp
      set_text(_text_start)
    end
    unless _tmp
      self.pos = _save96
      break
    end
    @result = begin;  text.to_i(16).chr ; end
    _tmp = true
    unless _tmp
      self.pos = _save96
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save92
    break
    end # end choice

    return _tmp
  end
  def _escape

    _save97 = self.pos
    while true # choice
    _tmp = apply('number_escapes', :_number_escapes)
    break if _tmp
    self.pos = _save97
    _tmp = apply('escapes', :_escapes)
    break if _tmp
    self.pos = _save97
    break
    end # end choice

    return _tmp
  end
  def _str_seq

    _save98 = self.pos
    while true # sequence
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[^\\"]+)/)
    if _tmp
      set_text(_text_start)
    end
    unless _tmp
      self.pos = _save98
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save98
    end
    break
    end # end sequence

    return _tmp
  end
  def _string

    _save99 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save99
      break
    end
    _tmp = match_string("\"")
    unless _tmp
      self.pos = _save99
      break
    end
    _ary = []
    while true

    _save101 = self.pos
    while true # choice

    _save102 = self.pos
    while true # sequence
    _tmp = match_string("\\")
    unless _tmp
      self.pos = _save102
      break
    end
    _tmp = apply('escape', :_escape)
    unless _tmp
      self.pos = _save102
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save101
    _tmp = apply('str_seq', :_str_seq)
    break if _tmp
    self.pos = _save101
    break
    end # end choice

    _ary << @result if _tmp
    break unless _tmp
    end
    _tmp = true
    @result = _ary
    c = @result
    unless _tmp
      self.pos = _save99
      break
    end
    _tmp = match_string("\"")
    unless _tmp
      self.pos = _save99
      break
    end
    @result = begin;  Atomo::AST::String.new(line, c.join) ; end
    _tmp = true
    unless _tmp
      self.pos = _save99
    end
    break
    end # end sequence

    return _tmp
  end
  def _particle

    _save103 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save103
      break
    end
    _tmp = match_string("#")
    unless _tmp
      self.pos = _save103
      break
    end
    _tmp = apply('f_identifier', :_f_identifier)
    n = @result
    unless _tmp
      self.pos = _save103
      break
    end
    @result = begin;  Atomo::AST::Particle.new(line, n) ; end
    _tmp = true
    unless _tmp
      self.pos = _save103
    end
    break
    end # end sequence

    return _tmp
  end
  def _block_pass

    _save104 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save104
      break
    end
    _tmp = match_string("&")
    unless _tmp
      self.pos = _save104
      break
    end
    _tmp = apply('level1', :_level1)
    b = @result
    unless _tmp
      self.pos = _save104
      break
    end
    @result = begin;  Atomo::AST::BlockPass.new(line, b) ; end
    _tmp = true
    unless _tmp
      self.pos = _save104
    end
    break
    end # end sequence

    return _tmp
  end
  def _constant_name

    _save105 = self.pos
    while true # sequence
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[A-Z][a-zA-Z0-9_]*)/)
    if _tmp
      set_text(_text_start)
    end
    unless _tmp
      self.pos = _save105
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save105
    end
    break
    end # end sequence

    return _tmp
  end
  def _constant

    _save106 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save106
      break
    end
    _tmp = apply('constant_name', :_constant_name)
    m = @result
    unless _tmp
      self.pos = _save106
      break
    end
    _ary = []
    while true

    _save108 = self.pos
    while true # sequence
    _tmp = match_string("::")
    unless _tmp
      self.pos = _save108
      break
    end
    _tmp = apply('constant_name', :_constant_name)
    unless _tmp
      self.pos = _save108
    end
    break
    end # end sequence

    _ary << @result if _tmp
    break unless _tmp
    end
    _tmp = true
    @result = _ary
    s = @result
    unless _tmp
      self.pos = _save106
      break
    end
    @result = begin;  Atomo::AST::Constant.new(line, [m] + Array(s)) ; end
    _tmp = true
    unless _tmp
      self.pos = _save106
    end
    break
    end # end sequence

    return _tmp
  end
  def _variable

    _save109 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save109
      break
    end
    _tmp = apply('identifier', :_identifier)
    n = @result
    unless _tmp
      self.pos = _save109
      break
    end
    @result = begin;  Atomo::AST::Variable.new(line, n) ; end
    _tmp = true
    unless _tmp
      self.pos = _save109
    end
    break
    end # end sequence

    return _tmp
  end
  def _g_variable

    _save110 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save110
      break
    end
    _tmp = match_string("$")
    unless _tmp
      self.pos = _save110
      break
    end
    _tmp = apply('f_identifier', :_f_identifier)
    n = @result
    unless _tmp
      self.pos = _save110
      break
    end
    @result = begin;  Atomo::AST::GlobalVariable.new(line, n) ; end
    _tmp = true
    unless _tmp
      self.pos = _save110
    end
    break
    end # end sequence

    return _tmp
  end
  def _c_variable

    _save111 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save111
      break
    end
    _tmp = match_string("@@")
    unless _tmp
      self.pos = _save111
      break
    end
    _tmp = apply('f_identifier', :_f_identifier)
    n = @result
    unless _tmp
      self.pos = _save111
      break
    end
    @result = begin;  Atomo::AST::ClassVariable.new(line, n) ; end
    _tmp = true
    unless _tmp
      self.pos = _save111
    end
    break
    end # end sequence

    return _tmp
  end
  def _i_variable

    _save112 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save112
      break
    end
    _tmp = match_string("@")
    unless _tmp
      self.pos = _save112
      break
    end
    _tmp = apply('f_identifier', :_f_identifier)
    n = @result
    unless _tmp
      self.pos = _save112
      break
    end
    @result = begin;  Atomo::AST::InstanceVariable.new(line, n) ; end
    _tmp = true
    unless _tmp
      self.pos = _save112
    end
    break
    end # end sequence

    return _tmp
  end
  def _tuple

    _save113 = self.pos
    while true # choice

    _save114 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save114
      break
    end
    _tmp = match_string("(")
    unless _tmp
      self.pos = _save114
      break
    end
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save114
      break
    end
    _tmp = apply('expression', :_expression)
    e = @result
    unless _tmp
      self.pos = _save114
      break
    end
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save114
      break
    end
    _tmp = apply('delim', :_delim)
    unless _tmp
      self.pos = _save114
      break
    end
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save114
      break
    end
    _tmp = apply('expressions', :_expressions)
    es = @result
    unless _tmp
      self.pos = _save114
      break
    end
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save114
      break
    end
    _tmp = match_string(")")
    unless _tmp
      self.pos = _save114
      break
    end
    @result = begin;  Atomo::AST::Tuple.new(line, [e] + Array(es)) ; end
    _tmp = true
    unless _tmp
      self.pos = _save114
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save113

    _save115 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save115
      break
    end
    _tmp = match_string("(")
    unless _tmp
      self.pos = _save115
      break
    end
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save115
      break
    end
    _tmp = match_string(")")
    unless _tmp
      self.pos = _save115
      break
    end
    @result = begin;  Atomo::AST::Tuple.new(line, []) ; end
    _tmp = true
    unless _tmp
      self.pos = _save115
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save113
    break
    end # end choice

    return _tmp
  end
  def _block_args

    _save116 = self.pos
    while true # sequence
    _save117 = self.pos
    _ary = []

    _save118 = self.pos
    while true # sequence
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save118
      break
    end
    _tmp = apply('level1', :_level1)
    n = @result
    unless _tmp
      self.pos = _save118
    end
    break
    end # end sequence

    if _tmp
      _ary << @result
      while true
    
    _save119 = self.pos
    while true # sequence
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save119
      break
    end
    _tmp = apply('level1', :_level1)
    n = @result
    unless _tmp
      self.pos = _save119
    end
    break
    end # end sequence

        _ary << @result if _tmp
        break unless _tmp
      end
      _tmp = true
      @result = _ary
    else
      self.pos = _save117
    end
    as = @result
    unless _tmp
      self.pos = _save116
      break
    end
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save116
      break
    end
    _tmp = match_string("|")
    unless _tmp
      self.pos = _save116
      break
    end
    @result = begin;  as ; end
    _tmp = true
    unless _tmp
      self.pos = _save116
    end
    break
    end # end sequence

    return _tmp
  end
  def _block

    _save120 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save120
      break
    end
    _tmp = match_string("{")
    unless _tmp
      self.pos = _save120
      break
    end
    _save121 = self.pos
    _tmp = apply('block_args', :_block_args)
    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save121
    end
    as = @result
    unless _tmp
      self.pos = _save120
      break
    end
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save120
      break
    end
    _save122 = self.pos
    _tmp = apply('expressions', :_expressions)
    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save122
    end
    es = @result
    unless _tmp
      self.pos = _save120
      break
    end
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save120
      break
    end
    _tmp = match_string("}")
    unless _tmp
      self.pos = _save120
      break
    end
    @result = begin;  Atomo::AST::Block.new(line, Array(es), Array(as)) ; end
    _tmp = true
    unless _tmp
      self.pos = _save120
    end
    break
    end # end sequence

    return _tmp
  end
  def _list

    _save123 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save123
      break
    end
    _tmp = match_string("[")
    unless _tmp
      self.pos = _save123
      break
    end
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save123
      break
    end
    _save124 = self.pos
    _tmp = apply('expressions', :_expressions)
    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save124
    end
    es = @result
    unless _tmp
      self.pos = _save123
      break
    end
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save123
      break
    end
    _tmp = match_string("]")
    unless _tmp
      self.pos = _save123
      break
    end
    @result = begin;  Atomo::AST::List.new(line, Array(es)) ; end
    _tmp = true
    unless _tmp
      self.pos = _save123
    end
    break
    end # end sequence

    return _tmp
  end
  def _unary_args

    _save125 = self.pos
    while true # sequence
    _tmp = match_string("(")
    unless _tmp
      self.pos = _save125
      break
    end
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save125
      break
    end
    _save126 = self.pos
    _tmp = apply('expressions', :_expressions)
    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save126
    end
    as = @result
    unless _tmp
      self.pos = _save125
      break
    end
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save125
      break
    end
    _tmp = match_string(")")
    unless _tmp
      self.pos = _save125
      break
    end
    @result = begin;  as ; end
    _tmp = true
    unless _tmp
      self.pos = _save125
    end
    break
    end # end sequence

    return _tmp
  end
  def _unary_send

    _save127 = self.pos
    while true # choice

    _save128 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save128
      break
    end
    _tmp = apply('unary_send', :_unary_send)
    r = @result
    unless _tmp
      self.pos = _save128
      break
    end
    _tmp = apply('sig_sp', :_sig_sp)
    unless _tmp
      self.pos = _save128
      break
    end
    _tmp = apply('identifier', :_identifier)
    n = @result
    unless _tmp
      self.pos = _save128
      break
    end
    _save129 = self.pos
    _tmp = match_string(":")
    self.pos = _save129
    _tmp = _tmp ? nil : true
    unless _tmp
      self.pos = _save128
      break
    end
    _save130 = self.pos
    _tmp = apply('unary_args', :_unary_args)
    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save130
    end
    as = @result
    unless _tmp
      self.pos = _save128
      break
    end
    _save131 = self.pos

    _save132 = self.pos
    while true # sequence
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save132
      break
    end
    _tmp = apply('block', :_block)
    unless _tmp
      self.pos = _save132
    end
    break
    end # end sequence

    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save131
    end
    b = @result
    unless _tmp
      self.pos = _save128
      break
    end
    @result = begin;  Atomo::AST::UnarySend.new(line, r, n, Array(as), b) ; end
    _tmp = true
    unless _tmp
      self.pos = _save128
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save127

    _save133 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save133
      break
    end
    _tmp = apply('level1', :_level1)
    r = @result
    unless _tmp
      self.pos = _save133
      break
    end
    _tmp = apply('sig_sp', :_sig_sp)
    unless _tmp
      self.pos = _save133
      break
    end
    _tmp = apply('identifier', :_identifier)
    n = @result
    unless _tmp
      self.pos = _save133
      break
    end
    _save134 = self.pos
    _tmp = match_string(":")
    self.pos = _save134
    _tmp = _tmp ? nil : true
    unless _tmp
      self.pos = _save133
      break
    end
    _save135 = self.pos
    _tmp = apply('unary_args', :_unary_args)
    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save135
    end
    as = @result
    unless _tmp
      self.pos = _save133
      break
    end
    _save136 = self.pos

    _save137 = self.pos
    while true # sequence
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save137
      break
    end
    _tmp = apply('block', :_block)
    unless _tmp
      self.pos = _save137
    end
    break
    end # end sequence

    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save136
    end
    b = @result
    unless _tmp
      self.pos = _save133
      break
    end
    @result = begin;  Atomo::AST::UnarySend.new(line, r, n, Array(as), b) ; end
    _tmp = true
    unless _tmp
      self.pos = _save133
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save127

    _save138 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save138
      break
    end
    _tmp = apply('identifier', :_identifier)
    n = @result
    unless _tmp
      self.pos = _save138
      break
    end
    _tmp = apply('unary_args', :_unary_args)
    as = @result
    unless _tmp
      self.pos = _save138
      break
    end
    _save139 = self.pos

    _save140 = self.pos
    while true # sequence
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save140
      break
    end
    _tmp = apply('block', :_block)
    unless _tmp
      self.pos = _save140
    end
    break
    end # end sequence

    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save139
    end
    b = @result
    unless _tmp
      self.pos = _save138
      break
    end
    @result = begin;  Atomo::AST::UnarySend.new(line,
                        Atomo::AST::Primitive.new(line, :self),
                        n,
                        Array(as),
                        b,
                        true
                      )
                    ; end
    _tmp = true
    unless _tmp
      self.pos = _save138
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save127
    break
    end # end choice

    return _tmp
  end
  def _keyword_pair

    _save141 = self.pos
    while true # sequence
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save141
      break
    end
    _tmp = apply('identifier', :_identifier)
    n = @result
    unless _tmp
      self.pos = _save141
      break
    end
    _tmp = match_string(":")
    unless _tmp
      self.pos = _save141
      break
    end
    _tmp = apply('sp', :_sp)
    unless _tmp
      self.pos = _save141
      break
    end
    _tmp = apply('level2', :_level2)
    v = @result
    unless _tmp
      self.pos = _save141
      break
    end
    @result = begin;  [n, v] ; end
    _tmp = true
    unless _tmp
      self.pos = _save141
    end
    break
    end # end sequence

    return _tmp
  end
  def _keyword_args

    _save142 = self.pos
    while true # sequence
    _save143 = self.pos
    _ary = []
    _tmp = apply('keyword_pair', :_keyword_pair)
    if _tmp
      _ary << @result
      while true
        _tmp = apply('keyword_pair', :_keyword_pair)
        _ary << @result if _tmp
        break unless _tmp
      end
      _tmp = true
      @result = _ary
    else
      self.pos = _save143
    end
    as = @result
    unless _tmp
      self.pos = _save142
      break
    end
    @result = begin; 
                    pairs = Array(as)
                    name = ""
                    args = []

                    pairs.each do |n, v|
                      name << "#{n}:"
                      args << v
                    end

                    [name, args]
                  ; end
    _tmp = true
    unless _tmp
      self.pos = _save142
    end
    break
    end # end sequence

    return _tmp
  end
  def _keyword_send

    _save144 = self.pos
    while true # choice

    _save145 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save145
      break
    end
    _tmp = apply('level2', :_level2)
    r = @result
    unless _tmp
      self.pos = _save145
      break
    end
    _tmp = apply('sig_sp', :_sig_sp)
    unless _tmp
      self.pos = _save145
      break
    end
    _tmp = apply('keyword_args', :_keyword_args)
    as = @result
    unless _tmp
      self.pos = _save145
      break
    end
    @result = begin;  Atomo::AST::KeywordSend.new(line, r, as.first, as.last) ; end
    _tmp = true
    unless _tmp
      self.pos = _save145
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save144

    _save146 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save146
      break
    end
    _tmp = apply('keyword_args', :_keyword_args)
    as = @result
    unless _tmp
      self.pos = _save146
      break
    end
    @result = begin;  Atomo::AST::KeywordSend.new(line,
                        Atomo::AST::Primitive.new(line, :self),
                        as.first,
                        as.last,
                        true
                      )
                    ; end
    _tmp = true
    unless _tmp
      self.pos = _save146
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save144
    break
    end # end choice

    return _tmp
  end
  def _binary_send

    _save147 = self.pos
    while true # choice

    _save148 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save148
      break
    end
    _tmp = apply('binary_send', :_binary_send)
    l = @result
    unless _tmp
      self.pos = _save148
      break
    end
    _tmp = apply('sig_sp', :_sig_sp)
    unless _tmp
      self.pos = _save148
      break
    end
    _tmp = apply('operator', :_operator)
    o = @result
    unless _tmp
      self.pos = _save148
      break
    end
    _tmp = apply('sig_sp', :_sig_sp)
    unless _tmp
      self.pos = _save148
      break
    end
    _tmp = apply('expression', :_expression)
    r = @result
    unless _tmp
      self.pos = _save148
      break
    end
    @result = begin;  Atomo::AST::BinarySend.new(line, o, l, r) ; end
    _tmp = true
    unless _tmp
      self.pos = _save148
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save147

    _save149 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save149
      break
    end
    _tmp = apply('level3', :_level3)
    l = @result
    unless _tmp
      self.pos = _save149
      break
    end
    _tmp = apply('sig_sp', :_sig_sp)
    unless _tmp
      self.pos = _save149
      break
    end
    _tmp = apply('operator', :_operator)
    o = @result
    unless _tmp
      self.pos = _save149
      break
    end
    _tmp = apply('sig_sp', :_sig_sp)
    unless _tmp
      self.pos = _save149
      break
    end
    _tmp = apply('expression', :_expression)
    r = @result
    unless _tmp
      self.pos = _save149
      break
    end
    @result = begin;  Atomo::AST::BinarySend.new(line, o, l, r) ; end
    _tmp = true
    unless _tmp
      self.pos = _save149
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save147

    _save150 = self.pos
    while true # sequence
    _tmp = apply('line', :_line)
    line = @result
    unless _tmp
      self.pos = _save150
      break
    end
    _tmp = apply('operator', :_operator)
    o = @result
    unless _tmp
      self.pos = _save150
      break
    end
    _tmp = apply('sig_sp', :_sig_sp)
    unless _tmp
      self.pos = _save150
      break
    end
    _tmp = apply('expression', :_expression)
    r = @result
    unless _tmp
      self.pos = _save150
      break
    end
    @result = begin;  Atomo::AST::BinarySend.new(
                        line,
                        o,
                        Atomo::AST::Primitive.new(line, :self),
                        r
                      )
                    ; end
    _tmp = true
    unless _tmp
      self.pos = _save150
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save147
    break
    end # end choice

    return _tmp
  end
  def _root

    _save151 = self.pos
    while true # sequence
    _tmp = apply('expressions', :_expressions)
    es = @result
    unless _tmp
      self.pos = _save151
      break
    end
    _save152 = self.pos
    _tmp = get_byte
    self.pos = _save152
    _tmp = _tmp ? nil : true
    unless _tmp
      self.pos = _save151
      break
    end
    @result = begin;  es ; end
    _tmp = true
    unless _tmp
      self.pos = _save151
    end
    break
    end # end sequence

    return _tmp
  end
end

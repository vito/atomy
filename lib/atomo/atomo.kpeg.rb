require 'kpeg/compiled_parser'

class Atomo::Parser < KPeg::CompiledParser


  def initialize(str)
    super
    @wsp = []
  end

  def continue?
    x = @wsp.last
    y = current_position
    y[0] >= x[0] && y[1] > x[1]
  end

  def save
    @wsp << current_position
    true
  end

  def done
    @wsp.pop
  end

  def set_op_info(op, assoc, prec)
    info = Atomo::OPERATORS[op] ||= {}
    info[:assoc] = assoc
    info[:prec] = prec
  end

  def op_info(op)
    Atomo::OPERATORS[op] || {}
  end

  def prec(o)
    op_info(o)[:prec] || 5
  end

  def assoc(o)
    op_info(o)[:assoc] || :left
  end

  def binary(o, l, r)
    Atomo::AST::BinarySend.new(l.line, l, r, o)
  end

  def op_chain(os, es)
    return binary(os[0], es[0], es[1]) if os.size == 1

    a, b, *cs = os
    w, x, y, *zs = es

    if prec(b) > prec(a) || assoc(a) == :right && prec(b) == prec(a)
      binary(a, w, op_chain([b] + cs, [x, y] + zs))
    else
      op_chain([b] + cs, [binary(a, w, x), y] + zs)
    end
  end

  def const_chain(l, ns, top = false)
    p = nil
    ns.each do |n|
      if p
        p = Atomo::AST::ScopedConstant.new(l, p, n)
      elsif top
        p = Atomo::AST::ToplevelConstant.new(l, n)
      else
        p = Atomo::AST::Constant.new(l, n)
      end
    end
    p
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
    return _tmp
  end

  # cont = (("\n" sp)+ &{ continue? } | sig_sp (("\n" sp)+ &{ continue? })?)
  def _cont

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
    _tmp = begin;  continue? ; end
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

    _save8 = self.pos
    while true # sequence
    _save9 = self.pos

    _save10 = self.pos
    while true # sequence
    _tmp = match_string("\n")
    unless _tmp
      self.pos = _save10
      break
    end
    _tmp = apply(:_sp)
    unless _tmp
      self.pos = _save10
    end
    break
    end # end sequence

    if _tmp
      while true
    
    _save11 = self.pos
    while true # sequence
    _tmp = match_string("\n")
    unless _tmp
      self.pos = _save11
      break
    end
    _tmp = apply(:_sp)
    unless _tmp
      self.pos = _save11
    end
    break
    end # end sequence

        break unless _tmp
      end
      _tmp = true
    else
      self.pos = _save9
    end
    unless _tmp
      self.pos = _save8
      break
    end
    _save12 = self.pos
    _tmp = begin;  continue? ; end
    self.pos = _save12
    unless _tmp
      self.pos = _save8
    end
    break
    end # end sequence

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

    return _tmp
  end

  # line = { current_line }
  def _line
    @result = begin;  current_line ; end
    _tmp = true
    return _tmp
  end

  # ident_start = < /[[a-z]_]/ > { text }
  def _ident_start

    _save = self.pos
    while true # sequence
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[[a-z]_])/)
    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # ident_letters = < /([[:alnum:]\$\+\<=\>\^~_!@#%&*\-.\/\?])*/ > { text }
  def _ident_letters

    _save = self.pos
    while true # sequence
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:([[:alnum:]\$\+\<=\>\^~_!@#%&*\-.\/\?])*)/)
    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # op_start = < /[\$\+\<=\>\^~!@&#%\|&*\-.\/\?:]/ > { text }
  def _op_start

    _save = self.pos
    while true # sequence
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[\$\+\<=\>\^~!@&#%\|&*\-.\/\?:])/)
    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # op_letters = < /([\$\+\<=\>\^~!@&#%\|&*\-.\/\?:])*/ > { text }
  def _op_letters

    _save = self.pos
    while true # sequence
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:([\$\+\<=\>\^~!@&#%\|&*\-.\/\?:])*)/)
    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # f_ident_start = < /[[:alpha:]\$\+\<=\>\^`~_!@#%&*\-.\/\?]/ > { text }
  def _f_ident_start

    _save = self.pos
    while true # sequence
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[[:alpha:]\$\+\<=\>\^`~_!@#%&*\-.\/\?])/)
    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # operator = < op_start op_letters > { text }
  def _operator

    _save = self.pos
    while true # sequence
    _text_start = self.pos

    _save1 = self.pos
    while true # sequence
    _tmp = apply(:_op_start)
    unless _tmp
      self.pos = _save1
      break
    end
    _tmp = apply(:_op_letters)
    unless _tmp
      self.pos = _save1
    end
    break
    end # end sequence

    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # identifier = < ident_start ident_letters > { text }
  def _identifier

    _save = self.pos
    while true # sequence
    _text_start = self.pos

    _save1 = self.pos
    while true # sequence
    _tmp = apply(:_ident_start)
    unless _tmp
      self.pos = _save1
      break
    end
    _tmp = apply(:_ident_letters)
    unless _tmp
      self.pos = _save1
    end
    break
    end # end sequence

    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # f_identifier = < f_ident_start ident_letters > { text }
  def _f_identifier

    _save = self.pos
    while true # sequence
    _text_start = self.pos

    _save1 = self.pos
    while true # sequence
    _tmp = apply(:_f_ident_start)
    unless _tmp
      self.pos = _save1
      break
    end
    _tmp = apply(:_ident_letters)
    unless _tmp
      self.pos = _save1
    end
    break
    end # end sequence

    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

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

    return _tmp
  end

  # delim = (wsp (";" | ",") wsp | (sp "\n" sp)+)
  def _delim

    _save = self.pos
    while true # choice

    _save1 = self.pos
    while true # sequence
    _tmp = apply(:_wsp)
    unless _tmp
      self.pos = _save1
      break
    end

    _save2 = self.pos
    while true # choice
    _tmp = match_string(";")
    break if _tmp
    self.pos = _save2
    _tmp = match_string(",")
    break if _tmp
    self.pos = _save2
    break
    end # end choice

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
    break if _tmp
    self.pos = _save
    break
    end # end choice

    return _tmp
  end

  # expression = level4
  def _expression
    _tmp = apply(:_level4)
    return _tmp
  end

  # expressions = expression:x (delim expression)*:xs delim? { [x] + Array(xs) }
  def _expressions

    _save = self.pos
    while true # sequence
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
    _tmp = apply(:_delim)
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
    _save3 = self.pos
    _tmp = apply(:_delim)
    unless _tmp
      _tmp = true
      self.pos = _save3
    end
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  [x] + Array(xs) ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # level1 = (true | false | self | nil | number | macro | for_macro | op_assoc_pred | quote | quasi_quote | unquote | string | macro_quote | particle | constant | meta | variable | grouped | block | list | unary_op)
  def _level1

    _save = self.pos
    while true # choice
    _tmp = apply(:_true)
    break if _tmp
    self.pos = _save
    _tmp = apply(:_false)
    break if _tmp
    self.pos = _save
    _tmp = apply(:_self)
    break if _tmp
    self.pos = _save
    _tmp = apply(:_nil)
    break if _tmp
    self.pos = _save
    _tmp = apply(:_number)
    break if _tmp
    self.pos = _save
    _tmp = apply(:_macro)
    break if _tmp
    self.pos = _save
    _tmp = apply(:_for_macro)
    break if _tmp
    self.pos = _save
    _tmp = apply(:_op_assoc_pred)
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
    _tmp = apply(:_macro_quote)
    break if _tmp
    self.pos = _save
    _tmp = apply(:_particle)
    break if _tmp
    self.pos = _save
    _tmp = apply(:_constant)
    break if _tmp
    self.pos = _save
    _tmp = apply(:_meta)
    break if _tmp
    self.pos = _save
    _tmp = apply(:_variable)
    break if _tmp
    self.pos = _save
    _tmp = apply(:_grouped)
    break if _tmp
    self.pos = _save
    _tmp = apply(:_block)
    break if _tmp
    self.pos = _save
    _tmp = apply(:_list)
    break if _tmp
    self.pos = _save
    _tmp = apply(:_unary_op)
    break if _tmp
    self.pos = _save
    break
    end # end choice

    return _tmp
  end

  # level2 = (unary_send | level1)
  def _level2

    _save = self.pos
    while true # choice
    _tmp = apply(:_unary_send)
    break if _tmp
    self.pos = _save
    _tmp = apply(:_level1)
    break if _tmp
    self.pos = _save
    break
    end # end choice

    return _tmp
  end

  # level3 = (keyword_send | level2)
  def _level3

    _save = self.pos
    while true # choice
    _tmp = apply(:_keyword_send)
    break if _tmp
    self.pos = _save
    _tmp = apply(:_level2)
    break if _tmp
    self.pos = _save
    break
    end # end choice

    return _tmp
  end

  # level4 = (binary_send | level3)
  def _level4

    _save = self.pos
    while true # choice
    _tmp = apply(:_binary_send)
    break if _tmp
    self.pos = _save
    _tmp = apply(:_level3)
    break if _tmp
    self.pos = _save
    break
    end # end choice

    return _tmp
  end

  # true = line:line "true" !f_identifier { Atomo::AST::Primitive.new(line, :true) }
  def _true

    _save = self.pos
    while true # sequence
    _tmp = apply(:_line)
    line = @result
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = match_string("true")
    unless _tmp
      self.pos = _save
      break
    end
    _save1 = self.pos
    _tmp = apply(:_f_identifier)
    _tmp = _tmp ? nil : true
    self.pos = _save1
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  Atomo::AST::Primitive.new(line, :true) ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # false = line:line "false" !f_identifier { Atomo::AST::Primitive.new(line, :false) }
  def _false

    _save = self.pos
    while true # sequence
    _tmp = apply(:_line)
    line = @result
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = match_string("false")
    unless _tmp
      self.pos = _save
      break
    end
    _save1 = self.pos
    _tmp = apply(:_f_identifier)
    _tmp = _tmp ? nil : true
    self.pos = _save1
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  Atomo::AST::Primitive.new(line, :false) ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # self = line:line "self" !f_identifier { Atomo::AST::Primitive.new(line, :self) }
  def _self

    _save = self.pos
    while true # sequence
    _tmp = apply(:_line)
    line = @result
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = match_string("self")
    unless _tmp
      self.pos = _save
      break
    end
    _save1 = self.pos
    _tmp = apply(:_f_identifier)
    _tmp = _tmp ? nil : true
    self.pos = _save1
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  Atomo::AST::Primitive.new(line, :self) ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # nil = line:line "nil" !f_identifier { Atomo::AST::Primitive.new(line, :nil) }
  def _nil

    _save = self.pos
    while true # sequence
    _tmp = apply(:_line)
    line = @result
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = match_string("nil")
    unless _tmp
      self.pos = _save
      break
    end
    _save1 = self.pos
    _tmp = apply(:_f_identifier)
    _tmp = _tmp ? nil : true
    self.pos = _save1
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  Atomo::AST::Primitive.new(line, :nil) ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # number = (line:line < /[\+\-]?0[oO][\da-fA-F]+/ > { Atomo::AST::Primitive.new(line, text.to_i(8)) } | line:line < /[\+\-]?0[xX][0-7]+/ > { Atomo::AST::Primitive.new(line, text.to_i(16)) } | line:line < /[\+\-]?\d+(\.\d+)?[eE][\+\-]?\d+/ > { Atomo::AST::Primitive.new(line, text.to_f) } | line:line < /[\+\-]?\d+\.\d+/ > { Atomo::AST::Primitive.new(line, text.to_f) } | line:line < /[\+\-]?\d+/ > { Atomo::AST::Primitive.new(line, text.to_i) })
  def _number

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
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[\+\-]?0[oO][\da-fA-F]+)/)
    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save1
      break
    end
    @result = begin;  Atomo::AST::Primitive.new(line, text.to_i(8)) ; end
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
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[\+\-]?0[xX][0-7]+)/)
    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save2
      break
    end
    @result = begin;  Atomo::AST::Primitive.new(line, text.to_i(16)) ; end
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
    line = @result
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
    @result = begin;  Atomo::AST::Primitive.new(line, text.to_f) ; end
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
    line = @result
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
    @result = begin;  Atomo::AST::Primitive.new(line, text.to_f) ; end
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
    line = @result
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
    @result = begin;  Atomo::AST::Primitive.new(line, text.to_i) ; end
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

    return _tmp
  end

  # macro = line:line "macro" wsp "(" wsp expression:p wsp ")" wsp expression:b { b; Atomo::AST::Macro.new(line, p, b) }
  def _macro

    _save = self.pos
    while true # sequence
    _tmp = apply(:_line)
    line = @result
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = match_string("macro")
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = apply(:_wsp)
    unless _tmp
      self.pos = _save
      break
    end
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
    p = @result
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
    _tmp = apply(:_wsp)
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = apply(:_expression)
    b = @result
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  b; Atomo::AST::Macro.new(line, p, b) ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # for_macro = line:line "for-macro" wsp expression:b { Atomo::AST::ForMacro.new(line, b) }
  def _for_macro

    _save = self.pos
    while true # sequence
    _tmp = apply(:_line)
    line = @result
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = match_string("for-macro")
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
    b = @result
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  Atomo::AST::ForMacro.new(line, b) ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # op_assoc = sig_wsp < /left|right/ > { text.to_sym }
  def _op_assoc

    _save = self.pos
    while true # sequence
    _tmp = apply(:_sig_wsp)
    unless _tmp
      self.pos = _save
      break
    end
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:left|right)/)
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

    return _tmp
  end

  # op_pred = sig_wsp < /[0-9]+/ > { text.to_i }
  def _op_pred

    _save = self.pos
    while true # sequence
    _tmp = apply(:_sig_wsp)
    unless _tmp
      self.pos = _save
      break
    end
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[0-9]+)/)
    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  text.to_i ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # op_assoc_pred = line:line "operator" op_assoc?:assoc op_pred:pred (sig_wsp operator)+:os { Atomo::Macro.set_op_info(os, assoc, pred)                       Atomo::AST::Operator.new(line, assoc, pred, os)                     }
  def _op_assoc_pred

    _save = self.pos
    while true # sequence
    _tmp = apply(:_line)
    line = @result
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = match_string("operator")
    unless _tmp
      self.pos = _save
      break
    end
    _save1 = self.pos
    _tmp = apply(:_op_assoc)
    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save1
    end
    assoc = @result
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = apply(:_op_pred)
    pred = @result
    unless _tmp
      self.pos = _save
      break
    end
    _save2 = self.pos
    _ary = []

    _save3 = self.pos
    while true # sequence
    _tmp = apply(:_sig_wsp)
    unless _tmp
      self.pos = _save3
      break
    end
    _tmp = apply(:_operator)
    unless _tmp
      self.pos = _save3
    end
    break
    end # end sequence

    if _tmp
      _ary << @result
      while true
    
    _save4 = self.pos
    while true # sequence
    _tmp = apply(:_sig_wsp)
    unless _tmp
      self.pos = _save4
      break
    end
    _tmp = apply(:_operator)
    unless _tmp
      self.pos = _save4
    end
    break
    end # end sequence

        _ary << @result if _tmp
        break unless _tmp
      end
      _tmp = true
      @result = _ary
    else
      self.pos = _save2
    end
    os = @result
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  Atomo::Macro.set_op_info(os, assoc, pred)
                      Atomo::AST::Operator.new(line, assoc, pred, os)
                    ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # quote = line:line "'" level1:e { Atomo::AST::Quote.new(line, e) }
  def _quote

    _save = self.pos
    while true # sequence
    _tmp = apply(:_line)
    line = @result
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = match_string("'")
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = apply(:_level1)
    e = @result
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  Atomo::AST::Quote.new(line, e) ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # quasi_quote = line:line "`" level1:e { Atomo::AST::QuasiQuote.new(line, e) }
  def _quasi_quote

    _save = self.pos
    while true # sequence
    _tmp = apply(:_line)
    line = @result
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = match_string("`")
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = apply(:_level1)
    e = @result
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  Atomo::AST::QuasiQuote.new(line, e) ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # unquote = line:line "~" level1:e { Atomo::AST::Unquote.new(line, e) }
  def _unquote

    _save = self.pos
    while true # sequence
    _tmp = apply(:_line)
    line = @result
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = match_string("~")
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = apply(:_level1)
    e = @result
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  Atomo::AST::Unquote.new(line, e) ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # escape = (number_escapes | escapes)
  def _escape

    _save = self.pos
    while true # choice
    _tmp = apply(:_number_escapes)
    break if _tmp
    self.pos = _save
    _tmp = apply(:_escapes)
    break if _tmp
    self.pos = _save
    break
    end # end choice

    return _tmp
  end

  # str_seq = < /[^\\"]+/ > { text }
  def _str_seq

    _save = self.pos
    while true # sequence
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[^\\"]+)/)
    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # string = line:line "\"" ("\\" escape | str_seq)*:c "\"" { Atomo::AST::String.new(line, c.join) }
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
    _tmp = apply(:_escape)
    unless _tmp
      self.pos = _save3
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save2
    _tmp = apply(:_str_seq)
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
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = match_string("\"")
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  Atomo::AST::String.new(line, c.join) ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # macro_quote = line:line identifier:n quoted:c (< [a-z] > { text })*:fs { Atomo::AST::MacroQuote.new(line, n, c, fs) }
  def _macro_quote

    _save = self.pos
    while true # sequence
    _tmp = apply(:_line)
    line = @result
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
    _tmp = apply(:_quoted)
    c = @result
    unless _tmp
      self.pos = _save
      break
    end
    _ary = []
    while true

    _save2 = self.pos
    while true # sequence
    _text_start = self.pos
    _tmp = get_byte
    if _tmp
      unless _tmp >= 97 and _tmp <= 122
        fail_range('a', 'z')
        _tmp = nil
      end
    end
    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save2
      break
    end
    @result = begin;  text ; end
    _tmp = true
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
    fs = @result
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  Atomo::AST::MacroQuote.new(line, n, c, fs) ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # particle = line:line "#" f_identifier:n { Atomo::AST::Particle.new(line, n) }
  def _particle

    _save = self.pos
    while true # sequence
    _tmp = apply(:_line)
    line = @result
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = match_string("#")
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = apply(:_f_identifier)
    n = @result
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  Atomo::AST::Particle.new(line, n) ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # constant_name = < /[A-Z][a-zA-Z0-9_]*/ > { text }
  def _constant_name

    _save = self.pos
    while true # sequence
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[A-Z][a-zA-Z0-9_]*)/)
    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # constant = (line:line constant_name:m ("::" constant_name)*:s unary_args?:as {                     names = [m] + Array(s)                     if as                       msg = names.pop                       Atomo::AST::UnarySend.new(                         line,                         names.empty? ?                             Atomo::AST::Primitive.new(line, :self) :                             const_chain(line, names),                         Array(as),                         msg,                         nil,                         true                       )                     else                       const_chain(line, names)                     end                   } | line:line ("::" constant_name)+:s unary_args?:as {                     names = Array(s)                     if as                       msg = names.pop                       Atomo::AST::UnarySend.new(                         line,                         names.empty? ?                             Atomo::AST::Primitive.new(line, :self) :                             const_chain(line, names, true),                         Array(as),                         msg,                         nil,                         true                       )                     else                       const_chain(line, names, true)                     end                 })
  def _constant

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
    _tmp = apply(:_constant_name)
    m = @result
    unless _tmp
      self.pos = _save1
      break
    end
    _ary = []
    while true

    _save3 = self.pos
    while true # sequence
    _tmp = match_string("::")
    unless _tmp
      self.pos = _save3
      break
    end
    _tmp = apply(:_constant_name)
    unless _tmp
      self.pos = _save3
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
      self.pos = _save1
      break
    end
    _save4 = self.pos
    _tmp = apply(:_unary_args)
    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save4
    end
    as = @result
    unless _tmp
      self.pos = _save1
      break
    end
    @result = begin; 
                    names = [m] + Array(s)
                    if as
                      msg = names.pop
                      Atomo::AST::UnarySend.new(
                        line,
                        names.empty? ?
                            Atomo::AST::Primitive.new(line, :self) :
                            const_chain(line, names),
                        Array(as),
                        msg,
                        nil,
                        true
                      )
                    else
                      const_chain(line, names)
                    end
                  ; end
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
    line = @result
    unless _tmp
      self.pos = _save5
      break
    end
    _save6 = self.pos
    _ary = []

    _save7 = self.pos
    while true # sequence
    _tmp = match_string("::")
    unless _tmp
      self.pos = _save7
      break
    end
    _tmp = apply(:_constant_name)
    unless _tmp
      self.pos = _save7
    end
    break
    end # end sequence

    if _tmp
      _ary << @result
      while true
    
    _save8 = self.pos
    while true # sequence
    _tmp = match_string("::")
    unless _tmp
      self.pos = _save8
      break
    end
    _tmp = apply(:_constant_name)
    unless _tmp
      self.pos = _save8
    end
    break
    end # end sequence

        _ary << @result if _tmp
        break unless _tmp
      end
      _tmp = true
      @result = _ary
    else
      self.pos = _save6
    end
    s = @result
    unless _tmp
      self.pos = _save5
      break
    end
    _save9 = self.pos
    _tmp = apply(:_unary_args)
    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save9
    end
    as = @result
    unless _tmp
      self.pos = _save5
      break
    end
    @result = begin; 
                    names = Array(s)
                    if as
                      msg = names.pop
                      Atomo::AST::UnarySend.new(
                        line,
                        names.empty? ?
                            Atomo::AST::Primitive.new(line, :self) :
                            const_chain(line, names, true),
                        Array(as),
                        msg,
                        nil,
                        true
                      )
                    else
                      const_chain(line, names, true)
                    end
                ; end
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

    return _tmp
  end

  # meta = (line:line "__LINE__" { Atomo::AST::Primitive.new(line, line) } | line:line "__FILE__" { Atomo::AST::File.new(line) })
  def _meta

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
    _tmp = match_string("__LINE__")
    unless _tmp
      self.pos = _save1
      break
    end
    @result = begin;  Atomo::AST::Primitive.new(line, line) ; end
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
    _tmp = match_string("__FILE__")
    unless _tmp
      self.pos = _save2
      break
    end
    @result = begin;  Atomo::AST::File.new(line) ; end
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

    return _tmp
  end

  # variable = line:line identifier:n !":" { Atomo::AST::Variable.new(line, n) }
  def _variable

    _save = self.pos
    while true # sequence
    _tmp = apply(:_line)
    line = @result
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
    _save1 = self.pos
    _tmp = match_string(":")
    _tmp = _tmp ? nil : true
    self.pos = _save1
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  Atomo::AST::Variable.new(line, n) ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # unary_op = line:line operator:o level1:e { Atomo::AST::UnaryOperator.new(line, e, o) }
  def _unary_op

    _save = self.pos
    while true # sequence
    _tmp = apply(:_line)
    line = @result
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = apply(:_operator)
    o = @result
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = apply(:_level1)
    e = @result
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  Atomo::AST::UnaryOperator.new(line, e, o) ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # block_args = (sp level1:n)+:as wsp "|" { as }
  def _block_args

    _save = self.pos
    while true # sequence
    _save1 = self.pos
    _ary = []

    _save2 = self.pos
    while true # sequence
    _tmp = apply(:_sp)
    unless _tmp
      self.pos = _save2
      break
    end
    _tmp = apply(:_level1)
    n = @result
    unless _tmp
      self.pos = _save2
    end
    break
    end # end sequence

    if _tmp
      _ary << @result
      while true
    
    _save3 = self.pos
    while true # sequence
    _tmp = apply(:_sp)
    unless _tmp
      self.pos = _save3
      break
    end
    _tmp = apply(:_level1)
    n = @result
    unless _tmp
      self.pos = _save3
    end
    break
    end # end sequence

        _ary << @result if _tmp
        break unless _tmp
      end
      _tmp = true
      @result = _ary
    else
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
    _tmp = match_string("|")
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  as ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # block = line:line "{" block_args?:as wsp expressions?:es wsp "}" { Atomo::AST::Block.new(line, Array(es), Array(as)) }
  def _block

    _save = self.pos
    while true # sequence
    _tmp = apply(:_line)
    line = @result
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = match_string("{")
    unless _tmp
      self.pos = _save
      break
    end
    _save1 = self.pos
    _tmp = apply(:_block_args)
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
    _tmp = match_string("}")
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  Atomo::AST::Block.new(line, Array(es), Array(as)) ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # list = line:line "[" wsp expressions?:es wsp "]" { Atomo::AST::List.new(line, Array(es)) }
  def _list

    _save = self.pos
    while true # sequence
    _tmp = apply(:_line)
    line = @result
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
    @result = begin;  Atomo::AST::List.new(line, Array(es)) ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # unary_args = "(" wsp expressions?:as wsp ")" { Array(as) }
  def _unary_args

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

    return _tmp
  end

  # sunary_send = (line:line sunary_send:r @cont identifier:n !":" unary_args?:as (@cont block)?:b { Atomo::AST::UnarySend.new(line, r, Array(as), n, b) } | line:line level1:r @cont identifier:n !":" unary_args?:as (@cont block)?:b { Atomo::AST::UnarySend.new(line, r, Array(as), n, b) } | line:line identifier:n unary_args?:as @cont block:b { Atomo::AST::UnarySend.new(                         line,                         Atomo::AST::Primitive.new(line, :self),                         Array(as),                         n,                         b,                         true                       )                     } | line:line identifier:n unary_args:as (sp block)?:b { Atomo::AST::UnarySend.new(                         line,                         Atomo::AST::Primitive.new(line, :self),                         as,                         n,                         b,                         true                       )                     })
  def _sunary_send

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
    _tmp = apply(:_sunary_send)
    r = @result
    unless _tmp
      self.pos = _save1
      break
    end
    _tmp = _cont()
    unless _tmp
      self.pos = _save1
      break
    end
    _tmp = apply(:_identifier)
    n = @result
    unless _tmp
      self.pos = _save1
      break
    end
    _save2 = self.pos
    _tmp = match_string(":")
    _tmp = _tmp ? nil : true
    self.pos = _save2
    unless _tmp
      self.pos = _save1
      break
    end
    _save3 = self.pos
    _tmp = apply(:_unary_args)
    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save3
    end
    as = @result
    unless _tmp
      self.pos = _save1
      break
    end
    _save4 = self.pos

    _save5 = self.pos
    while true # sequence
    _tmp = _cont()
    unless _tmp
      self.pos = _save5
      break
    end
    _tmp = apply(:_block)
    unless _tmp
      self.pos = _save5
    end
    break
    end # end sequence

    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save4
    end
    b = @result
    unless _tmp
      self.pos = _save1
      break
    end
    @result = begin;  Atomo::AST::UnarySend.new(line, r, Array(as), n, b) ; end
    _tmp = true
    unless _tmp
      self.pos = _save1
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save6 = self.pos
    while true # sequence
    _tmp = apply(:_line)
    line = @result
    unless _tmp
      self.pos = _save6
      break
    end
    _tmp = apply(:_level1)
    r = @result
    unless _tmp
      self.pos = _save6
      break
    end
    _tmp = _cont()
    unless _tmp
      self.pos = _save6
      break
    end
    _tmp = apply(:_identifier)
    n = @result
    unless _tmp
      self.pos = _save6
      break
    end
    _save7 = self.pos
    _tmp = match_string(":")
    _tmp = _tmp ? nil : true
    self.pos = _save7
    unless _tmp
      self.pos = _save6
      break
    end
    _save8 = self.pos
    _tmp = apply(:_unary_args)
    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save8
    end
    as = @result
    unless _tmp
      self.pos = _save6
      break
    end
    _save9 = self.pos

    _save10 = self.pos
    while true # sequence
    _tmp = _cont()
    unless _tmp
      self.pos = _save10
      break
    end
    _tmp = apply(:_block)
    unless _tmp
      self.pos = _save10
    end
    break
    end # end sequence

    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save9
    end
    b = @result
    unless _tmp
      self.pos = _save6
      break
    end
    @result = begin;  Atomo::AST::UnarySend.new(line, r, Array(as), n, b) ; end
    _tmp = true
    unless _tmp
      self.pos = _save6
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save11 = self.pos
    while true # sequence
    _tmp = apply(:_line)
    line = @result
    unless _tmp
      self.pos = _save11
      break
    end
    _tmp = apply(:_identifier)
    n = @result
    unless _tmp
      self.pos = _save11
      break
    end
    _save12 = self.pos
    _tmp = apply(:_unary_args)
    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save12
    end
    as = @result
    unless _tmp
      self.pos = _save11
      break
    end
    _tmp = _cont()
    unless _tmp
      self.pos = _save11
      break
    end
    _tmp = apply(:_block)
    b = @result
    unless _tmp
      self.pos = _save11
      break
    end
    @result = begin;  Atomo::AST::UnarySend.new(
                        line,
                        Atomo::AST::Primitive.new(line, :self),
                        Array(as),
                        n,
                        b,
                        true
                      )
                    ; end
    _tmp = true
    unless _tmp
      self.pos = _save11
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save13 = self.pos
    while true # sequence
    _tmp = apply(:_line)
    line = @result
    unless _tmp
      self.pos = _save13
      break
    end
    _tmp = apply(:_identifier)
    n = @result
    unless _tmp
      self.pos = _save13
      break
    end
    _tmp = apply(:_unary_args)
    as = @result
    unless _tmp
      self.pos = _save13
      break
    end
    _save14 = self.pos

    _save15 = self.pos
    while true # sequence
    _tmp = apply(:_sp)
    unless _tmp
      self.pos = _save15
      break
    end
    _tmp = apply(:_block)
    unless _tmp
      self.pos = _save15
    end
    break
    end # end sequence

    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save14
    end
    b = @result
    unless _tmp
      self.pos = _save13
      break
    end
    @result = begin;  Atomo::AST::UnarySend.new(
                        line,
                        Atomo::AST::Primitive.new(line, :self),
                        as,
                        n,
                        b,
                        true
                      )
                    ; end
    _tmp = true
    unless _tmp
      self.pos = _save13
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save
    break
    end # end choice

    return _tmp
  end

  # unary_send = ~{ done } { save } sunary_send:t { t }
  def _unary_send

    _save = self.pos
    begin
    while true # sequence
    @result = begin;  save ; end
    _tmp = true
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = apply(:_sunary_send)
    t = @result
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  t ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    ensure
 done     end
    return _tmp
  end

  # keyword_pair = identifier:n ":" sig_sp level2:v { [n, v] }
  def _keyword_pair

    _save = self.pos
    while true # sequence
    _tmp = apply(:_identifier)
    n = @result
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = match_string(":")
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = apply(:_sig_sp)
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = apply(:_level2)
    v = @result
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  [n, v] ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # keyword_args = keyword_pair:a (@cont keyword_pair)*:as {                     pairs = [a] + Array(as)                     name = ""                     names = []                     args = []                      pairs.each do |n, v|                       names << n                       args << v                     end                      [names, args]                   }
  def _keyword_args

    _save = self.pos
    while true # sequence
    _tmp = apply(:_keyword_pair)
    a = @result
    unless _tmp
      self.pos = _save
      break
    end
    _ary = []
    while true

    _save2 = self.pos
    while true # sequence
    _tmp = _cont()
    unless _tmp
      self.pos = _save2
      break
    end
    _tmp = apply(:_keyword_pair)
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
    as = @result
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin; 
                    pairs = [a] + Array(as)
                    name = ""
                    names = []
                    args = []

                    pairs.each do |n, v|
                      names << n
                      args << v
                    end

                    [names, args]
                  ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # skeyword_send = (line:line level2:r @cont keyword_args:as { Atomo::AST::KeywordSend.new(                         line,                         r,                         as.last,                         as.first                       )                     } | line:line keyword_args:as { Atomo::AST::KeywordSend.new(                         line,                         Atomo::AST::Primitive.new(line, :self),                         as.last,                         as.first,                         true                       )                     })
  def _skeyword_send

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
    _tmp = apply(:_level2)
    r = @result
    unless _tmp
      self.pos = _save1
      break
    end
    _tmp = _cont()
    unless _tmp
      self.pos = _save1
      break
    end
    _tmp = apply(:_keyword_args)
    as = @result
    unless _tmp
      self.pos = _save1
      break
    end
    @result = begin;  Atomo::AST::KeywordSend.new(
                        line,
                        r,
                        as.last,
                        as.first
                      )
                    ; end
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
    _tmp = apply(:_keyword_args)
    as = @result
    unless _tmp
      self.pos = _save2
      break
    end
    @result = begin;  Atomo::AST::KeywordSend.new(
                        line,
                        Atomo::AST::Primitive.new(line, :self),
                        as.last,
                        as.first,
                        true
                      )
                    ; end
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

    return _tmp
  end

  # keyword_send = ~{ done } { save } skeyword_send:t { t }
  def _keyword_send

    _save = self.pos
    begin
    while true # sequence
    @result = begin;  save ; end
    _tmp = true
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = apply(:_skeyword_send)
    t = @result
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  t ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    ensure
 done     end
    return _tmp
  end

  # binary_chain = line:line level3:r (@cont operator:o sig_wsp level3:e { [o, e] })+:bs { os, es = [], [r]                       bs.each do |o, e|                         os << o                         es << e                       end                       [os, es]                     }
  def _binary_chain

    _save = self.pos
    while true # sequence
    _tmp = apply(:_line)
    line = @result
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = apply(:_level3)
    r = @result
    unless _tmp
      self.pos = _save
      break
    end
    _save1 = self.pos
    _ary = []

    _save2 = self.pos
    while true # sequence
    _tmp = _cont()
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
    _tmp = apply(:_sig_wsp)
    unless _tmp
      self.pos = _save2
      break
    end
    _tmp = apply(:_level3)
    e = @result
    unless _tmp
      self.pos = _save2
      break
    end
    @result = begin;  [o, e] ; end
    _tmp = true
    unless _tmp
      self.pos = _save2
    end
    break
    end # end sequence

    if _tmp
      _ary << @result
      while true
    
    _save3 = self.pos
    while true # sequence
    _tmp = _cont()
    unless _tmp
      self.pos = _save3
      break
    end
    _tmp = apply(:_operator)
    o = @result
    unless _tmp
      self.pos = _save3
      break
    end
    _tmp = apply(:_sig_wsp)
    unless _tmp
      self.pos = _save3
      break
    end
    _tmp = apply(:_level3)
    e = @result
    unless _tmp
      self.pos = _save3
      break
    end
    @result = begin;  [o, e] ; end
    _tmp = true
    unless _tmp
      self.pos = _save3
    end
    break
    end # end sequence

        _ary << @result if _tmp
        break unless _tmp
      end
      _tmp = true
      @result = _ary
    else
      self.pos = _save1
    end
    bs = @result
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  os, es = [], [r]
                      bs.each do |o, e|
                        os << o
                        es << e
                      end
                      [os, es]
                    ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end

  # binary_send = (~{ done } { save } binary_chain:t { op_chain(t[0], t[1]) } | line:line operator:o sig_wsp expression:r { Atomo::AST::BinarySend.new(                         line,                         Atomo::AST::Primitive.new(line, :self),                         r,                         o                       )                     })
  def _binary_send

    _save = self.pos
    while true # choice

    _save1 = self.pos
    begin
    while true # sequence
    @result = begin;  save ; end
    _tmp = true
    unless _tmp
      self.pos = _save1
      break
    end
    _tmp = apply(:_binary_chain)
    t = @result
    unless _tmp
      self.pos = _save1
      break
    end
    @result = begin;  op_chain(t[0], t[1]) ; end
    _tmp = true
    unless _tmp
      self.pos = _save1
    end
    break
    end # end sequence

    ensure
 done     end
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
    _tmp = apply(:_sig_wsp)
    unless _tmp
      self.pos = _save2
      break
    end
    _tmp = apply(:_expression)
    r = @result
    unless _tmp
      self.pos = _save2
      break
    end
    @result = begin;  Atomo::AST::BinarySend.new(
                        line,
                        Atomo::AST::Primitive.new(line, :self),
                        r,
                        o
                      )
                    ; end
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

    return _tmp
  end

  # escapes = ("n" { "\n" } | "s" { " " } | "r" { "\r" } | "t" { "\t" } | "v" { "\v" } | "f" { "\f" } | "b" { "\b" } | "a" { "\a" } | "e" { "\e" } | "\\" { "\\" } | "\"" { "\"" } | "BS" { "\b" } | "HT" { "\t" } | "LF" { "\n" } | "VT" { "\v" } | "FF" { "\f" } | "CR" { "\r" } | "SO" { "\016" } | "SI" { "\017" } | "EM" { "\031" } | "FS" { "\034" } | "GS" { "\035" } | "RS" { "\036" } | "US" { "\037" } | "SP" { " " } | "NUL" { "\000" } | "SOH" { "\001" } | "STX" { "\002" } | "ETX" { "\003" } | "EOT" { "\004" } | "ENQ" { "\005" } | "ACK" { "\006" } | "BEL" { "\a" } | "DLE" { "\020" } | "DC1" { "\021" } | "DC2" { "\022" } | "DC3" { "\023" } | "DC4" { "\024" } | "NAK" { "\025" } | "SYN" { "\026" } | "ETB" { "\027" } | "CAN" { "\030" } | "SUB" { "\032" } | "ESC" { "\e" } | "DEL" { "\177" })
  def _escapes

    _save = self.pos
    while true # choice

    _save1 = self.pos
    while true # sequence
    _tmp = match_string("n")
    unless _tmp
      self.pos = _save1
      break
    end
    @result = begin;  "\n" ; end
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
    _tmp = match_string("s")
    unless _tmp
      self.pos = _save2
      break
    end
    @result = begin;  " " ; end
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
    _tmp = match_string("r")
    unless _tmp
      self.pos = _save3
      break
    end
    @result = begin;  "\r" ; end
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
    _tmp = match_string("t")
    unless _tmp
      self.pos = _save4
      break
    end
    @result = begin;  "\t" ; end
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
    _tmp = match_string("v")
    unless _tmp
      self.pos = _save5
      break
    end
    @result = begin;  "\v" ; end
    _tmp = true
    unless _tmp
      self.pos = _save5
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save6 = self.pos
    while true # sequence
    _tmp = match_string("f")
    unless _tmp
      self.pos = _save6
      break
    end
    @result = begin;  "\f" ; end
    _tmp = true
    unless _tmp
      self.pos = _save6
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save7 = self.pos
    while true # sequence
    _tmp = match_string("b")
    unless _tmp
      self.pos = _save7
      break
    end
    @result = begin;  "\b" ; end
    _tmp = true
    unless _tmp
      self.pos = _save7
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save8 = self.pos
    while true # sequence
    _tmp = match_string("a")
    unless _tmp
      self.pos = _save8
      break
    end
    @result = begin;  "\a" ; end
    _tmp = true
    unless _tmp
      self.pos = _save8
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save9 = self.pos
    while true # sequence
    _tmp = match_string("e")
    unless _tmp
      self.pos = _save9
      break
    end
    @result = begin;  "\e" ; end
    _tmp = true
    unless _tmp
      self.pos = _save9
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save10 = self.pos
    while true # sequence
    _tmp = match_string("\\")
    unless _tmp
      self.pos = _save10
      break
    end
    @result = begin;  "\\" ; end
    _tmp = true
    unless _tmp
      self.pos = _save10
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save11 = self.pos
    while true # sequence
    _tmp = match_string("\"")
    unless _tmp
      self.pos = _save11
      break
    end
    @result = begin;  "\"" ; end
    _tmp = true
    unless _tmp
      self.pos = _save11
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save12 = self.pos
    while true # sequence
    _tmp = match_string("BS")
    unless _tmp
      self.pos = _save12
      break
    end
    @result = begin;  "\b" ; end
    _tmp = true
    unless _tmp
      self.pos = _save12
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save13 = self.pos
    while true # sequence
    _tmp = match_string("HT")
    unless _tmp
      self.pos = _save13
      break
    end
    @result = begin;  "\t" ; end
    _tmp = true
    unless _tmp
      self.pos = _save13
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save14 = self.pos
    while true # sequence
    _tmp = match_string("LF")
    unless _tmp
      self.pos = _save14
      break
    end
    @result = begin;  "\n" ; end
    _tmp = true
    unless _tmp
      self.pos = _save14
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save15 = self.pos
    while true # sequence
    _tmp = match_string("VT")
    unless _tmp
      self.pos = _save15
      break
    end
    @result = begin;  "\v" ; end
    _tmp = true
    unless _tmp
      self.pos = _save15
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save16 = self.pos
    while true # sequence
    _tmp = match_string("FF")
    unless _tmp
      self.pos = _save16
      break
    end
    @result = begin;  "\f" ; end
    _tmp = true
    unless _tmp
      self.pos = _save16
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save17 = self.pos
    while true # sequence
    _tmp = match_string("CR")
    unless _tmp
      self.pos = _save17
      break
    end
    @result = begin;  "\r" ; end
    _tmp = true
    unless _tmp
      self.pos = _save17
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save18 = self.pos
    while true # sequence
    _tmp = match_string("SO")
    unless _tmp
      self.pos = _save18
      break
    end
    @result = begin;  "\016" ; end
    _tmp = true
    unless _tmp
      self.pos = _save18
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save19 = self.pos
    while true # sequence
    _tmp = match_string("SI")
    unless _tmp
      self.pos = _save19
      break
    end
    @result = begin;  "\017" ; end
    _tmp = true
    unless _tmp
      self.pos = _save19
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save20 = self.pos
    while true # sequence
    _tmp = match_string("EM")
    unless _tmp
      self.pos = _save20
      break
    end
    @result = begin;  "\031" ; end
    _tmp = true
    unless _tmp
      self.pos = _save20
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save21 = self.pos
    while true # sequence
    _tmp = match_string("FS")
    unless _tmp
      self.pos = _save21
      break
    end
    @result = begin;  "\034" ; end
    _tmp = true
    unless _tmp
      self.pos = _save21
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save22 = self.pos
    while true # sequence
    _tmp = match_string("GS")
    unless _tmp
      self.pos = _save22
      break
    end
    @result = begin;  "\035" ; end
    _tmp = true
    unless _tmp
      self.pos = _save22
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save23 = self.pos
    while true # sequence
    _tmp = match_string("RS")
    unless _tmp
      self.pos = _save23
      break
    end
    @result = begin;  "\036" ; end
    _tmp = true
    unless _tmp
      self.pos = _save23
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save24 = self.pos
    while true # sequence
    _tmp = match_string("US")
    unless _tmp
      self.pos = _save24
      break
    end
    @result = begin;  "\037" ; end
    _tmp = true
    unless _tmp
      self.pos = _save24
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save25 = self.pos
    while true # sequence
    _tmp = match_string("SP")
    unless _tmp
      self.pos = _save25
      break
    end
    @result = begin;  " " ; end
    _tmp = true
    unless _tmp
      self.pos = _save25
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save26 = self.pos
    while true # sequence
    _tmp = match_string("NUL")
    unless _tmp
      self.pos = _save26
      break
    end
    @result = begin;  "\000" ; end
    _tmp = true
    unless _tmp
      self.pos = _save26
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save27 = self.pos
    while true # sequence
    _tmp = match_string("SOH")
    unless _tmp
      self.pos = _save27
      break
    end
    @result = begin;  "\001" ; end
    _tmp = true
    unless _tmp
      self.pos = _save27
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save28 = self.pos
    while true # sequence
    _tmp = match_string("STX")
    unless _tmp
      self.pos = _save28
      break
    end
    @result = begin;  "\002" ; end
    _tmp = true
    unless _tmp
      self.pos = _save28
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save29 = self.pos
    while true # sequence
    _tmp = match_string("ETX")
    unless _tmp
      self.pos = _save29
      break
    end
    @result = begin;  "\003" ; end
    _tmp = true
    unless _tmp
      self.pos = _save29
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save30 = self.pos
    while true # sequence
    _tmp = match_string("EOT")
    unless _tmp
      self.pos = _save30
      break
    end
    @result = begin;  "\004" ; end
    _tmp = true
    unless _tmp
      self.pos = _save30
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save31 = self.pos
    while true # sequence
    _tmp = match_string("ENQ")
    unless _tmp
      self.pos = _save31
      break
    end
    @result = begin;  "\005" ; end
    _tmp = true
    unless _tmp
      self.pos = _save31
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save32 = self.pos
    while true # sequence
    _tmp = match_string("ACK")
    unless _tmp
      self.pos = _save32
      break
    end
    @result = begin;  "\006" ; end
    _tmp = true
    unless _tmp
      self.pos = _save32
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save33 = self.pos
    while true # sequence
    _tmp = match_string("BEL")
    unless _tmp
      self.pos = _save33
      break
    end
    @result = begin;  "\a" ; end
    _tmp = true
    unless _tmp
      self.pos = _save33
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save34 = self.pos
    while true # sequence
    _tmp = match_string("DLE")
    unless _tmp
      self.pos = _save34
      break
    end
    @result = begin;  "\020" ; end
    _tmp = true
    unless _tmp
      self.pos = _save34
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save35 = self.pos
    while true # sequence
    _tmp = match_string("DC1")
    unless _tmp
      self.pos = _save35
      break
    end
    @result = begin;  "\021" ; end
    _tmp = true
    unless _tmp
      self.pos = _save35
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save36 = self.pos
    while true # sequence
    _tmp = match_string("DC2")
    unless _tmp
      self.pos = _save36
      break
    end
    @result = begin;  "\022" ; end
    _tmp = true
    unless _tmp
      self.pos = _save36
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save37 = self.pos
    while true # sequence
    _tmp = match_string("DC3")
    unless _tmp
      self.pos = _save37
      break
    end
    @result = begin;  "\023" ; end
    _tmp = true
    unless _tmp
      self.pos = _save37
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save38 = self.pos
    while true # sequence
    _tmp = match_string("DC4")
    unless _tmp
      self.pos = _save38
      break
    end
    @result = begin;  "\024" ; end
    _tmp = true
    unless _tmp
      self.pos = _save38
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save39 = self.pos
    while true # sequence
    _tmp = match_string("NAK")
    unless _tmp
      self.pos = _save39
      break
    end
    @result = begin;  "\025" ; end
    _tmp = true
    unless _tmp
      self.pos = _save39
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save40 = self.pos
    while true # sequence
    _tmp = match_string("SYN")
    unless _tmp
      self.pos = _save40
      break
    end
    @result = begin;  "\026" ; end
    _tmp = true
    unless _tmp
      self.pos = _save40
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save41 = self.pos
    while true # sequence
    _tmp = match_string("ETB")
    unless _tmp
      self.pos = _save41
      break
    end
    @result = begin;  "\027" ; end
    _tmp = true
    unless _tmp
      self.pos = _save41
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save42 = self.pos
    while true # sequence
    _tmp = match_string("CAN")
    unless _tmp
      self.pos = _save42
      break
    end
    @result = begin;  "\030" ; end
    _tmp = true
    unless _tmp
      self.pos = _save42
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save43 = self.pos
    while true # sequence
    _tmp = match_string("SUB")
    unless _tmp
      self.pos = _save43
      break
    end
    @result = begin;  "\032" ; end
    _tmp = true
    unless _tmp
      self.pos = _save43
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save44 = self.pos
    while true # sequence
    _tmp = match_string("ESC")
    unless _tmp
      self.pos = _save44
      break
    end
    @result = begin;  "\e" ; end
    _tmp = true
    unless _tmp
      self.pos = _save44
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save45 = self.pos
    while true # sequence
    _tmp = match_string("DEL")
    unless _tmp
      self.pos = _save45
      break
    end
    @result = begin;  "\177" ; end
    _tmp = true
    unless _tmp
      self.pos = _save45
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save
    break
    end # end choice

    return _tmp
  end

  # number_escapes = (/[xX]/ < /[0-9a-fA-F]{1,5}/ > { text.to_i(16).chr } | < /\d{1,6}/ > { text.to_i.chr } | /[oO]/ < /[0-7]{1,7}/ > { text.to_i(16).chr } | /[uU]/ < /[0-9a-fA-F]{4}/ > { text.to_i(16).chr })
  def _number_escapes

    _save = self.pos
    while true # choice

    _save1 = self.pos
    while true # sequence
    _tmp = scan(/\A(?-mix:[xX])/)
    unless _tmp
      self.pos = _save1
      break
    end
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[0-9a-fA-F]{1,5})/)
    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save1
      break
    end
    @result = begin;  text.to_i(16).chr ; end
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
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:\d{1,6})/)
    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save2
      break
    end
    @result = begin;  text.to_i.chr ; end
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
    _tmp = scan(/\A(?-mix:[oO])/)
    unless _tmp
      self.pos = _save3
      break
    end
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[0-7]{1,7})/)
    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save3
      break
    end
    @result = begin;  text.to_i(16).chr ; end
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
    _tmp = scan(/\A(?-mix:[uU])/)
    unless _tmp
      self.pos = _save4
      break
    end
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[0-9a-fA-F]{4})/)
    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save4
      break
    end
    @result = begin;  text.to_i(16).chr ; end
    _tmp = true
    unless _tmp
      self.pos = _save4
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save
    break
    end # end choice

    return _tmp
  end

  # quoted = ("\"" ("\\\"" { "\"" } | < "\\" . > { text } | < /[^\\"]+/ > { text })*:c "\"" { c.join } | "{" ("\\" < ("{" | "}") > { text } | < "\\" . > { text } | < /[^\\\{\}]+/ > { text })*:c "}" { c.join } | "[" ("\\" < ("[" | "]") > { text } | < "\\" . > { text } | < /[^\\\[\]]+/ > { text })*:c "]" { c.join } | "`" ("\\`" { "`" } | < "\\" . > { text } | < /[^\\`]+/ > { text })*:c "`" { c.join } | "'" ("\\'" { "'" } | < "\\" . > { text } | < /[^\\']+/ > { text })*:c "'" { c.join })
  def _quoted

    _save = self.pos
    while true # choice

    _save1 = self.pos
    while true # sequence
    _tmp = match_string("\"")
    unless _tmp
      self.pos = _save1
      break
    end
    _ary = []
    while true

    _save3 = self.pos
    while true # choice

    _save4 = self.pos
    while true # sequence
    _tmp = match_string("\\\"")
    unless _tmp
      self.pos = _save4
      break
    end
    @result = begin;  "\"" ; end
    _tmp = true
    unless _tmp
      self.pos = _save4
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save3

    _save5 = self.pos
    while true # sequence
    _text_start = self.pos

    _save6 = self.pos
    while true # sequence
    _tmp = match_string("\\")
    unless _tmp
      self.pos = _save6
      break
    end
    _tmp = get_byte
    unless _tmp
      self.pos = _save6
    end
    break
    end # end sequence

    if _tmp
      text = get_text(_text_start)
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

    break if _tmp
    self.pos = _save3

    _save7 = self.pos
    while true # sequence
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[^\\"]+)/)
    if _tmp
      text = get_text(_text_start)
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

    break if _tmp
    self.pos = _save3
    break
    end # end choice

    _ary << @result if _tmp
    break unless _tmp
    end
    _tmp = true
    @result = _ary
    c = @result
    unless _tmp
      self.pos = _save1
      break
    end
    _tmp = match_string("\"")
    unless _tmp
      self.pos = _save1
      break
    end
    @result = begin;  c.join ; end
    _tmp = true
    unless _tmp
      self.pos = _save1
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save8 = self.pos
    while true # sequence
    _tmp = match_string("{")
    unless _tmp
      self.pos = _save8
      break
    end
    _ary = []
    while true

    _save10 = self.pos
    while true # choice

    _save11 = self.pos
    while true # sequence
    _tmp = match_string("\\")
    unless _tmp
      self.pos = _save11
      break
    end
    _text_start = self.pos

    _save12 = self.pos
    while true # choice
    _tmp = match_string("{")
    break if _tmp
    self.pos = _save12
    _tmp = match_string("}")
    break if _tmp
    self.pos = _save12
    break
    end # end choice

    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save11
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save11
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save10

    _save13 = self.pos
    while true # sequence
    _text_start = self.pos

    _save14 = self.pos
    while true # sequence
    _tmp = match_string("\\")
    unless _tmp
      self.pos = _save14
      break
    end
    _tmp = get_byte
    unless _tmp
      self.pos = _save14
    end
    break
    end # end sequence

    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save13
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save13
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save10

    _save15 = self.pos
    while true # sequence
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[^\\\{\}]+)/)
    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save15
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save15
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save10
    break
    end # end choice

    _ary << @result if _tmp
    break unless _tmp
    end
    _tmp = true
    @result = _ary
    c = @result
    unless _tmp
      self.pos = _save8
      break
    end
    _tmp = match_string("}")
    unless _tmp
      self.pos = _save8
      break
    end
    @result = begin;  c.join ; end
    _tmp = true
    unless _tmp
      self.pos = _save8
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save16 = self.pos
    while true # sequence
    _tmp = match_string("[")
    unless _tmp
      self.pos = _save16
      break
    end
    _ary = []
    while true

    _save18 = self.pos
    while true # choice

    _save19 = self.pos
    while true # sequence
    _tmp = match_string("\\")
    unless _tmp
      self.pos = _save19
      break
    end
    _text_start = self.pos

    _save20 = self.pos
    while true # choice
    _tmp = match_string("[")
    break if _tmp
    self.pos = _save20
    _tmp = match_string("]")
    break if _tmp
    self.pos = _save20
    break
    end # end choice

    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save19
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save19
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save18

    _save21 = self.pos
    while true # sequence
    _text_start = self.pos

    _save22 = self.pos
    while true # sequence
    _tmp = match_string("\\")
    unless _tmp
      self.pos = _save22
      break
    end
    _tmp = get_byte
    unless _tmp
      self.pos = _save22
    end
    break
    end # end sequence

    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save21
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save21
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save18

    _save23 = self.pos
    while true # sequence
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[^\\\[\]]+)/)
    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save23
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save23
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save18
    break
    end # end choice

    _ary << @result if _tmp
    break unless _tmp
    end
    _tmp = true
    @result = _ary
    c = @result
    unless _tmp
      self.pos = _save16
      break
    end
    _tmp = match_string("]")
    unless _tmp
      self.pos = _save16
      break
    end
    @result = begin;  c.join ; end
    _tmp = true
    unless _tmp
      self.pos = _save16
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save24 = self.pos
    while true # sequence
    _tmp = match_string("`")
    unless _tmp
      self.pos = _save24
      break
    end
    _ary = []
    while true

    _save26 = self.pos
    while true # choice

    _save27 = self.pos
    while true # sequence
    _tmp = match_string("\\`")
    unless _tmp
      self.pos = _save27
      break
    end
    @result = begin;  "`" ; end
    _tmp = true
    unless _tmp
      self.pos = _save27
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save26

    _save28 = self.pos
    while true # sequence
    _text_start = self.pos

    _save29 = self.pos
    while true # sequence
    _tmp = match_string("\\")
    unless _tmp
      self.pos = _save29
      break
    end
    _tmp = get_byte
    unless _tmp
      self.pos = _save29
    end
    break
    end # end sequence

    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save28
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save28
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save26

    _save30 = self.pos
    while true # sequence
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[^\\`]+)/)
    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save30
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save30
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save26
    break
    end # end choice

    _ary << @result if _tmp
    break unless _tmp
    end
    _tmp = true
    @result = _ary
    c = @result
    unless _tmp
      self.pos = _save24
      break
    end
    _tmp = match_string("`")
    unless _tmp
      self.pos = _save24
      break
    end
    @result = begin;  c.join ; end
    _tmp = true
    unless _tmp
      self.pos = _save24
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save31 = self.pos
    while true # sequence
    _tmp = match_string("'")
    unless _tmp
      self.pos = _save31
      break
    end
    _ary = []
    while true

    _save33 = self.pos
    while true # choice

    _save34 = self.pos
    while true # sequence
    _tmp = match_string("\\'")
    unless _tmp
      self.pos = _save34
      break
    end
    @result = begin;  "'" ; end
    _tmp = true
    unless _tmp
      self.pos = _save34
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save33

    _save35 = self.pos
    while true # sequence
    _text_start = self.pos

    _save36 = self.pos
    while true # sequence
    _tmp = match_string("\\")
    unless _tmp
      self.pos = _save36
      break
    end
    _tmp = get_byte
    unless _tmp
      self.pos = _save36
    end
    break
    end # end sequence

    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save35
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save35
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save33

    _save37 = self.pos
    while true # sequence
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:[^\\']+)/)
    if _tmp
      text = get_text(_text_start)
    end
    unless _tmp
      self.pos = _save37
      break
    end
    @result = begin;  text ; end
    _tmp = true
    unless _tmp
      self.pos = _save37
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save33
    break
    end # end choice

    _ary << @result if _tmp
    break unless _tmp
    end
    _tmp = true
    @result = _ary
    c = @result
    unless _tmp
      self.pos = _save31
      break
    end
    _tmp = match_string("'")
    unless _tmp
      self.pos = _save31
      break
    end
    @result = begin;  c.join ; end
    _tmp = true
    unless _tmp
      self.pos = _save31
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save
    break
    end # end choice

    return _tmp
  end

  # root = wsp expressions:es wsp !. { es }
  def _root

    _save = self.pos
    while true # sequence
    _tmp = apply(:_wsp)
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = apply(:_expressions)
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
    _save1 = self.pos
    _tmp = get_byte
    _tmp = _tmp ? nil : true
    self.pos = _save1
    unless _tmp
      self.pos = _save
      break
    end
    @result = begin;  es ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    return _tmp
  end
end

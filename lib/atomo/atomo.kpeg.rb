class Atomo::Parser
# STANDALONE START
    def setup_parser(str, debug=false)
      @string = str
      @pos = 0
      @memoizations = Hash.new { |h,k| h[k] = {} }
      @result = nil
      @failed_rule = nil
      @failing_rule_offset = -1
    end

    # This is distinct from setup_parser so that a standalone parser
    # can redefine #initialize and still have access to the proper
    # parser setup code.
    #
    def initialize(str, debug=false)
      setup_parser(str, debug)
    end

    attr_reader :string
    attr_reader :result, :failing_rule_offset
    attr_accessor :pos

    # STANDALONE START
    def current_column(target=pos)
      if c = string.rindex("\n", target-1)
        return target - c - 1
      end

      target + 1
    end

    def current_line(target=pos)
      cur_offset = 0
      cur_line = 0

      string.each_line do |line|
        cur_line += 1
        cur_offset += line.size
        return cur_line if cur_offset >= target
      end

      -1
    end

    def lines
      lines = []
      string.each_line { |l| lines << l }
      lines
    end

    #

    def get_text(start)
      @string[start..@pos-1]
    end

    def show_pos
      width = 10
      if @pos < width
        "#{@pos} (\"#{@string[0,@pos]}\" @ \"#{@string[@pos,width]}\")"
      else
        "#{@pos} (\"... #{@string[@pos - width, width]}\" @ \"#{@string[@pos,width]}\")"
      end
    end

    def failure_info
      l = current_line @failing_rule_offset
      c = current_column @failing_rule_offset
      info = self.class::Rules[@failed_rule]

      "line #{l}, column #{c}: failed rule '#{info.name}' = '#{info.rendered}'"
    end

    def failure_caret
      l = current_line @failing_rule_offset
      c = current_column @failing_rule_offset

      line = lines[l-1]
      "#{line}\n#{' ' * (c - 1)}^"
    end

    def failure_character
      l = current_line @failing_rule_offset
      c = current_column @failing_rule_offset
      lines[l-1][c-1, 1]
    end

    def failure_oneline
      l = current_line @failing_rule_offset
      c = current_column @failing_rule_offset

      info = self.class::Rules[@failed_rule]
      char = lines[l-1][c-1, 1]

      "@#{l}:#{c} failed rule '#{info.name}', got '#{char}'"
    end

    class ParseError < RuntimeError
    end

    def raise_error
      raise ParseError, failure_oneline
    end

    def show_error(io=STDOUT)
      error_pos = @failing_rule_offset
      line_no = current_line(error_pos)
      col_no = current_column(error_pos)

      info = self.class::Rules[@failed_rule]
      io.puts "On line #{line_no}, column #{col_no}:"
      io.puts "Failed to match '#{info.rendered}' (rule '#{info.name}')"
      io.puts "Got: #{string[error_pos,1].inspect}"
      line = lines[line_no-1]
      io.puts "=> #{line}"
      io.print(" " * (col_no + 3))
      io.puts "^"
    end

    def set_failed_rule(name)
      if @pos > @failing_rule_offset
        @failed_rule = name
        @failing_rule_offset = @pos
      end
    end

    attr_reader :failed_rule

    def match_string(str)
      len = str.size
      if @string[pos,len] == str
        @pos += len
        return str
      end

      return nil
    end

    def scan(reg)
      if m = reg.match(@string[@pos..-1])
        width = m.end(0)
        @pos += width
        return true
      end

      return nil
    end

    if "".respond_to? :getbyte
      def get_byte
        if @pos >= @string.size
          return nil
        end

        s = @string.getbyte @pos
        @pos += 1
        s
      end
    else
      def get_byte
        if @pos >= @string.size
          return nil
        end

        s = @string[@pos]
        @pos += 1
        s
      end
    end

    def parse
      _root ? true : false
    end

    class LeftRecursive
      def initialize(detected=false)
        @detected = detected
      end

      attr_accessor :detected
    end

    class MemoEntry
      def initialize(ans, pos)
        @ans = ans
        @pos = pos
        @uses = 1
        @result = nil
      end

      attr_reader :ans, :pos, :uses, :result

      def inc!
        @uses += 1
      end

      def move!(ans, pos, result)
        @ans = ans
        @pos = pos
        @result = result
      end
    end

    def apply(rule)
      if m = @memoizations[rule][@pos]
        m.inc!

        prev = @pos
        @pos = m.pos
        if m.ans.kind_of? LeftRecursive
          m.ans.detected = true
          return nil
        end

        @result = m.result

        return m.ans
      else
        lr = LeftRecursive.new(false)
        m = MemoEntry.new(lr, @pos)
        @memoizations[rule][@pos] = m
        start_pos = @pos

        ans = __send__ rule

        m.move! ans, @pos, @result

        # Don't bother trying to grow the left recursion
        # if it's failing straight away (thus there is no seed)
        if ans and lr.detected
          return grow_lr(rule, start_pos, m)
        else
          return ans
        end

        return ans
      end
    end

    def grow_lr(rule, start_pos, m)
      while true
        @pos = start_pos
        @result = m.result

        ans = __send__ rule
        return nil unless ans

        break if @pos <= m.pos

        m.move! ans, @pos, @result
      end

      @result = m.result
      @pos = m.pos
      return m.ans
    end

    class RuleInfo
      def initialize(name, rendered)
        @name = name
        @rendered = rendered
      end

      attr_reader :name, :rendered
    end

    def self.rule_info(name, rendered)
      RuleInfo.new(name, rendered)
    end

    #


  def current_position(target=pos)
    cur_offset = 0
    cur_line = 0

    line_lengths.each do |len|
      cur_line += 1
      return [cur_line, target - cur_offset] if cur_offset + len > target
      cur_offset += len
    end
  end

  def line_lengths
    @line_lengths ||= lines.collect { |l| l.size }
  end

  def continue?(x)
    y = current_position
    y[0] >= x[0] && y[1] > x[1]
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

  # cont = (("\n" sp)+ &{ continue?(p) } | sig_sp (("\n" sp)+ &{ continue?(p) })?)
  def _cont(p)

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
    _tmp = begin;  continue?(p) ; end
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

    set_failed_rule :_cont unless _tmp
    return _tmp
  end

  # line = { current_line }
  def _line
    @result = begin;  current_line ; end
    _tmp = true
    set_failed_rule :_line unless _tmp
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

    set_failed_rule :_ident_start unless _tmp
    return _tmp
  end

  # ident_letters = < /([[:alnum:]\$\+\<=\>\^~!@#%&*\-.\/\?])*/ > { text }
  def _ident_letters

    _save = self.pos
    while true # sequence
    _text_start = self.pos
    _tmp = scan(/\A(?-mix:([[:alnum:]\$\+\<=\>\^~!@#%&*\-.\/\?])*)/)
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

    set_failed_rule :_ident_letters unless _tmp
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

    set_failed_rule :_op_start unless _tmp
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

    set_failed_rule :_op_letters unless _tmp
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

    set_failed_rule :_f_ident_start unless _tmp
    return _tmp
  end

  # operator = < op_start op_letters > &{ text != ":" } { text }
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
    _save2 = self.pos
    _tmp = begin;  text != ":" ; end
    self.pos = _save2
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

    set_failed_rule :_operator unless _tmp
    return _tmp
  end

  # identifier = < ident_start ident_letters > { text.tr("-", "_") }
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
    @result = begin;  text.tr("-", "_") ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    set_failed_rule :_identifier unless _tmp
    return _tmp
  end

  # f_identifier = < f_ident_start ident_letters > { text.tr("-", "_") }
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
    @result = begin;  text.tr("-", "_") ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    set_failed_rule :_f_identifier unless _tmp
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

  # expression = level3
  def _expression
    _tmp = apply(:_level3)
    set_failed_rule :_expression unless _tmp
    return _tmp
  end

  # expressions = { current_column }:c expression:x (delim(c) expression)*:xs delim(c)? { [x] + Array(xs) }
  def _expressions

    _save = self.pos
    while true # sequence
    @result = begin;  current_column ; end
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
    _tmp = _delim(c)
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
    _tmp = _delim(c)
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

    set_failed_rule :_expressions unless _tmp
    return _tmp
  end

  # level1 = (true | false | self | nil | number | quote | quasi_quote | unquote | string | macro_quote | particle | constant | variable | block | grouped | list | unary_op)
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
    _tmp = apply(:_variable)
    break if _tmp
    self.pos = _save
    _tmp = apply(:_block)
    break if _tmp
    self.pos = _save
    _tmp = apply(:_grouped)
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

    set_failed_rule :_level1 unless _tmp
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

    set_failed_rule :_level2 unless _tmp
    return _tmp
  end

  # level3 = (macro | for_macro | op_assoc_prec | binary_send | level2)
  def _level3

    _save = self.pos
    while true # choice
    _tmp = apply(:_macro)
    break if _tmp
    self.pos = _save
    _tmp = apply(:_for_macro)
    break if _tmp
    self.pos = _save
    _tmp = apply(:_op_assoc_prec)
    break if _tmp
    self.pos = _save
    _tmp = apply(:_binary_send)
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

    set_failed_rule :_true unless _tmp
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

    set_failed_rule :_false unless _tmp
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

    set_failed_rule :_self unless _tmp
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

    set_failed_rule :_nil unless _tmp
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

    set_failed_rule :_number unless _tmp
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

    set_failed_rule :_macro unless _tmp
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

    set_failed_rule :_for_macro unless _tmp
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

    set_failed_rule :_op_assoc unless _tmp
    return _tmp
  end

  # op_prec = sig_wsp < /[0-9]+/ > { text.to_i }
  def _op_prec

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

    set_failed_rule :_op_prec unless _tmp
    return _tmp
  end

  # op_assoc_prec = line:line "operator" op_assoc?:assoc op_prec:prec (sig_wsp operator)+:os { Atomo::Macro.set_op_info(os, assoc, prec)                       Atomo::AST::Operator.new(line, assoc, prec, os)                     }
  def _op_assoc_prec

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
    _tmp = apply(:_op_prec)
    prec = @result
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
    @result = begin;  Atomo::Macro.set_op_info(os, assoc, prec)
                      Atomo::AST::Operator.new(line, assoc, prec, os)
                    ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    set_failed_rule :_op_assoc_prec unless _tmp
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

    set_failed_rule :_quote unless _tmp
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

    set_failed_rule :_quasi_quote unless _tmp
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

    set_failed_rule :_unquote unless _tmp
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

    set_failed_rule :_escape unless _tmp
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

    set_failed_rule :_str_seq unless _tmp
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

    set_failed_rule :_string unless _tmp
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
    _save3 = self.pos
    _tmp = get_byte
    if _tmp
      unless _tmp >= 97 and _tmp <= 122
        self.pos = _save3
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

    set_failed_rule :_macro_quote unless _tmp
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

    set_failed_rule :_particle unless _tmp
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

    set_failed_rule :_constant_name unless _tmp
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

    set_failed_rule :_constant unless _tmp
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

    set_failed_rule :_variable unless _tmp
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

    set_failed_rule :_unary_op unless _tmp
    return _tmp
  end

  # block_args = "(" wsp expressions?:as wsp ")" { as }
  def _block_args

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
    @result = begin;  as ; end
    _tmp = true
    unless _tmp
      self.pos = _save
    end
    break
    end # end sequence

    set_failed_rule :_block_args unless _tmp
    return _tmp
  end

  # block = line:line block_args?:as ":" !operator wsp expressions?:es (wsp ";")? { Atomo::AST::Block.new(line, Array(es), Array(as)) }
  def _block

    _save = self.pos
    while true # sequence
    _tmp = apply(:_line)
    line = @result
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
    _tmp = match_string(":")
    unless _tmp
      self.pos = _save
      break
    end
    _save2 = self.pos
    _tmp = apply(:_operator)
    _tmp = _tmp ? nil : true
    self.pos = _save2
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
    _tmp = apply(:_expressions)
    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save3
    end
    es = @result
    unless _tmp
      self.pos = _save
      break
    end
    _save4 = self.pos

    _save5 = self.pos
    while true # sequence
    _tmp = apply(:_wsp)
    unless _tmp
      self.pos = _save5
      break
    end
    _tmp = match_string(";")
    unless _tmp
      self.pos = _save5
    end
    break
    end # end sequence

    unless _tmp
      _tmp = true
      self.pos = _save4
    end
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

    set_failed_rule :_block unless _tmp
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

    set_failed_rule :_list unless _tmp
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

    set_failed_rule :_unary_args unless _tmp
    return _tmp
  end

  # unary_c = (line:line unary_send:r cont(pos) identifier:n unary_args?:as (sp block)?:b { Atomo::AST::UnarySend.new(line, r, Array(as), n, b) } | line:line level1:r cont(pos) identifier:n unary_args?:as (sp block)?:b { Atomo::AST::UnarySend.new(line, r, Array(as), n, b) } | line:line identifier:n unary_args?:as sp block:b { Atomo::AST::UnarySend.new(                         line,                         Atomo::AST::Primitive.new(line, :self),                         Array(as),                         n,                         b,                         true                       )                     } | line:line identifier:n unary_args:as (sp block)?:b { Atomo::AST::UnarySend.new(                         line,                         Atomo::AST::Primitive.new(line, :self),                         as,                         n,                         b,                         true                       )                     })
  def _unary_c(pos)

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
    _tmp = apply(:_unary_send)
    r = @result
    unless _tmp
      self.pos = _save1
      break
    end
    _tmp = _cont(pos)
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
    _tmp = apply(:_unary_args)
    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save2
    end
    as = @result
    unless _tmp
      self.pos = _save1
      break
    end
    _save3 = self.pos

    _save4 = self.pos
    while true # sequence
    _tmp = apply(:_sp)
    unless _tmp
      self.pos = _save4
      break
    end
    _tmp = apply(:_block)
    unless _tmp
      self.pos = _save4
    end
    break
    end # end sequence

    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save3
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

    _save5 = self.pos
    while true # sequence
    _tmp = apply(:_line)
    line = @result
    unless _tmp
      self.pos = _save5
      break
    end
    _tmp = apply(:_level1)
    r = @result
    unless _tmp
      self.pos = _save5
      break
    end
    _tmp = _cont(pos)
    unless _tmp
      self.pos = _save5
      break
    end
    _tmp = apply(:_identifier)
    n = @result
    unless _tmp
      self.pos = _save5
      break
    end
    _save6 = self.pos
    _tmp = apply(:_unary_args)
    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save6
    end
    as = @result
    unless _tmp
      self.pos = _save5
      break
    end
    _save7 = self.pos

    _save8 = self.pos
    while true # sequence
    _tmp = apply(:_sp)
    unless _tmp
      self.pos = _save8
      break
    end
    _tmp = apply(:_block)
    unless _tmp
      self.pos = _save8
    end
    break
    end # end sequence

    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save7
    end
    b = @result
    unless _tmp
      self.pos = _save5
      break
    end
    @result = begin;  Atomo::AST::UnarySend.new(line, r, Array(as), n, b) ; end
    _tmp = true
    unless _tmp
      self.pos = _save5
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save

    _save9 = self.pos
    while true # sequence
    _tmp = apply(:_line)
    line = @result
    unless _tmp
      self.pos = _save9
      break
    end
    _tmp = apply(:_identifier)
    n = @result
    unless _tmp
      self.pos = _save9
      break
    end
    _save10 = self.pos
    _tmp = apply(:_unary_args)
    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save10
    end
    as = @result
    unless _tmp
      self.pos = _save9
      break
    end
    _tmp = apply(:_sp)
    unless _tmp
      self.pos = _save9
      break
    end
    _tmp = apply(:_block)
    b = @result
    unless _tmp
      self.pos = _save9
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
      self.pos = _save9
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
    _tmp = apply(:_unary_args)
    as = @result
    unless _tmp
      self.pos = _save11
      break
    end
    _save12 = self.pos

    _save13 = self.pos
    while true # sequence
    _tmp = apply(:_sp)
    unless _tmp
      self.pos = _save13
      break
    end
    _tmp = apply(:_block)
    unless _tmp
      self.pos = _save13
    end
    break
    end # end sequence

    @result = nil unless _tmp
    unless _tmp
      _tmp = true
      self.pos = _save12
    end
    b = @result
    unless _tmp
      self.pos = _save11
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
      self.pos = _save11
    end
    break
    end # end sequence

    break if _tmp
    self.pos = _save
    break
    end # end choice

    set_failed_rule :_unary_c unless _tmp
    return _tmp
  end

  # unary_send = unary_c(current_position)
  def _unary_send
    _tmp = _unary_c(current_position)
    set_failed_rule :_unary_send unless _tmp
    return _tmp
  end

  # binary_c = line:line level2:r (cont(pos) operator:o sig_wsp level2:e { [o, e] })+:bs { os, es = [], [r]                       bs.each do |o, e|                         os << o                         es << e                       end                       [os, es]                     }
  def _binary_c(pos)

    _save = self.pos
    while true # sequence
    _tmp = apply(:_line)
    line = @result
    unless _tmp
      self.pos = _save
      break
    end
    _tmp = apply(:_level2)
    r = @result
    unless _tmp
      self.pos = _save
      break
    end
    _save1 = self.pos
    _ary = []

    _save2 = self.pos
    while true # sequence
    _tmp = _cont(pos)
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
    _tmp = apply(:_level2)
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
    _tmp = _cont(pos)
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
    _tmp = apply(:_level2)
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

    set_failed_rule :_binary_c unless _tmp
    return _tmp
  end

  # binary_send = (binary_c(current_position):t { op_chain(t[0], t[1]) } | line:line operator:o sig_wsp expression:r { Atomo::AST::BinarySend.new(                         line,                         Atomo::AST::Primitive.new(line, :self),                         r,                         o,                         true                       )                     })
  def _binary_send

    _save = self.pos
    while true # choice

    _save1 = self.pos
    while true # sequence
    _tmp = _binary_c(current_position)
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
                        o,
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

    set_failed_rule :_binary_send unless _tmp
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

    set_failed_rule :_escapes unless _tmp
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

    set_failed_rule :_number_escapes unless _tmp
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

    set_failed_rule :_quoted unless _tmp
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

    set_failed_rule :_root unless _tmp
    return _tmp
  end

  Rules = {}
  Rules[:_sp] = rule_info("sp", "(\" \" | \"\\t\" | comment)*")
  Rules[:_wsp] = rule_info("wsp", "(\" \" | \"\\t\" | \"\\n\" | comment)*")
  Rules[:_sig_sp] = rule_info("sig_sp", "(\" \" | \"\\t\" | comment)+")
  Rules[:_sig_wsp] = rule_info("sig_wsp", "(\" \" | \"\\t\" | \"\\n\" | comment)+")
  Rules[:_cont] = rule_info("cont", "((\"\\n\" sp)+ &{ continue?(p) } | sig_sp ((\"\\n\" sp)+ &{ continue?(p) })?)")
  Rules[:_line] = rule_info("line", "{ current_line }")
  Rules[:_ident_start] = rule_info("ident_start", "< /[[a-z]_]/ > { text }")
  Rules[:_ident_letters] = rule_info("ident_letters", "< /([[:alnum:]\\$\\+\\<=\\>\\^~!@#%&*\\-.\\/\\?])*/ > { text }")
  Rules[:_op_start] = rule_info("op_start", "< /[\\$\\+\\<=\\>\\^~!@&#%\\|&*\\-.\\/\\?:]/ > { text }")
  Rules[:_op_letters] = rule_info("op_letters", "< /([\\$\\+\\<=\\>\\^~!@&#%\\|&*\\-.\\/\\?:])*/ > { text }")
  Rules[:_f_ident_start] = rule_info("f_ident_start", "< /[[:alpha:]\\$\\+\\<=\\>\\^`~_!@#%&*\\-.\\/\\?]/ > { text }")
  Rules[:_operator] = rule_info("operator", "< op_start op_letters > &{ text != \":\" } { text }")
  Rules[:_identifier] = rule_info("identifier", "< ident_start ident_letters > { text.tr(\"-\", \"_\") }")
  Rules[:_f_identifier] = rule_info("f_identifier", "< f_ident_start ident_letters > { text.tr(\"-\", \"_\") }")
  Rules[:_grouped] = rule_info("grouped", "\"(\" wsp expression:x wsp \")\" { x }")
  Rules[:_comment] = rule_info("comment", "(/--.*?$/ | multi_comment)")
  Rules[:_multi_comment] = rule_info("multi_comment", "\"{-\" in_multi")
  Rules[:_in_multi] = rule_info("in_multi", "(/[^\\-\\{\\}]*/ \"-}\" | /[^\\-\\{\\}]*/ \"{-\" in_multi /[^\\-\\{\\}]*/ \"-}\" | /[^\\-\\{\\}]*/ /[-{}]/ in_multi)")
  Rules[:_delim] = rule_info("delim", "(wsp \",\" wsp | (sp \"\\n\" sp)+ &{ current_column >= c })")
  Rules[:_expression] = rule_info("expression", "level3")
  Rules[:_expressions] = rule_info("expressions", "{ current_column }:c expression:x (delim(c) expression)*:xs delim(c)? { [x] + Array(xs) }")
  Rules[:_level1] = rule_info("level1", "(true | false | self | nil | number | quote | quasi_quote | unquote | string | macro_quote | particle | constant | variable | block | grouped | list | unary_op)")
  Rules[:_level2] = rule_info("level2", "(unary_send | level1)")
  Rules[:_level3] = rule_info("level3", "(macro | for_macro | op_assoc_prec | binary_send | level2)")
  Rules[:_true] = rule_info("true", "line:line \"true\" !f_identifier { Atomo::AST::Primitive.new(line, :true) }")
  Rules[:_false] = rule_info("false", "line:line \"false\" !f_identifier { Atomo::AST::Primitive.new(line, :false) }")
  Rules[:_self] = rule_info("self", "line:line \"self\" !f_identifier { Atomo::AST::Primitive.new(line, :self) }")
  Rules[:_nil] = rule_info("nil", "line:line \"nil\" !f_identifier { Atomo::AST::Primitive.new(line, :nil) }")
  Rules[:_number] = rule_info("number", "(line:line < /[\\+\\-]?0[oO][\\da-fA-F]+/ > { Atomo::AST::Primitive.new(line, text.to_i(8)) } | line:line < /[\\+\\-]?0[xX][0-7]+/ > { Atomo::AST::Primitive.new(line, text.to_i(16)) } | line:line < /[\\+\\-]?\\d+(\\.\\d+)?[eE][\\+\\-]?\\d+/ > { Atomo::AST::Primitive.new(line, text.to_f) } | line:line < /[\\+\\-]?\\d+\\.\\d+/ > { Atomo::AST::Primitive.new(line, text.to_f) } | line:line < /[\\+\\-]?\\d+/ > { Atomo::AST::Primitive.new(line, text.to_i) })")
  Rules[:_macro] = rule_info("macro", "line:line \"macro\" wsp \"(\" wsp expression:p wsp \")\" wsp expression:b { b; Atomo::AST::Macro.new(line, p, b) }")
  Rules[:_for_macro] = rule_info("for_macro", "line:line \"for-macro\" wsp expression:b { Atomo::AST::ForMacro.new(line, b) }")
  Rules[:_op_assoc] = rule_info("op_assoc", "sig_wsp < /left|right/ > { text.to_sym }")
  Rules[:_op_prec] = rule_info("op_prec", "sig_wsp < /[0-9]+/ > { text.to_i }")
  Rules[:_op_assoc_prec] = rule_info("op_assoc_prec", "line:line \"operator\" op_assoc?:assoc op_prec:prec (sig_wsp operator)+:os { Atomo::Macro.set_op_info(os, assoc, prec)                       Atomo::AST::Operator.new(line, assoc, prec, os)                     }")
  Rules[:_quote] = rule_info("quote", "line:line \"'\" level1:e { Atomo::AST::Quote.new(line, e) }")
  Rules[:_quasi_quote] = rule_info("quasi_quote", "line:line \"`\" level1:e { Atomo::AST::QuasiQuote.new(line, e) }")
  Rules[:_unquote] = rule_info("unquote", "line:line \"~\" level1:e { Atomo::AST::Unquote.new(line, e) }")
  Rules[:_escape] = rule_info("escape", "(number_escapes | escapes)")
  Rules[:_str_seq] = rule_info("str_seq", "< /[^\\\\\"]+/ > { text }")
  Rules[:_string] = rule_info("string", "line:line \"\\\"\" (\"\\\\\" escape | str_seq)*:c \"\\\"\" { Atomo::AST::String.new(line, c.join) }")
  Rules[:_macro_quote] = rule_info("macro_quote", "line:line identifier:n quoted:c (< [a-z] > { text })*:fs { Atomo::AST::MacroQuote.new(line, n, c, fs) }")
  Rules[:_particle] = rule_info("particle", "line:line \"#\" f_identifier:n { Atomo::AST::Particle.new(line, n) }")
  Rules[:_constant_name] = rule_info("constant_name", "< /[A-Z][a-zA-Z0-9_]*/ > { text }")
  Rules[:_constant] = rule_info("constant", "(line:line constant_name:m (\"::\" constant_name)*:s unary_args?:as {                     names = [m] + Array(s)                     if as                       msg = names.pop                       Atomo::AST::UnarySend.new(                         line,                         names.empty? ?                             Atomo::AST::Primitive.new(line, :self) :                             const_chain(line, names),                         Array(as),                         msg,                         nil,                         true                       )                     else                       const_chain(line, names)                     end                   } | line:line (\"::\" constant_name)+:s unary_args?:as {                     names = Array(s)                     if as                       msg = names.pop                       Atomo::AST::UnarySend.new(                         line,                         names.empty? ?                             Atomo::AST::Primitive.new(line, :self) :                             const_chain(line, names, true),                         Array(as),                         msg,                         nil,                         true                       )                     else                       const_chain(line, names, true)                     end                 })")
  Rules[:_variable] = rule_info("variable", "line:line identifier:n !\":\" { Atomo::AST::Variable.new(line, n) }")
  Rules[:_unary_op] = rule_info("unary_op", "line:line operator:o level1:e { Atomo::AST::UnaryOperator.new(line, e, o) }")
  Rules[:_block_args] = rule_info("block_args", "\"(\" wsp expressions?:as wsp \")\" { as }")
  Rules[:_block] = rule_info("block", "line:line block_args?:as \":\" !operator wsp expressions?:es (wsp \";\")? { Atomo::AST::Block.new(line, Array(es), Array(as)) }")
  Rules[:_list] = rule_info("list", "line:line \"[\" wsp expressions?:es wsp \"]\" { Atomo::AST::List.new(line, Array(es)) }")
  Rules[:_unary_args] = rule_info("unary_args", "\"(\" wsp expressions?:as wsp \")\" { Array(as) }")
  Rules[:_unary_c] = rule_info("unary_c", "(line:line unary_send:r cont(pos) identifier:n unary_args?:as (sp block)?:b { Atomo::AST::UnarySend.new(line, r, Array(as), n, b) } | line:line level1:r cont(pos) identifier:n unary_args?:as (sp block)?:b { Atomo::AST::UnarySend.new(line, r, Array(as), n, b) } | line:line identifier:n unary_args?:as sp block:b { Atomo::AST::UnarySend.new(                         line,                         Atomo::AST::Primitive.new(line, :self),                         Array(as),                         n,                         b,                         true                       )                     } | line:line identifier:n unary_args:as (sp block)?:b { Atomo::AST::UnarySend.new(                         line,                         Atomo::AST::Primitive.new(line, :self),                         as,                         n,                         b,                         true                       )                     })")
  Rules[:_unary_send] = rule_info("unary_send", "unary_c(current_position)")
  Rules[:_binary_c] = rule_info("binary_c", "line:line level2:r (cont(pos) operator:o sig_wsp level2:e { [o, e] })+:bs { os, es = [], [r]                       bs.each do |o, e|                         os << o                         es << e                       end                       [os, es]                     }")
  Rules[:_binary_send] = rule_info("binary_send", "(binary_c(current_position):t { op_chain(t[0], t[1]) } | line:line operator:o sig_wsp expression:r { Atomo::AST::BinarySend.new(                         line,                         Atomo::AST::Primitive.new(line, :self),                         r,                         o,                         true                       )                     })")
  Rules[:_escapes] = rule_info("escapes", "(\"n\" { \"\\n\" } | \"s\" { \" \" } | \"r\" { \"\\r\" } | \"t\" { \"\\t\" } | \"v\" { \"\\v\" } | \"f\" { \"\\f\" } | \"b\" { \"\\b\" } | \"a\" { \"\\a\" } | \"e\" { \"\\e\" } | \"\\\\\" { \"\\\\\" } | \"\\\"\" { \"\\\"\" } | \"BS\" { \"\\b\" } | \"HT\" { \"\\t\" } | \"LF\" { \"\\n\" } | \"VT\" { \"\\v\" } | \"FF\" { \"\\f\" } | \"CR\" { \"\\r\" } | \"SO\" { \"\\016\" } | \"SI\" { \"\\017\" } | \"EM\" { \"\\031\" } | \"FS\" { \"\\034\" } | \"GS\" { \"\\035\" } | \"RS\" { \"\\036\" } | \"US\" { \"\\037\" } | \"SP\" { \" \" } | \"NUL\" { \"\\000\" } | \"SOH\" { \"\\001\" } | \"STX\" { \"\\002\" } | \"ETX\" { \"\\003\" } | \"EOT\" { \"\\004\" } | \"ENQ\" { \"\\005\" } | \"ACK\" { \"\\006\" } | \"BEL\" { \"\\a\" } | \"DLE\" { \"\\020\" } | \"DC1\" { \"\\021\" } | \"DC2\" { \"\\022\" } | \"DC3\" { \"\\023\" } | \"DC4\" { \"\\024\" } | \"NAK\" { \"\\025\" } | \"SYN\" { \"\\026\" } | \"ETB\" { \"\\027\" } | \"CAN\" { \"\\030\" } | \"SUB\" { \"\\032\" } | \"ESC\" { \"\\e\" } | \"DEL\" { \"\\177\" })")
  Rules[:_number_escapes] = rule_info("number_escapes", "(/[xX]/ < /[0-9a-fA-F]{1,5}/ > { text.to_i(16).chr } | < /\\d{1,6}/ > { text.to_i.chr } | /[oO]/ < /[0-7]{1,7}/ > { text.to_i(16).chr } | /[uU]/ < /[0-9a-fA-F]{4}/ > { text.to_i(16).chr })")
  Rules[:_quoted] = rule_info("quoted", "(\"\\\"\" (\"\\\\\\\"\" { \"\\\"\" } | < \"\\\\\" . > { text } | < /[^\\\\\"]+/ > { text })*:c \"\\\"\" { c.join } | \"{\" (\"\\\\\" < (\"{\" | \"}\") > { text } | < \"\\\\\" . > { text } | < /[^\\\\\\{\\}]+/ > { text })*:c \"}\" { c.join } | \"[\" (\"\\\\\" < (\"[\" | \"]\") > { text } | < \"\\\\\" . > { text } | < /[^\\\\\\[\\]]+/ > { text })*:c \"]\" { c.join } | \"`\" (\"\\\\`\" { \"`\" } | < \"\\\\\" . > { text } | < /[^\\\\`]+/ > { text })*:c \"`\" { c.join } | \"'\" (\"\\\\'\" { \"'\" } | < \"\\\\\" . > { text } | < /[^\\\\']+/ > { text })*:c \"'\" { c.join })")
  Rules[:_root] = rule_info("root", "wsp expressions:es wsp !. { es }")
end

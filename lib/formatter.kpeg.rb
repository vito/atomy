class Atomy::Format::Parser
# STANDALONE START
    def setup_parser(str, debug=false)
      @string = str
      @pos = 0
      @memoizations = Hash.new { |h,k| h[k] = {} }
      @result = nil
      @failed_rule = nil
      @failing_rule_offset = -1

      setup_foreign_grammar
    end

    # This is distinct from setup_parser so that a standalone parser
    # can redefine #initialize and still have access to the proper
    # parser setup code.
    #
    def initialize(str, debug=false)
      setup_parser(str, debug)
    end

    attr_reader :string
    attr_reader :failing_rule_offset
    attr_accessor :result, :pos

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

      if @failed_rule.kind_of? Symbol
        info = self.class::Rules[@failed_rule]
        "line #{l}, column #{c}: failed rule '#{info.name}' = '#{info.rendered}'"
      else
        "line #{l}, column #{c}: failed rule '#{@failed_rule}'"
      end
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

      char = lines[l-1][c-1, 1]

      if @failed_rule.kind_of? Symbol
        info = self.class::Rules[@failed_rule]
        "@#{l}:#{c} failed rule '#{info.name}', got '#{char}'"
      else
        "@#{l}:#{c} failed rule '#{@failed_rule}', got '#{char}'"
      end
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

      io.puts "On line #{line_no}, column #{col_no}:"

      if @failed_rule.kind_of? Symbol
        info = self.class::Rules[@failed_rule]
        io.puts "Failed to match '#{info.rendered}' (rule '#{info.name}')"
      else
        io.puts "Failed to match rule '#{@failed_rule}'"
      end

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

    def parse(rule=nil)
      if !rule
        _root ? true : false
      else
        # This is not shared with code_generator.rb so this can be standalone
        method = rule.gsub("-","_hyphen_")
        __send__("_#{method}") ? true : false
      end
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

    def external_invoke(other, rule, *args)
      old_pos = @pos
      old_string = @string

      @pos = other.pos
      @string = other.string

      begin
        if val = __send__(rule, *args)
          other.pos = @pos
          other.result = @result
        else
          other.set_failed_rule "#{self.class}##{rule}"
        end
        val
      ensure
        @pos = old_pos
        @string = old_string
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


    require File.expand_path("../atomy.kpeg.rb", __FILE__)
    include Atomy::Format

    def create(x, *as)
      as << []
      x.send(:new, 1, *as)
    end


  def setup_foreign_grammar
    @_grammar_atomy = Atomy::Parser.new(nil)
  end

  # line = { current_line }
  def _line
    @result = begin;  current_line ; end
    _tmp = true
    set_failed_rule :_line unless _tmp
    return _tmp
  end

  # text = (< /[^\\%#{Regexp.quote(e)}]+/ > { text } | "\\" < /[%\(\)\{\}\[\]]/ > { text } | "\\" %atomy.escape:e { e })
  def _text(e)

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _text_start = self.pos
        _tmp = scan(/\A(?-mix:[^\\%#{Regexp.quote(e)}]+)/)
        if _tmp
          text = get_text(_text_start)
        end
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin;  text ; end
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
        _tmp = match_string("\\")
        unless _tmp
          self.pos = _save2
          break
        end
        _text_start = self.pos
        _tmp = scan(/\A(?-mix:[%\(\)\{\}\[\]])/)
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

      break if _tmp
      self.pos = _save

      _save3 = self.pos
      while true # sequence
        _tmp = match_string("\\")
        unless _tmp
          self.pos = _save3
          break
        end
        _tmp = @_grammar_atomy.external_invoke(self, :_escape)
        e = @result
        unless _tmp
          self.pos = _save3
          break
        end
        @result = begin;  e ; end
        _tmp = true
        unless _tmp
          self.pos = _save3
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_text unless _tmp
    return _tmp
  end

  # nested = text(e)+:c { Chunk.new(0, [], c.join) }
  def _nested(e)

    _save = self.pos
    while true # sequence
      _save1 = self.pos
      _ary = []
      _tmp = _text(e)
      if _tmp
        _ary << @result
        while true
          _tmp = _text(e)
          _ary << @result if _tmp
          break unless _tmp
        end
        _tmp = true
        @result = _ary
      else
        self.pos = _save1
      end
      c = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  Chunk.new(0, [], c.join) ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_nested unless _tmp
    return _tmp
  end

  # chunk = nested("")
  def _chunk
    _tmp = _nested("")
    set_failed_rule :_chunk unless _tmp
    return _tmp
  end

  # flagged = "%" flag*:fs segment:s { s.flags = fs; s }
  def _flagged

    _save = self.pos
    while true # sequence
      _tmp = match_string("%")
      unless _tmp
        self.pos = _save
        break
      end
      _ary = []
      while true
        _tmp = apply(:_flag)
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
      _tmp = apply(:_segment)
      s = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  s.flags = fs; s ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_flagged unless _tmp
    return _tmp
  end

  # flag = ("#" { Number.new(0, nil) } | "0" &("." /\d/ | /\d/) { ZeroPad.new(0) } | "." < /\d+/ > { Precision.new(0, text.to_i) } | < /\d+/ > { Number.new(0, text.to_i) } | < /[\.\+\*=<>,\?]/ > { Symbol.new(0, text) })
  def _flag

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = match_string("#")
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin;  Number.new(0, nil) ; end
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
        _tmp = match_string("0")
        unless _tmp
          self.pos = _save2
          break
        end
        _save3 = self.pos

        _save4 = self.pos
        while true # choice

          _save5 = self.pos
          while true # sequence
            _tmp = match_string(".")
            unless _tmp
              self.pos = _save5
              break
            end
            _tmp = scan(/\A(?-mix:\d)/)
            unless _tmp
              self.pos = _save5
            end
            break
          end # end sequence

          break if _tmp
          self.pos = _save4
          _tmp = scan(/\A(?-mix:\d)/)
          break if _tmp
          self.pos = _save4
          break
        end # end choice

        self.pos = _save3
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin;  ZeroPad.new(0) ; end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save6 = self.pos
      while true # sequence
        _tmp = match_string(".")
        unless _tmp
          self.pos = _save6
          break
        end
        _text_start = self.pos
        _tmp = scan(/\A(?-mix:\d+)/)
        if _tmp
          text = get_text(_text_start)
        end
        unless _tmp
          self.pos = _save6
          break
        end
        @result = begin;  Precision.new(0, text.to_i) ; end
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
        _text_start = self.pos
        _tmp = scan(/\A(?-mix:\d+)/)
        if _tmp
          text = get_text(_text_start)
        end
        unless _tmp
          self.pos = _save7
          break
        end
        @result = begin;  Number.new(0, text.to_i) ; end
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
        _text_start = self.pos
        _tmp = scan(/\A(?-mix:[\.\+\*=<>,\?])/)
        if _tmp
          text = get_text(_text_start)
        end
        unless _tmp
          self.pos = _save8
          break
        end
        @result = begin;  Symbol.new(0, text) ; end
        _tmp = true
        unless _tmp
          self.pos = _save8
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_flag unless _tmp
    return _tmp
  end

  # segment = ("p" "(" sub(")"):s ")" ("(" sub(")"):p ")")? { Pluralize.new(0, s, [], p) } | "l" "(" sub(")"):c ")" { create(Lowercase, c) } | "c" "(" sub(")"):c ")" { create(Capitalize, c) } | "u" "(" sub(")"):c ")" { create(Uppercase, c) } | "j" ("(" sub(")"):c ")" { c })+:cs { create(Justify, cs) } | "{" sub("}"):c "}" { create(Iterate, c) } | ("[" sub("]"):c "]" { c })+:bs ("(" sub(")"):d ")" { d })? { Conditional.new(0, Array(bs), [], d) } | "_" { create(Skip) } | "^" { create(Break) } | "%" { create(Indirection) } | "s" { create(String) } | "d" { create(Decimal) } | "x" { create(Hex) } | "o" { create(Octal) } | "b" { create(Binary) } | "r" { create(Radix) } | "f" { create(Float) } | "e" { create(Exponent) } | "g" { create(General) } | "c" { create(Character) } | "v" { create(Any) })
  def _segment

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = match_string("p")
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = match_string("(")
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = _sub(")")
        s = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = match_string(")")
        unless _tmp
          self.pos = _save1
          break
        end
        _save2 = self.pos

        _save3 = self.pos
        while true # sequence
          _tmp = match_string("(")
          unless _tmp
            self.pos = _save3
            break
          end
          _tmp = _sub(")")
          p = @result
          unless _tmp
            self.pos = _save3
            break
          end
          _tmp = match_string(")")
          unless _tmp
            self.pos = _save3
          end
          break
        end # end sequence

        unless _tmp
          _tmp = true
          self.pos = _save2
        end
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin;  Pluralize.new(0, s, [], p) ; end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save4 = self.pos
      while true # sequence
        _tmp = match_string("l")
        unless _tmp
          self.pos = _save4
          break
        end
        _tmp = match_string("(")
        unless _tmp
          self.pos = _save4
          break
        end
        _tmp = _sub(")")
        c = @result
        unless _tmp
          self.pos = _save4
          break
        end
        _tmp = match_string(")")
        unless _tmp
          self.pos = _save4
          break
        end
        @result = begin;  create(Lowercase, c) ; end
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
        _tmp = match_string("c")
        unless _tmp
          self.pos = _save5
          break
        end
        _tmp = match_string("(")
        unless _tmp
          self.pos = _save5
          break
        end
        _tmp = _sub(")")
        c = @result
        unless _tmp
          self.pos = _save5
          break
        end
        _tmp = match_string(")")
        unless _tmp
          self.pos = _save5
          break
        end
        @result = begin;  create(Capitalize, c) ; end
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
        _tmp = match_string("u")
        unless _tmp
          self.pos = _save6
          break
        end
        _tmp = match_string("(")
        unless _tmp
          self.pos = _save6
          break
        end
        _tmp = _sub(")")
        c = @result
        unless _tmp
          self.pos = _save6
          break
        end
        _tmp = match_string(")")
        unless _tmp
          self.pos = _save6
          break
        end
        @result = begin;  create(Uppercase, c) ; end
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
        _tmp = match_string("j")
        unless _tmp
          self.pos = _save7
          break
        end
        _save8 = self.pos
        _ary = []

        _save9 = self.pos
        while true # sequence
          _tmp = match_string("(")
          unless _tmp
            self.pos = _save9
            break
          end
          _tmp = _sub(")")
          c = @result
          unless _tmp
            self.pos = _save9
            break
          end
          _tmp = match_string(")")
          unless _tmp
            self.pos = _save9
            break
          end
          @result = begin;  c ; end
          _tmp = true
          unless _tmp
            self.pos = _save9
          end
          break
        end # end sequence

        if _tmp
          _ary << @result
          while true

            _save10 = self.pos
            while true # sequence
              _tmp = match_string("(")
              unless _tmp
                self.pos = _save10
                break
              end
              _tmp = _sub(")")
              c = @result
              unless _tmp
                self.pos = _save10
                break
              end
              _tmp = match_string(")")
              unless _tmp
                self.pos = _save10
                break
              end
              @result = begin;  c ; end
              _tmp = true
              unless _tmp
                self.pos = _save10
              end
              break
            end # end sequence

            _ary << @result if _tmp
            break unless _tmp
          end
          _tmp = true
          @result = _ary
        else
          self.pos = _save8
        end
        cs = @result
        unless _tmp
          self.pos = _save7
          break
        end
        @result = begin;  create(Justify, cs) ; end
        _tmp = true
        unless _tmp
          self.pos = _save7
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save11 = self.pos
      while true # sequence
        _tmp = match_string("{")
        unless _tmp
          self.pos = _save11
          break
        end
        _tmp = _sub("}")
        c = @result
        unless _tmp
          self.pos = _save11
          break
        end
        _tmp = match_string("}")
        unless _tmp
          self.pos = _save11
          break
        end
        @result = begin;  create(Iterate, c) ; end
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
        _save13 = self.pos
        _ary = []

        _save14 = self.pos
        while true # sequence
          _tmp = match_string("[")
          unless _tmp
            self.pos = _save14
            break
          end
          _tmp = _sub("]")
          c = @result
          unless _tmp
            self.pos = _save14
            break
          end
          _tmp = match_string("]")
          unless _tmp
            self.pos = _save14
            break
          end
          @result = begin;  c ; end
          _tmp = true
          unless _tmp
            self.pos = _save14
          end
          break
        end # end sequence

        if _tmp
          _ary << @result
          while true

            _save15 = self.pos
            while true # sequence
              _tmp = match_string("[")
              unless _tmp
                self.pos = _save15
                break
              end
              _tmp = _sub("]")
              c = @result
              unless _tmp
                self.pos = _save15
                break
              end
              _tmp = match_string("]")
              unless _tmp
                self.pos = _save15
                break
              end
              @result = begin;  c ; end
              _tmp = true
              unless _tmp
                self.pos = _save15
              end
              break
            end # end sequence

            _ary << @result if _tmp
            break unless _tmp
          end
          _tmp = true
          @result = _ary
        else
          self.pos = _save13
        end
        bs = @result
        unless _tmp
          self.pos = _save12
          break
        end
        _save16 = self.pos

        _save17 = self.pos
        while true # sequence
          _tmp = match_string("(")
          unless _tmp
            self.pos = _save17
            break
          end
          _tmp = _sub(")")
          d = @result
          unless _tmp
            self.pos = _save17
            break
          end
          _tmp = match_string(")")
          unless _tmp
            self.pos = _save17
            break
          end
          @result = begin;  d ; end
          _tmp = true
          unless _tmp
            self.pos = _save17
          end
          break
        end # end sequence

        unless _tmp
          _tmp = true
          self.pos = _save16
        end
        unless _tmp
          self.pos = _save12
          break
        end
        @result = begin;  Conditional.new(0, Array(bs), [], d) ; end
        _tmp = true
        unless _tmp
          self.pos = _save12
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save18 = self.pos
      while true # sequence
        _tmp = match_string("_")
        unless _tmp
          self.pos = _save18
          break
        end
        @result = begin;  create(Skip) ; end
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
        _tmp = match_string("^")
        unless _tmp
          self.pos = _save19
          break
        end
        @result = begin;  create(Break) ; end
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
        _tmp = match_string("%")
        unless _tmp
          self.pos = _save20
          break
        end
        @result = begin;  create(Indirection) ; end
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
        _tmp = match_string("s")
        unless _tmp
          self.pos = _save21
          break
        end
        @result = begin;  create(String) ; end
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
        _tmp = match_string("d")
        unless _tmp
          self.pos = _save22
          break
        end
        @result = begin;  create(Decimal) ; end
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
        _tmp = match_string("x")
        unless _tmp
          self.pos = _save23
          break
        end
        @result = begin;  create(Hex) ; end
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
        _tmp = match_string("o")
        unless _tmp
          self.pos = _save24
          break
        end
        @result = begin;  create(Octal) ; end
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
        _tmp = match_string("b")
        unless _tmp
          self.pos = _save25
          break
        end
        @result = begin;  create(Binary) ; end
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
        _tmp = match_string("r")
        unless _tmp
          self.pos = _save26
          break
        end
        @result = begin;  create(Radix) ; end
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
        _tmp = match_string("f")
        unless _tmp
          self.pos = _save27
          break
        end
        @result = begin;  create(Float) ; end
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
        _tmp = match_string("e")
        unless _tmp
          self.pos = _save28
          break
        end
        @result = begin;  create(Exponent) ; end
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
        _tmp = match_string("g")
        unless _tmp
          self.pos = _save29
          break
        end
        @result = begin;  create(General) ; end
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
        _tmp = match_string("c")
        unless _tmp
          self.pos = _save30
          break
        end
        @result = begin;  create(Character) ; end
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
        _tmp = match_string("v")
        unless _tmp
          self.pos = _save31
          break
        end
        @result = begin;  create(Any) ; end
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

    set_failed_rule :_segment unless _tmp
    return _tmp
  end

  # sub = (flagged | nested(e))*:as { Array(as) } { Formatter.new(0, Array(as)) }
  def _sub(e)

    _save = self.pos
    while true # sequence
      _ary = []
      while true

        _save2 = self.pos
        while true # choice
          _tmp = apply(:_flagged)
          break if _tmp
          self.pos = _save2
          _tmp = _nested(e)
          break if _tmp
          self.pos = _save2
          break
        end # end choice

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
      @result = begin;  Array(as) ; end
      _tmp = true
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  Formatter.new(0, Array(as)) ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_sub unless _tmp
    return _tmp
  end

  # root = sub("")
  def _root
    _tmp = _sub("")
    set_failed_rule :_root unless _tmp
    return _tmp
  end

  Rules = {}
  Rules[:_line] = rule_info("line", "{ current_line }")
  Rules[:_text] = rule_info("text", "(< /[^\\\\%\#{Regexp.quote(e)}]+/ > { text } | \"\\\\\" < /[%\\(\\)\\{\\}\\[\\]]/ > { text } | \"\\\\\" %atomy.escape:e { e })")
  Rules[:_nested] = rule_info("nested", "text(e)+:c { Chunk.new(0, [], c.join) }")
  Rules[:_chunk] = rule_info("chunk", "nested(\"\")")
  Rules[:_flagged] = rule_info("flagged", "\"%\" flag*:fs segment:s { s.flags = fs; s }")
  Rules[:_flag] = rule_info("flag", "(\"\#\" { Number.new(0, nil) } | \"0\" &(\".\" /\\d/ | /\\d/) { ZeroPad.new(0) } | \".\" < /\\d+/ > { Precision.new(0, text.to_i) } | < /\\d+/ > { Number.new(0, text.to_i) } | < /[\\.\\+\\*=<>,\\?]/ > { Symbol.new(0, text) })")
  Rules[:_segment] = rule_info("segment", "(\"p\" \"(\" sub(\")\"):s \")\" (\"(\" sub(\")\"):p \")\")? { Pluralize.new(0, s, [], p) } | \"l\" \"(\" sub(\")\"):c \")\" { create(Lowercase, c) } | \"c\" \"(\" sub(\")\"):c \")\" { create(Capitalize, c) } | \"u\" \"(\" sub(\")\"):c \")\" { create(Uppercase, c) } | \"j\" (\"(\" sub(\")\"):c \")\" { c })+:cs { create(Justify, cs) } | \"{\" sub(\"}\"):c \"}\" { create(Iterate, c) } | (\"[\" sub(\"]\"):c \"]\" { c })+:bs (\"(\" sub(\")\"):d \")\" { d })? { Conditional.new(0, Array(bs), [], d) } | \"_\" { create(Skip) } | \"^\" { create(Break) } | \"%\" { create(Indirection) } | \"s\" { create(String) } | \"d\" { create(Decimal) } | \"x\" { create(Hex) } | \"o\" { create(Octal) } | \"b\" { create(Binary) } | \"r\" { create(Radix) } | \"f\" { create(Float) } | \"e\" { create(Exponent) } | \"g\" { create(General) } | \"c\" { create(Character) } | \"v\" { create(Any) })")
  Rules[:_sub] = rule_info("sub", "(flagged | nested(e))*:as { Array(as) } { Formatter.new(0, Array(as)) }")
  Rules[:_root] = rule_info("root", "sub(\"\")")
end

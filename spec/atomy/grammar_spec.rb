require "spec_helper"

require "atomy/grammar"

include Atomy::Grammar::AST

describe Atomy::Grammar do
  let(:source) { "" }

  let(:result) do
    grammar.raise_error unless grammar.parse
    grammar.result.nodes
  end

  subject(:grammar) { Atomy::Grammar.new(source) }

  context "with an empty string" do
    it "parses as an empty tree" do
      expect(result).to eq([])
    end
  end

  context "with a shebang at the start" do
    let(:source) { "#!/usr/bin/env atomy\n" }

    it "skips the shebang line" do
      expect(result).to eq([])
    end
  end

  describe "language pragma" do
    let(:source) { "#language foo" }

    it "switches the language being parsed" do
      foolang = mock
      foolang.should_receive(:external_invoke).with(anything, :_root)

      grammar.should_receive(:set_lang).with(:foo) do
        grammar.instance_exec do
          @_grammar_lang = foolang
        end
      end

      result
    end
  end

  describe "comments" do
    subject { result.first }

    before do
      expect(result.size).to eq(1)
    end

    describe "single-line" do
      let(:source) { "-- foo\n1" }

      it { should be_a(Number) }
    end

    describe "block" do
      let(:source) { "{- foo -}\n1" }

      it { should be_a(Number) }

      context "when spanning multiple lines" do
        let(:source) { "{- \nfoo\nbar\nbaz -}\n1" }
        it { should be_a(Number) }
      end

      context "when not spaced from its contents" do
        let(:source) { "{-foo-}\n1" }
        it { should be_a(Number) }
      end

      context "when nested" do
        let(:source) { "{- foo {- bar -} baz -}\n1" }
        it { should be_a(Number) }
      end

      context "when in the middle of a node" do
        let(:source) { "fizz {- foo {- bar -} baz -} buzz" }
        it { should be_a(Compose) }
      end
    end
  end

  describe "node location tracking" do
    NODE_SAMPLES.each do |node, sample|
      describe node do
        it "has line information" do
          raise "No sample for #{node}" unless sample

          lines = rand(5)
          node = ast("\n" * lines + sample)
          expect(node.line).to eq(lines + 1)
        end
      end
    end
  end

  describe "parsing particular nodes" do
    before do
      expect(result.first).to be_a(node)
      expect(result.size).to eq(1)
    end

    subject { result.first }

    describe "numbers" do
      let(:node) { Number }

      let(:source) { "123" }
      its(:value) { should == 123 }

      context "with a positive sign" do
        let(:source) { "+123" }
        its(:value) { should == 123 }
      end

      context "with a negative sign" do
        let(:source) { "-123" }
        its(:value) { should == -123 }
      end

      context "with hexadecimal notation" do
        let(:source) { "0xdeadbeef" }
        its(:value) { should == 3735928559 }

        context "and a capital X" do
          let(:source) { "0Xdeadbeef" }
          its(:value) { should == 3735928559 }
        end

        context "and a positive sign" do
          let(:source) { "+0xdeadbeef" }
          its(:value) { should == 3735928559 }
        end

        context "and a negative sign" do
          let(:source) { "-0xdeadbeef" }
          its(:value) { should == -3735928559 }
        end
      end

      context "with octal notation" do
        let(:source) { "0o644" }
        its(:value) { should == 420 }

        context "and a capital O" do
          let(:source) { "0O644" }
          its(:value) { should == 420 }
        end

        context "and a positive sign" do
          let(:source) { "+0o644" }
          its(:value) { should == 420 }
        end

        context "and a negative sign" do
          let(:source) { "-0o644" }
          its(:value) { should == -420 }
        end
      end
    end

    describe "floating point literals" do
      let(:node) { Literal}

      let(:source) { "12.345" }
      its(:value) { should == 12.345 }

      context "with a positive sign" do
        let(:source) { "+12.345" }
        its(:value) { should == 12.345 }
      end

      context "with a negative sign" do
        let(:source) { "-12.345" }
        its(:value) { should == -12.345 }
      end

      context "with scientific notation" do
        let(:source) { "1e3" }
        its(:value) { should == 1000.0 }

        context "and a capital E" do
          let(:source) { "1E3" }
          its(:value) { should == 1000.0 }
        end

        context "and a positive exponent" do
          let(:source) { "1e+3" }
          its(:value) { should == 1000.0 }
        end

        context "and a negative exponent" do
          let(:source) { "1e-3" }
          its(:value) { should == 0.001 }
        end

        context "and a positive sign" do
          let(:source) { "+1e3" }
          its(:value) { should == 1000.0 }

          context "and a positive exponent" do
            let(:source) { "+1e+3" }
            its(:value) { should == 1000.0 }
          end

          context "and a negative exponent" do
            let(:source) { "+1e-3" }
            its(:value) { should == 0.001 }
          end
        end

        context "and a negative sign" do
          let(:source) { "-1e3" }
          its(:value) { should == -1000.0 }

          context "and a positive exponent" do
            let(:source) { "-1e+3" }
            its(:value) { should == -1000.0 }
          end

          context "and a negative exponent" do
            let(:source) { "-1e-3" }
            its(:value) { should == -0.001 }
          end
        end

        context "and a decimal" do
          let(:source) { "1.2e3" }
          its(:value) { should == 1200.0 }

          context "and a capital E" do
            let(:source) { "1.2E3" }
            its(:value) { should == 1200.0 }
          end

          context "and a positive exponent" do
            let(:source) { "1.2e+3" }
            its(:value) { should == 1200.0 }
          end

          context "and a negative exponent" do
            let(:source) { "1.2e-3" }
            its(:value) { should == 0.0012 }
          end

          context "and a positive sign" do
            let(:source) { "+1.2e3" }
            its(:value) { should == 1200.0 }

            context "and a positive exponent" do
              let(:source) { "+1.2e+3" }
              its(:value) { should == 1200.0 }
            end

            context "and a negative exponent" do
              let(:source) { "+1.2e-3" }
              its(:value) { should == 0.0012 }
            end
          end

          context "and a negative sign" do
            let(:source) { "-1.2e3" }
            its(:value) { should == -1200.0 }

            context "and a positive exponent" do
              let(:source) { "-1.2e+3" }
              its(:value) { should == -1200.0 }
            end

            context "and a negative exponent" do
              let(:source) { "-1.2e-3" }
              its(:value) { should == -0.0012 }
            end
          end
        end
      end
    end

    describe "strings" do
      let(:node) { StringLiteral }

      let(:source) { '"foo"' }
      its(:value) { should == "foo" }
      its(:raw) { should == "foo" }

      context "with an escaped double quote" do
        let(:source) { '"foo \"bar\""' }
        its(:value) { should == 'foo "bar"' }
        its(:raw) { should == 'foo "bar"' }
      end

      ESCAPES = {
        "n" => "\n", "s" => " ", "r" => "\r", "t" => "\t", "v" => "\v",
        "f" => "\f", "b" => "\b", "a" => "\a", "e" => "\e", "\\" => "\\",
        "BS" => "\b", "HT" => "\t", "LF" => "\n", "VT" => "\v", "FF" => "\f",
        "CR" => "\r", "SO" => "\016", "SI" => "\017", "EM" => "\031",
        "FS" => "\034", "GS" => "\035", "RS" => "\036", "US" => "\037",
        "SP" => " ", "NUL" => "\000", "SOH" => "\001", "STX" => "\002",
        "ETX" => "\003", "EOT" => "\004", "ENQ" => "\005", "ACK" => "\006",
        "BEL" => "\a", "DLE" => "\020", "DC1" => "\021", "DC2" => "\022",
        "DC3" => "\023", "DC4" => "\024", "NAK" => "\025", "SYN" => "\026",
        "ETB" => "\027", "CAN" => "\030", "SUB" => "\032", "ESC" => "\e",
        "DEL" => "\177"
      }

      ESCAPES.each do |esc, val|
        context "with a \\#{esc}" do
          let(:source) { "\"foo\\#{esc}bar\"" }
          its(:value) { should == "foo#{val}bar" }
          its(:raw) { should == "foo\\#{esc}bar" }
        end
      end

      describe "decimal escapes" do
        let(:source) { '"foo \123"' }
        its(:value) { should == "foo {" }
        its(:raw) { should == 'foo \123' }
      end

      describe "hexadecimal escapes" do
        let(:source) { '"foo \xabcdefg"' }
        its(:value) { should == "foo \u{ABCDE}fg" }
        its(:raw) { should == 'foo \xabcdefg' }

        context "with a capital X" do
          let(:source) { '"foo \Xabcdefg"' }
          its(:value) { should == "foo \u{ABCDE}fg" }
          its(:raw) { should == 'foo \Xabcdefg' }
        end
      end

      describe "octal escapes" do
        let(:source) { '"foo \o12345678"' }
        its(:value) { should == "foo \xf9\x88\xb4\x95\xa78" }
        its(:raw) { should == 'foo \o12345678' }

        context "with a capital O" do
          let(:source) { '"foo \O12345678"' }
          its(:value) { should == "foo \xf9\x88\xb4\x95\xa78" }
          its(:raw) { should == 'foo \O12345678' }
        end
      end

      describe "unicode escapes" do
        let(:source) { '"foo \u12AB"' }
        its(:value) { should == "foo \u{12AB}" }
        its(:raw) { should == 'foo \u12AB' }

        context "with a capital U" do
          let(:source) { '"foo \U12AB"' }
          its(:value) { should == "foo \u{12AB}" }
          its(:raw) { should == 'foo \U12AB' }
        end
      end
    end

    describe "constants" do
      let(:node) { Constant }

      let(:source) { "Foo" }
      its(:text) { should == :Foo }

      context "with a single letter" do
        let(:source) { "X" }
        its(:text) { should == :X }
      end

      context "with underscores and digits" do
        let(:source) { "Abc_12Three" }
        its(:text) { :Abc_12Three }
      end
    end

    describe "words" do
      let(:node) { Word }

      let(:source) { "foo" }
      its(:text) { should == :foo }

      context "with a single letter" do
        let(:source) { "x" }
        its(:text) { should == :x }
      end

      context "with a single underscore" do
        let(:source) { "_" }
        its(:text) { should == :_ }
      end

      context "with underscores and digits and hyphens" do
        let(:source) { "_foo-bar-123" }
        its(:text) { :"_foo-bar-123" }
      end
    end

    def self.it_contains_nodes(open, close, attribute = :nodes)
      let(:source) { "#{open} #{close}" }
      its(attribute) { should == [] }

      context "with a single node" do
        let(:source) { "#{open} x #{close}" }

        it "has it under ##{attribute}" do
          expect(subject.send(attribute).first).to be_a(Word)
          expect(subject.send(attribute).size).to eq(1)
        end
      end

      context "with multiple nodes" do
        let(:source) { "#{open} x, y #{close}" }

        it "has them both under ##{attribute}" do
          expect(subject.send(attribute).size).to eq(2)

          expect(subject.send(attribute)[0]).to be_a(Word)
          expect(subject.send(attribute)[0].text).to eq(:x)

          expect(subject.send(attribute)[1]).to be_a(Word)
          expect(subject.send(attribute)[1].text).to eq(:y)
        end
      end

      context "with multiple nodes spanning multiple lines" do
        let(:source) { "#{open}\n  x\n  y\n#{close}" }

        it "has them both under ##{attribute}" do
          expect(subject.send(attribute).size).to eq(2)

          expect(subject.send(attribute)[0]).to be_a(Word)
          expect(subject.send(attribute)[0].text).to eq(:x)

          expect(subject.send(attribute)[1]).to be_a(Word)
          expect(subject.send(attribute)[1].text).to eq(:y)
        end
      end
    end

    describe "blocks" do
      let(:node) { Block }

      it_contains_nodes("{", "}")

      context "with the colon syntax" do
        it_contains_nodes(":", ";")

        context "without a closing delimiter" do
          it_contains_nodes(":", "")
        end
      end
    end

    describe "lists" do
      let(:node) { List }

      it_contains_nodes("[", "]")
    end

    describe "prefixes" do
      let(:node) { Prefix }

      let(:source) { "!foo" }
      its(:operator) { should == :"!" }
      its(:node) { should be_a(Word) }

      context "when chaining prefixes" do
        let(:source) { "?!foo" }
        its(:operator) { should == :"?" }
        its(:node) { should be_a(Prefix) }
      end

      context "with a postfix node" do
        let(:source) { "!foo?" }
        its(:operator) { should == :"!" }
        its(:node) { should be_a(Postfix) }
      end
    end

    def self.it_prefixes_with(op)
      let(:source) { "#{op}foo" }
      its(:node) { should be_a(Word) }

      context "when chaining" do
        let(:source) { "#{op}#{op}foo" }
        its(:node) { should be_a(node) }
      end

      context "with a postfix node" do
        let(:source) { "#{op}foo?" }
        its(:node) { should be_a(Postfix) }
      end
    end

    describe "quotes" do
      let(:node) { Quote }

      it_prefixes_with "'"
    end

    describe "quasiquotes" do
      let(:node) { QuasiQuote }

      it_prefixes_with "`"
    end

    describe "unquotes" do
      let(:node) { Unquote }

      it_prefixes_with "~"
    end

    describe "postfixes" do
      let(:node) { Postfix }

      let(:source) { "foo!" }
      its(:operator) { should == :"!" }
      its(:node) { should be_a(Word) }

      context "when chaining postfixes" do
        let(:source) { "foo!?" }
        its(:operator) { should == :"?" }
        its(:node) { should be_a(Postfix) }
      end
    end

    describe "applies" do
      let(:node) { Apply }

      let(:source) { "foo()" }
      its(:node) { should be_a(Word) }
      its(:arguments) { should be_empty }

      context "with arguments given" do
        it_contains_nodes("foo(", ")", :arguments)
      end

      context "with a grouped name" do
        let(:source) { "(foo)()" }

        its(:node) { should be_a(Word) }
        its(:arguments) { should be_empty }

        context "with arguments given" do
          it_contains_nodes("(foo)(", ")", :arguments)
        end
      end
    end

    describe "composes" do
      let(:node) { Compose }

      let(:source) { "1 a" }
      its(:left) { should be_a(Number) }
      its(:right) { should be_a(Word) }

      context "with grouping" do
        let(:source) { "(1) (a)" }
        its(:left) { should be_a(Number) }
        its(:right) { should be_a(Word) }
      end

      context "without spacing" do
        let(:source) { "foo: 123" }
        its(:left) { should be_a(Word) }
        its(:right) { should be_a(Block) }

        context "and something that looks like an infix operation" do
          let(:source) { "1/2" }
          its(:left) { should be_a(Postfix) }
          its(:right) { should be_a(Number) }
        end
      end

      describe "line continuation" do
        let(:source) { "1\n a" }
        its(:left) { should be_a(Number) }
        its(:right) { should be_a(Word) }

        context "with a long chain and a small continuation" do
          let(:source) { "1 a b c d\n 1.2" }
          its(:left) { should be_a(Compose) }
          its(:right) { should be_a(Literal) }
        end

        context "with a small chain and a long continuation" do
          let(:source) { "1 a\n b c d 1.2" }
          its(:left) { should be_a(Compose) }
          its(:right) { should be_a(Literal) }
        end

        context "with a continuation spanning three lines" do
          let(:source) { "1 a\n b c\n d 1.2" }
          its(:left) { should be_a(Compose) }
          its(:right) { should be_a(Literal) }
        end
      end

      describe "chaining" do
        let(:source) { "1 a b" }
        its(:left) { should be_a(Compose) }
        its(:right) { should be_a(Word) }
      end
    end

    describe "infixes" do
      let(:node) { Infix }

      let(:source) { "1 + a" }
      its(:left) { should be_a(Number) }
      its(:right) { should be_a(Word) }
      its(:operator) { should == :+ }

      context "with an implicit left side" do
        let(:source) { "+ 2" }
        its(:left) { should be_nil }
        its(:right) { should be_a(Number) }
        its(:operator) { should == :+ }
      end

      context "with an arbitrarily long operator" do
        let(:source) { '1 !@#$%^&*-=+\|/.<>? a' }
        its(:left) { should be_a(Number) }
        its(:right) { should be_a(Word) }
        its(:operator) { should == :"!@\#$%^&*-=+\\|/.<>?" }
      end

      context "with a grouped expression on the left" do
        let(:source) { "(2 * 2) + a" }
        its(:left) { should be_a(Infix) }
        its(:right) { should be_a(Word) }
        its(:operator) { should == :+ }
      end

      context "with a grouped expression on the left" do
        let(:source) { "a + (2 * 2)" }
        its(:left) { should be_a(Word) }
        its(:right) { should be_a(Infix) }
        its(:operator) { should == :+ }
      end

      context "with a compose on the left" do
        let(:source) { "1 a + a" }
        its(:left) { should be_a(Compose) }
        its(:right) { should be_a(Word) }
        its(:operator) { should == :+ }
      end

      context "with a compose on the right" do
        let(:source) { "1 + 1 a" }
        its(:left) { should be_a(Number) }
        its(:right) { should be_a(Compose) }
        its(:operator) { should == :+ }
      end

      context "with a prefix on the right" do
        let(:source) { "1 + !a" }
        its(:left) { should be_a(Number) }
        its(:right) { should be_a(Prefix) }
        its(:operator) { should == :+ }
      end

      context "with a prefix on the left" do
        let(:source) { "!a + 1" }
        its(:left) { should be_a(Prefix) }
        its(:right) { should be_a(Number) }
        its(:operator) { should == :+ }
      end

      context "with a postfix on the right" do
        let(:source) { "1 + a!" }
        its(:left) { should be_a(Number) }
        its(:right) { should be_a(Postfix) }
        its(:operator) { should == :+ }
      end

      context "with a postfix on the left" do
        let(:source) { "a! + 1" }
        its(:left) { should be_a(Postfix) }
        its(:right) { should be_a(Number) }
        its(:operator) { should == :+ }
      end

      describe "line continuation" do
        let(:source) { "1\n + a" }
        its(:left) { should be_a(Number) }
        its(:right) { should be_a(Word) }
        its(:operator) { should == :+ }

        context "when continuing after the operator" do
          let(:source) { "1 +\n a" }
          its(:left) { should be_a(Number) }
          its(:right) { should be_a(Word) }
          its(:operator) { should == :+ }
        end

        context "with an implicit left side" do
          let(:source) { "+\n 2" }
          its(:left) { should be_nil }
          its(:right) { should be_a(Number) }
          its(:operator) { should == :+ }
        end
      end
    end
  end
end

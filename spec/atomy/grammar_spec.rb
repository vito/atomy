require "spec_helper"

require "atomy/grammar"


describe Atomy::Grammar do
  let(:source) { "" }

  let(:result) do
    grammar.raise_error unless grammar.parse
    grammar.result
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

  describe Atomy::Grammar::AST::Number do
    let(:source) { "123" }

    subject { result[0] }

    before do
      expect(result.size).to eq(1)
      expect(result[0]).to be_a(Atomy::Grammar::AST::Number)
    end

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

  describe Atomy::Grammar::AST::Float do
    let(:source) { "12.345" }

    subject { result[0] }

    before do
      expect(result.size).to eq(1)
      expect(result[0]).to be_a(Atomy::Grammar::AST::Float)
    end

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

  describe Atomy::Grammar::AST::StringLiteral do
    let(:source) { '"foo"' }

    subject { result[0] }

    before do
      expect(result.size).to eq(1)
      expect(result[0]).to be_a(Atomy::Grammar::AST::StringLiteral)
    end

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
end

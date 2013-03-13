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
end

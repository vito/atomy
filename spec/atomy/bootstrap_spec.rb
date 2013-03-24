require "spec_helper"

require "atomy/bootstrap"

describe Atomy::Bootstrap do
  subject do
    Atomy::Module.new do
      use Atomy::Bootstrap
    end
  end

  describe "#expand" do
    context "with an Apply node" do
      context "with word names" do
        let(:node) { ast("foo(1)") }

        it "expands them into Sends" do
          expanded = subject.expand(node)
          expect(expanded).to be_a(Atomy::Code::Send)
        end
      end
    end

    context "with a StringLiteral node" do
      let(:node) { ast('"foo"') }

      it "expands it into StringLiteral code" do
        expanded = subject.expand(node)
        expect(expanded).to be_a(Atomy::Code::StringLiteral)
      end
    end

    context "with a Sequence node" do
      let(:node) { Atomy::Grammar::AST::Sequence.new([ast("foo")]) }

      it "expands it into Sequence code" do
        expanded = subject.expand(node)
        expect(expanded).to be_a(Atomy::Code::Sequence)
      end
    end

    context "with a Word node" do
      let(:node) { ast("abc") }

      it "expands it into Variable code" do
        expanded = subject.expand(node)
        expect(expanded).to be_a(Atomy::Code::Variable)
      end

      context "when the text is 'self'" do
        let(:node) { ast("self") }

        it "expands it into Self code" do
          expanded = subject.expand(node)
          expect(expanded).to be_a(Atomy::Code::Self)
        end
      end
    end

    context "with a Number node" do
      let(:node) { ast("1") }

      it "expands into Integer code" do
        expanded = subject.expand(node)
        expect(expanded).to be_a(Atomy::Code::Integer)
      end
    end

    context "with an Infix node" do
      context "when the operator is '='" do
        let(:node) { ast("a = 1") }

        it "expands it into Assign code" do
          expanded = subject.expand(node)
          expect(expanded).to be_a(Atomy::Code::Assign)
        end
      end
    end
  end

  describe "#pattern" do
    context "with a Word node" do
      let(:node) { ast("a") }

      it "expands into a Wildcard pattern" do
        pattern = subject.pattern(node)
        expect(pattern).to be_a(Atomy::Pattern::Wildcard)
      end

      context "when the text is _" do
        let(:node) { ast("_") }

        it "has no name" do
          pattern = subject.pattern(node)
          expect(pattern.name).to_not be
        end
      end

      context "when the text is NOT _" do
        it "has the word's text as its name" do
          pattern = subject.pattern(node)
          expect(pattern.name).to eq(:a)
        end
      end
    end

    context "with a Number node" do
      let(:node) { ast("1") }

      it "expands into an Equality pattern" do
        pattern = subject.pattern(node)
        expect(pattern).to be_a(Atomy::Pattern::Equality)
      end
    end
  end
end

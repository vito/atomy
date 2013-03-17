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

      context "with non-word names" do
        let(:node) { ast("Foo(1)") }

        it "returns the original node" do
          expanded = subject.expand(node)
          expect(expanded).to be(node)
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
  end
end

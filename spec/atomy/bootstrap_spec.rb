require "spec_helper"

require "atomy/bootstrap"

describe Atomy::Bootstrap do
  subject do
    Atomy::Module.new do
      include Atomy::Bootstrap
      extend Atomy::Bootstrap
    end
  end

  describe "#expand" do
    context "with Apply nodes" do
      context "with word names" do
        let(:node) { ast("foo(1)") }

        it "expands them into Sends" do
          expanded = subject.expand(node)
          expect(expanded).to be_a(Atomy::Send)
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
        expect(expanded).to be_a(Atomy::StringLiteral)
      end
    end
  end
end

require "spec_helper"

require "atomy/bootstrap"
require "atomy/node/equality"

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

    context "with a List node" do
      let(:node) { Atomy::Grammar::AST::List.new([ast("foo")]) }

      it "expands it into List code" do
        expanded = subject.expand(node)
        expect(expanded).to be_a(Atomy::Code::List)
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

    context "with a Constant node" do
      let(:node) { ast("Abc") }

      it "expands it into Constant code" do
        expanded = subject.expand(node)
        expect(expanded).to be_a(Atomy::Code::Constant)
      end
    end

    context "with a Number node" do
      let(:node) { ast("1") }

      it "expands into Integer code" do
        expanded = subject.expand(node)
        expect(expanded).to be_a(Atomy::Code::Integer)
      end
    end

    context "with a Quote node" do
      let(:node) { ast("'1") }

      it "expands into Quote code" do
        expanded = subject.expand(node)
        expect(expanded).to be_a(Atomy::Code::Quote)
      end
    end

    context "with a QuasiQuote node" do
      let(:node) { ast("`1") }

      it "expands into QuasiQuote code" do
        expanded = subject.expand(node)
        expect(expanded).to be_a(Atomy::Code::QuasiQuote)
      end
    end

    context "with an Infix node" do
      let(:node) { ast("a + 1") }

      it "expands it into Send code" do
        expanded = subject.expand(node)
        expect(expanded).to be_a(Atomy::Code::Send)
      end

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

    context "with a Constant node" do
      let(:node) { ast("Abc") }

      it "expands it into a KindOf pattern" do
        expanded = subject.pattern(node)
        expect(expanded).to be_a(Atomy::Pattern::KindOf)
      end
    end

    context "with a Number node" do
      let(:node) { ast("1") }

      it "expands into an Equality pattern" do
        pattern = subject.pattern(node)
        expect(pattern).to be_a(Atomy::Pattern::Equality)
      end
    end

    context "with a Quote node" do
      let(:node) { ast("'a") }

      it "expands into an Equality pattern" do
        pattern = subject.pattern(node)
        expect(pattern).to be_a(Atomy::Pattern::Equality)
      end
    end

    context "with a Prefix node" do
      context "when the operator is *" do
        let(:node) { ast("*a") }

        it "expands into a Splat pattern" do
          pattern = subject.pattern(node)
          expect(pattern).to be_a(Atomy::Pattern::Splat)
        end
      end
    end

    context "with an Infix node" do
      context "when the operator is '&'" do
        let(:node) { ast("a & 1") }

        it "expands it into an And pattern" do
          pattern = subject.pattern(node)
          expect(pattern).to be_a(Atomy::Pattern::And)
        end
      end
    end
  end

  describe "#define_macro" do
    it "returns the CompiledCode of the method" do
      code = subject.module_eval { define_macro(ast("'foo"), ast("42")) }
      expect(code).to be_a(Rubinius::CompiledCode)
      expect(code.name).to eq(:expand)
    end

    it "defines #expand on the current scope's for_method_definition" do
      subject.module_exec do
        define_macro(ast("'foo"), ast("'42"))
      end

      expect(subject.expand(ast("foo"))).to eq(ast("42"))
    end

    it "has the caller's variable scope visible" do
      a = 1

      subject.module_exec do
        define_macro(ast("'foo"), ast("eval(\"a\")"))
      end

      expect(subject.expand(ast("foo"))).to eq(1)
    end

    it "has the caller's constant scope" do
      A = 1

      subject.module_exec do
        define_macro(ast("'foo"), ast("eval(\"A\")"))
      end

      expect(subject.expand(ast("foo"))).to eq(1)
    end

    it "adds Atomy::Grammar::AST to its constant scope" do
      subject.module_exec do
        define_macro(ast("Word"), ast("Word"))
      end

      expect(subject.expand(ast("foo"))).to eq(Atomy::Grammar::AST::Word)
    end
  end

  describe "#quasiquote" do
    it "constructs a QuasiQuote node" do
      expect(subject.quasiquote(ast("foo"))).to eq(ast("`foo"))
    end
  end

  describe "#sequence" do
    it "constructs a Sequence node" do
      seq = subject.sequence([ast("foo"), ast("bar")])
      expect(seq).to be_a(Atomy::Grammar::AST::Sequence)
      expect(seq.nodes).to eq([ast("foo"), ast("bar")])
    end
  end
end

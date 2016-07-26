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
    end
  end

  describe "#pattern" do
    context "with a Word node" do
      context "when the text is _" do
        let(:node) { ast("_") }

        it "expands into a Wildcard pattern" do
          pattern = subject.evaluate(subject.pattern(node))
          expect(pattern).to be_a(Atomy::Pattern::Wildcard)
        end
      end

      context "with text other than _" do
        let(:node) { ast("a") }

        it "expands into a Wildcard pattern" do
          pattern = subject.evaluate(subject.pattern(node))
          expect(pattern).to be_a(Atomy::Pattern::Wildcard)
        end
      end
    end

    context "with a Constant node" do
      let(:node) { ast("Integer") }

      it "expands it into a KindOf pattern" do
        expanded = subject.evaluate(subject.pattern(node))
        expect(expanded).to be_a(Atomy::Pattern::KindOf)
        expect(expanded.klass).to eq(Integer)
      end
    end

    context "with a Number node" do
      let(:node) { ast("1") }

      it "expands into an Equality pattern" do
        pattern = subject.evaluate(subject.pattern(node))
        expect(pattern).to be_a(Atomy::Pattern::Equality)
        expect(pattern.value).to eq(1)
      end
    end

    context "with a Quote node" do
      let(:node) { ast("'a") }

      it "expands into an Equality pattern" do
        pattern = subject.evaluate(subject.pattern(node))
        expect(pattern).to be_a(Atomy::Pattern::Equality)
        expect(pattern.value).to eq(ast("a"))
      end
    end

    context "with a QuasiQuote node" do
      let(:node) { ast("`a") }

      it "expands into a QuasiQuote pattern" do
        pattern = subject.evaluate(subject.pattern(node))
        expect(pattern).to be_a(Atomy::Pattern::QuasiQuote)
        expect(pattern.node).to eq(ast("a"))
      end

      context "when the pattern contains unquoted patterns" do
        let(:node) { ast("`(1 + ~a)") }

        it "correctly embeds pattern code" do
          pattern = subject.evaluate(subject.pattern(node))
          expect(pattern).to be_a(Atomy::Pattern::QuasiQuote)
          expect(pattern.node).to be_a(Atomy::Grammar::AST::Infix)
          expect(pattern.node.left).to eq(ast("1"))
          expect(pattern.node.right).to be_a(Atomy::Pattern::Wildcard)
        end

        context "at varying levels" do
          let(:node) { ast("`([~a, b] + `(2 + ~'~b))") }

          it "correctly embeds pattern code" do
            pattern = subject.evaluate(subject.pattern(node))
            expect(pattern).to be_a(Atomy::Pattern::QuasiQuote)
            expect(pattern.node).to be_a(Atomy::Grammar::AST::Infix)
            expect(pattern.node.left).to be_a(Atomy::Grammar::AST::List)
            expect(pattern.node.left.nodes[0]).to be_a(Atomy::Pattern::Wildcard)
            expect(pattern.node.left.nodes[1]).to eq(ast("b"))
            expect(pattern.node.right).to be_a(Atomy::Grammar::AST::QuasiQuote)
            expect(pattern.node.right.node).to be_a(Atomy::Grammar::AST::Infix)
            expect(pattern.node.right.node.operator).to eq(:+)
            expect(pattern.node.right.node.left).to eq(ast("2"))
            expect(pattern.node.right.node.right).to be_a(Atomy::Grammar::AST::Unquote)
            expect(pattern.node.right.node.right.node).to be_a(Atomy::Grammar::AST::Quote)
            expect(pattern.node.right.node.right.node.node).to be_a(Atomy::Pattern::Wildcard)
          end
        end
      end
    end

    context "with a Prefix node" do
      context "when the operator is *" do
        let(:node) { ast("*_") }

        it "expands into a Splat pattern" do
          pattern = subject.evaluate(subject.pattern(node))
          expect(pattern).to be_a(Atomy::Pattern::Splat)
          expect(pattern.pattern).to be_a(Atomy::Pattern::Wildcard)
        end
      end
    end

    context "with an Infix node" do
      context "when the operator is '&'" do
        let(:node) { ast("a & b") }

        it "expands it into an And pattern" do
          pattern = subject.evaluate(subject.pattern(node))
          expect(pattern).to be_a(Atomy::Pattern::And)
          expect(pattern.a).to be_a(Atomy::Pattern::Wildcard)
          expect(pattern.b).to be_a(Atomy::Pattern::Wildcard)
        end
      end
    end
  end

  describe "#macro_definer" do
    it "returns the CompiledCode of the method" do
      code = subject.evaluate(subject.macro_definer(ast("'foo"), ast("42")))
      expect(code).to be_a(Rubinius::CompiledCode)
      expect(code.name).to eq(:expand)
    end

    it "defines #expand on the current scope's for_method_definition" do
      subject.evaluate(subject.macro_definer(ast("'foo"), ast("'42")), subject.compile_context)
      expect(subject.expand(ast("foo"))).to eq(ast("42"))
    end

    it "adds Atomy::Grammar::AST to its constant scope" do
      subject.evaluate(subject.macro_definer(ast("Word"), ast("Word")), subject.compile_context)
      expect(subject.expand(ast("foo"))).to eq(Atomy::Grammar::AST::Word)
    end
  end

  describe "#make_quasiquote" do
    it "constructs QuasiQuote code" do
      made = subject.make_quasiquote(ast("foo"))
      expect(made).to be_a(Atomy::Grammar::AST::QuasiQuote)
      expect(made.node).to eq(ast("foo"))
    end
  end

  describe "#make_sequence" do
    it "constructs a Sequence node" do
      seq = subject.make_sequence([ast("foo"), ast("bar")])
      expect(seq).to be_a(Atomy::Grammar::AST::Sequence)
      expect(seq.nodes).to eq([ast("foo"), ast("bar")])
    end
  end

  describe "#make_constant" do
    it "constructs Constant code" do
      made = subject.make_constant(:Foo, ast("Bar"))
      expect(made).to be_a(Atomy::Code::Constant)
      expect(made.name).to eq(:Foo)
      expect(made.parent).to eq(ast("Bar"))
    end
  end

  describe "#make_send" do
    it "constructs a Send node" do
      made = subject.make_send(ast("foo"), ast("bar"), [ast("baz")])
      expect(made).to be_a(Atomy::Code::Send)
      expect(made.receiver).to eq(ast("foo"))
      expect(made.message).to eq(:bar)
      expect(made.arguments).to eq([ast("baz")])
    end
  end
end

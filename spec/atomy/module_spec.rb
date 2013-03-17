require "spec_helper"

require "atomy/module"

describe Atomy::Module do
  class SelfCode
    def bytecode(gen, mod)
      gen.push_self
    end
  end

  class SendCode
    def initialize(receiver, message, arguments = [])
      @receiver = receiver
      @message = message
      @arguments = arguments
    end

    def bytecode(gen, mod)
      if @receiver
        mod.compile(gen, @receiver)
      else
        gen.allow_private
        gen.push_self
      end

      @arguments.each do |arg|
        mod.compile(gen, arg)
      end

      gen.send(@message, @arguments.size)
    end
  end

  class IntegerCode
    def initialize(value)
      @value = value
    end

    def bytecode(gen, mod)
      gen.push_int(@value)
    end
  end

  class LiteralCode
    def initialize(value)
      @value = value
    end

    def bytecode(gen, mod)
      gen.push_literal(@value)
    end
  end

  subject do
    described_class.new do
      def expand(node)
        case node
        when Atomy::Grammar::AST::Word
          if node.text == :self
            return SelfCode.new
          end
        when Atomy::Grammar::AST::Apply
          if node.node.is_a?(Atomy::Grammar::AST::Word)
            return SendCode.new(nil, node.node.text, node.arguments)
          end
        when Atomy::Grammar::AST::Prefix
          if node.node.is_a?(Atomy::Grammar::AST::Word)
            return LiteralCode.new(node.node.text)
          end
        end

        node
      end
    end
  end

  describe "#initialize" do
    it "makes methods available on the module itself" do
      mod = Atomy::Module.new { def foo; 1; end }
      expect(mod.foo).to eq(1)
    end
  end

  describe "#file" do
    it "can be set" do
      mod = Atomy::Module.new { def foo; 1; end }
      mod.file = :"foo/bar"
    end

    it "can be read" do
      mod = Atomy::Module.new { def foo; 1; end }
      mod.file = :"foo/bar"
      expect(mod.file).to eq(:"foo/bar")
    end
  end

  describe "#use" do
    it "extends the module with the functionality of another" do
      mod = Atomy::Module.new { def foo; 1; end }

      mod2 = Atomy::Module.new do
        use mod

        def bar
          foo + 1
        end
      end

      expect(mod2.bar).to eq(2)
    end

    describe "deeper #use" do
      it "transfers the usage through to other modules" do
        mod = Atomy::Module.new do
          def foo
            1
          end
        end

        mod2 = Atomy::Module.new do
          use mod

          def bar
            foo + 1
          end
        end

        mod3 = Atomy::Module.new do
          use mod2

          def baz
            bar + 1
          end
        end

        expect(mod3.baz).to eq(3)
      end
    end
  end

  describe "#expand" do
    context "when an expansion rule matched" do
      it "returns the expanded node" do
        expect(subject.expand(ast("self"))).to be_a(SelfCode)
      end
    end

    context "when NO expansion rule matched" do
      it "returns the original node" do
        node = ast("foo")
        expect(subject.expand(node)).to eq(node)
      end
    end
  end

  describe "#evaluate" do
    it "compiles the given expression using the module" do
      expect(subject.evaluate(ast(".foo"))).to eq(:foo)
    end

    it "executes the compiled code" do
      value = catch(:foo) do
        expect(subject.evaluate(ast("throw(.foo, .called)"))).to eq(self)
        :not_called
      end

      expect(value).to eq(:called)
    end

    it "executes with the 'self' of the caller" do
      expect(subject.evaluate(ast("self"))).to eq(self)
    end
  end

  describe "#compile" do
    let(:apply) { ast("foo(1)") }
    let(:generator) { mock }
    let(:expansion) { mock }

    it "expands the node and compiles the expansion" do
      # TODO: less stubby

      generator.should_receive(:set_line)

      subject.should_receive(:expand).with(apply) do
        expansion
      end

      expansion.should_receive(:bytecode).with(generator, subject)

      subject.compile(generator, apply)
    end
  end
end

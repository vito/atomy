require "spec_helper"

require "atomy/node/equality"
require "atomy/node/meta"

describe Atomy::Grammar::AST::Node do
  describe ".basename" do
    it "returns the node class's unqualified name" do
      expect(Atomy::Grammar::AST::QuasiQuote.basename).to eq(:QuasiQuote)
    end
  end

  describe "#each_child" do
    expectations = {
      ast("1") => [],
      ast("1.0") => [],
      ast("'1") => [[:node, ast("1")]],
      ast("`1") => [[:node, ast("1")]],
      ast("~1") => [[:node, ast("1")]],
      ast("A") => [],
      ast("a") => [],
      ast("!a") => [[:node, ast("a")]],
      ast("a!") => [[:node, ast("a")]],
      ast("a + b") => [[:left, ast("a")], [:right, ast("b")]],
      ast("{ a }") => [[:nodes, [ast("a")]]],
      ast("[a]") => [[:nodes, [ast("a")]]],
      ast("a b") => [[:left, ast("a")], [:right, ast("b")]],
      ast("a(b)") => [[:node, ast("a")], [:arguments, [ast("b")]]],
      ast('"foo"') => []
    }

    expectations.each do |node, expected|
      context "with a #{node.class.basename}" do
        it "yields the proper nodes" do
          actual = []

          node.each_child do |name, child|
            actual << [name, child]
          end

          expect(actual).to eq(expected)
        end
      end
    end
  end

  describe "#each_attribute" do
    expectations = {
      ast("1") => [[:value, 1]],
      ast("1.0") => [[:value, 1.0]],
      ast("'1") => [],
      ast("`1") => [],
      ast("~1") => [],
      ast("A") => [[:text, :A]],
      ast("a") => [[:text, :a]],
      ast("!a") => [[:operator, :"!"]],
      ast("a!") => [[:operator, :"!"]],
      ast("a + b") => [[:operator, :+]],
      ast("{ a }") => [],
      ast("[a]") => [],
      ast("a b") => [],
      ast("a(b)") => [],
      ast('"foo"') => [[:value, "foo"]]
    }

    expectations.each do |node, expected|
      context "with a #{node.class.basename}" do
        it "yields the proper attributes" do
          actual = []

          node.each_attribute do |name, value|
            actual << [name, value]
          end

          expect(actual).to eq(expected)
        end
      end
    end
  end

  describe "#children" do
    expectations = {
      ast("1") => [],
      ast("1.0") => [],
      ast("'1") => [:node],
      ast("`1") => [:node],
      ast("~1") => [:node],
      ast("A") => [],
      ast("a") => [],
      ast("!a") => [:node],
      ast("a!") => [:node],
      ast("a + b") => [:left, :right],
      ast("{ a }") => [:nodes],
      ast("[a]") => [:nodes],
      ast("a b") => [:left, :right],
      ast("a(b)") => [:node, :arguments],
      ast('"foo"') => []
    }

    expectations.each do |node, expected|
      context "with a #{node.class.basename}" do
        it "has the proper attribute names" do
          expect(node.children).to eq(expected)
        end
      end
    end
  end

  describe "#attributes" do
    expectations = {
      ast("1") => [:value],
      ast("1.0") => [:value],
      ast("'1") => [],
      ast("`1") => [],
      ast("~1") => [],
      ast("A") => [:text],
      ast("a") => [:text],
      ast("!a") => [:operator],
      ast("a!") => [:operator],
      ast("a + b") => [:operator],
      ast("{ a }") => [],
      ast("[a]") => [],
      ast("a b") => [],
      ast("a(b)") => [],
      ast('"foo"') => [:value]
    }

    expectations.each do |node, expected|
      context "with a #{node.class.basename}" do
        it "has the proper attribute names" do
          expect(node.attributes).to eq(expected)
        end
      end
    end
  end

  describe "#accept" do
    let(:node) { ast("`abc") }

    context "when the visitor responds to #visit_(lowercase basename)" do
      let(:visitor) do
        Class.new do
          def visit_quasiquote(x)
            x.foo!
          end
        end
      end

      it "sends the message" do
        expect(node).to receive(:foo!)
        node.accept(visitor.new)
      end
    end

    context "when the visitor does NOT respond to the specific message" do
      let(:visitor) do
        Class.new do
          def visit(x)
            x.foo!
          end
        end
      end

      it "sends #visit" do
        expect(node).to receive(:foo!)
        node.accept(visitor.new)
      end
    end
  end

  describe "#through" do
    let(:node) { ast("`abc") }

    it "reconstructs the node, yielding its children" do
      expect(node.through { ast("123") }).to eq(ast("`123"))
    end

    it "yields the children in order" do
      actual = []

      ast("[a, b, c]").through do |child|
        actual << child
        child
      end

      expect(actual).to eq([ast("a"), ast("b"), ast("c")])
    end
  end
end

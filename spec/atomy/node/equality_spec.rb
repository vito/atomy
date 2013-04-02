require "spec_helper"

require "atomy/node/equality"

def it_can_equate_itself
  it "can equate itself" do
    expect(node).to eq(node.dup)
  end
end

describe Atomy::Grammar::AST::Sequence do
  let(:node) { described_class.new([ast("foo"), ast("1")]) }
  it_can_equate_itself
end

describe Atomy::Grammar::AST::Number do
  let(:node) { ast("1") }
  it_can_equate_itself

  context "when the value differs" do
    it "is not equal" do
      expect(node).to_not eq(ast("2"))
    end
  end
end

describe Atomy::Grammar::AST::Literal do
  let(:node) { ast("1.0") }
  it_can_equate_itself

  context "when the value differs" do
    it "is not equal" do
      expect(node).to_not eq(ast("1.1"))
    end
  end
end

describe Atomy::Grammar::AST::Quote do
  let(:node) { ast("'a") }
  it_can_equate_itself

  context "when the node differs" do
    it "is not equal" do
      expect(node).to_not eq(ast("'b"))
    end
  end
end

describe Atomy::Grammar::AST::QuasiQuote do
  let(:node) { ast("`a") }
  it_can_equate_itself

  context "when the node differs" do
    it "is not equal" do
      expect(node).to_not eq(ast("`b"))
    end
  end
end

describe Atomy::Grammar::AST::Unquote do
  let(:node) { ast("'a") }
  it_can_equate_itself

  context "when the node differs" do
    it "is not equal" do
      expect(node).to_not eq(ast("~b"))
    end
  end
end

describe Atomy::Grammar::AST::Constant do
  let(:node) { ast("Foo") }
  it_can_equate_itself

  context "when the text differs" do
    it "is not equal" do
      expect(node).to_not eq(ast("Bar"))
    end
  end
end

describe Atomy::Grammar::AST::Word do
  let(:node) { ast("foo") }
  it_can_equate_itself

  context "when the text differs" do
    it "is not equal" do
      expect(node).to_not eq(ast("bar"))
    end
  end
end

describe Atomy::Grammar::AST::Prefix do
  let(:node) { ast("!foo") }
  it_can_equate_itself

  context "when the operator differs" do
    it "is not equal" do
      expect(node).to_not eq(ast("?foo"))
    end
  end

  context "when the node differs" do
    it "is not equal" do
      expect(node).to_not eq(ast("!bar"))
    end
  end
end

describe Atomy::Grammar::AST::Postfix do
  let(:node) { ast("foo!") }
  it_can_equate_itself

  context "when the operator differs" do
    it "is not equal" do
      expect(node).to_not eq(ast("foo?"))
    end
  end

  context "when the node differs" do
    it "is not equal" do
      expect(node).to_not eq(ast("bar!"))
    end
  end
end

describe Atomy::Grammar::AST::Infix do
  let(:node) { ast("foo = 1") }
  it_can_equate_itself

  context "when the operator differs" do
    it "is not equal" do
      expect(node).to_not eq(ast("foo + 1"))
    end
  end

  context "when the left node differs" do
    it "is not equal" do
      expect(node).to_not eq(ast("bar = 1"))
    end
  end

  context "when the right node differs" do
    it "is not equal" do
      expect(node).to_not eq(ast("foo = 2"))
    end
  end
end

describe Atomy::Grammar::AST::Block do
  let(:node) { ast("{ foo, 1 }") }
  it_can_equate_itself

  context "when there are no nodes" do
    it "is not equal" do
      expect(node).to_not eq(ast("{}"))
    end
  end

  context "when there are fewer nodes" do
    it "is not equal" do
      expect(node).to_not eq(ast("{ foo }"))
    end
  end

  context "when there are extra nodes" do
    it "is not equal" do
      expect(node).to_not eq(ast("{ foo, 1, 2 }"))
    end
  end
end

describe Atomy::Grammar::AST::List do
  let(:node) { ast("[foo, 1]") }
  it_can_equate_itself

  context "when there are no nodes" do
    it "is not equal" do
      expect(node).to_not eq(ast("[]"))
    end
  end

  context "when there are fewer nodes" do
    it "is not equal" do
      expect(node).to_not eq(ast("[foo]"))
    end
  end

  context "when there are extra nodes" do
    it "is not equal" do
      expect(node).to_not eq(ast("[foo, 1, 2]"))
    end
  end
end

describe Atomy::Grammar::AST::Compose do
  let(:node) { ast("foo 1") }
  it_can_equate_itself

  context "when the left node differs" do
    it "is not equal" do
      expect(node).to_not eq(ast("bar 1"))
    end
  end

  context "when the right node differs" do
    it "is not equal" do
      expect(node).to_not eq(ast("foo 2"))
    end
  end
end

describe Atomy::Grammar::AST::Apply do
  let(:node) { ast("foo(1, 2)") }
  it_can_equate_itself

  context "when the name differs" do
    it "is not equal" do
      expect(node).to_not eq(ast("bar(1)"))
    end
  end

  context "when there are no arguments" do
    it "is not equal" do
      expect(node).to_not eq(ast("foo()"))
    end
  end

  context "when there are fewer arguments" do
    it "is not equal" do
      expect(node).to_not eq(ast("foo(1)"))
    end
  end

  context "when there are extra arguments" do
    it "is not equal" do
      expect(node).to_not eq(ast("foo(1, 2, 3)"))
    end
  end
end

describe Atomy::Grammar::AST::StringLiteral do
  let(:node) { ast('"foo"') }
  it_can_equate_itself

  context "when the value differs" do
    it "is not equal" do
      expect(node).to_not eq(ast('"bar"'))
    end
  end
end

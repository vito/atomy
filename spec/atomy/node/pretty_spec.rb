require "spec_helper"

require "atomy/node/pretty"
require "atomy/node/equality"
require "atomy/parser"

def it_can_pretty_print_itself
  it "pretty-prints, optionally with parentheses to disambiguate" do
    if source =~ / /
      expect(node.to_s).to eq("(#{source})")
    else
      expect(node.to_s).to eq(source)
    end
  end

  it "parses back to itself" do
    expect(ast(node.to_s)).to eq(node)
  end
end

describe Atomy::Grammar::AST::Sequence do
  let(:node) { described_class.new([ast("foo"), ast("1")]) }

  it "pretty-prints with comma separation" do
    expect(node.to_s).to eq("foo, 1")
  end

  it "parses back to itself" do
    expect(Atomy::Parser.parse_string(node.to_s)).to eq(node)
  end
end

describe Atomy::Grammar::AST::Infix do
  context "when the left-hand side is missing" do
    let(:source) { "+ 1" }
    let(:node) { ast("+ 1") }
    it_can_pretty_print_itself
  end
end

describe Atomy::Grammar::AST::Word do
  context "when the word starts with an underscore (_)" do
    let(:source) { "_foo" }
    let(:node) { ast("_foo") }
    it_can_pretty_print_itself
  end

  context "when the word is hyphenated" do
    let(:source) { "foo-bar" }
    let(:node) { ast("foo-bar") }
    it_can_pretty_print_itself
  end
end

NODE_SAMPLES.each do |klass, sample|
  describe klass do
    let(:source) { sample }
    let(:node) { ast(source) }

    it_can_pretty_print_itself
  end
end

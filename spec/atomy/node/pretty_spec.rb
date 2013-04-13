require "spec_helper"

require "atomy/node/pretty"
require "atomy/node/equality"
require "atomy/parser"

def it_can_pretty_print_itself
  it "can pretty-print itself" do
    expect(node.to_s).to eq(source)
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

NODE_SAMPLES.each do |klass, sample|
  describe klass do
    let(:source) { sample }
    let(:node) { ast(source) }

    it_can_pretty_print_itself
  end
end

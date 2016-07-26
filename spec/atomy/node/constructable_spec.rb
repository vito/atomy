require "spec_helper"

require "atomy/node/constructable"
require "atomy/node/equality"

def it_can_construct_itself
  it "can construct itself" do
    code =
      Atomy::Compiler.package(__FILE__.to_sym, __LINE__) do |gen|
        node.construct(gen)
      end

    code.scope = binding.constant_scope

    block = Atomy::Compiler.construct_block(code, binding)
    constructed = block.call

    expect(constructed).to eq(node)
  end
end

describe Atomy::Grammar::AST::Sequence do
  let(:node) { described_class.new([ast("foo"), ast("1")]) }
  it_can_construct_itself
end

SpecHelpers::NODE_SAMPLES.each do |klass, sample|
  describe klass do
    let(:node) { ast(sample) }
    it_can_construct_itself
  end
end

describe Atomy::Grammar::AST::Infix do
  context "when the left-hand side is missing" do
    let(:node) { ast("+ 1") }
    it_can_construct_itself
  end
end

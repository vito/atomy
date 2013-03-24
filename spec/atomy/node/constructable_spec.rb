require "spec_helper"

require "atomy/node/constructable"
require "atomy/node/equality"

def it_can_construct_itself
  it "can construct itself" do
    gen = Rubinius::Generator.new
    gen.file = __FILE__.to_sym
    gen.set_line(__LINE__)

    node.construct(gen)
    gen.ret

    gen.close
    gen.encode

    code = gen.package(Rubinius::CompiledCode)
    code.scope = binding.constant_scope

    block = Rubinius::BlockEnvironment.new
    block.under_context(binding.variables, code)

    constructed = block.call

    expect(constructed).to eq(node)
  end
end

describe Atomy::Grammar::AST::Sequence do
  let(:node) { described_class.new([ast("foo"), ast("1")]) }
  it_can_construct_itself
end

NODE_SAMPLES.each do |klass, sample|
  describe klass do
    let(:node) { ast(sample) }
    it_can_construct_itself
  end
end

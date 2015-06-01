require "spec_helper"

require "atomy/code/symbol"

describe Atomy::Code::Symbol do
  let(:compile_module) { Atomy::Module.new { use Atomy::Bootstrap } }

  subject { described_class.new(:abc) }

  it_compiles_as do |gen|
    gen.push_literal(:abc)
  end
end

require "spec_helper"

require "atomy/code/symbol"

describe Atomy::Code::False do
  let(:compile_module) { Atomy::Module.new { use Atomy::Bootstrap } }

  subject { described_class.new }

  it_compiles_as do |gen|
    gen.push_false
  end
end

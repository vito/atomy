require "spec_helper"

require "atomy/code/integer"

describe Atomy::Code::Integer do
  let(:compile_module) { Atomy::Module.new { use Atomy::Bootstrap } }

  subject { described_class.new(123) }

  it_compiles_as do |gen|
    gen.push_int 123
  end
end

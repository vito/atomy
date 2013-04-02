require "spec_helper"

require "atomy/bootstrap"
require "atomy/module"
require "atomy/code/quote"

describe Atomy::Code::Quote do
  let(:compile_module) do
    Atomy::Module.new do
      use Atomy::Bootstrap
    end
  end

  let(:quoted) { ast("[a + b c, 42]") }

  subject { described_class.new(quoted) }

  it_compiles_as do |gen|
    quoted.construct(gen)
  end
end

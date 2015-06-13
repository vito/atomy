require "spec_helper"

require "atomy/code/class_variable"

describe Atomy::Code::ClassVariable do
  let(:compile_module) { Atomy::Module.new { use Atomy::Bootstrap } }

  subject { described_class.new(:abc) }

  it_compiles_as do |gen|
    gen.push_scope
    gen.push_literal(:@@abc)
    gen.send(:class_variable_get, 1)
  end
end

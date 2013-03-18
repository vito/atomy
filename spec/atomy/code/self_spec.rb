require "spec_helper"

require "atomy/code/self"

describe Atomy::Code::Self do
  let(:compile_module) { nil }

  it_compiles_as do |gen|
    gen.push_self
  end
end

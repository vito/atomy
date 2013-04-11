require "spec_helper"

require "atomy/bootstrap"
require "atomy/code/constant"

describe Atomy::Code::Constant do
  let(:compile_module) { Atomy::Bootstrap }

  subject { described_class.new(:Kernel) }

  it_compiles_as do |gen|
    gen.push_const(:Kernel)
  end

  context "with a parent" do
    subject { described_class.new(:Kernel, ast("Atomy")) }

    it_compiles_as do |gen|
      gen.push_const(:Atomy)
      gen.find_const(:Kernel)
    end
  end
end

require "spec_helper"

require "atomy/bootstrap"
require "atomy/code/variable"

describe Atomy::Code::Variable do
  let(:compile_module) do
    Atomy::Module.new do
      use Atomy::Bootstrap
    end
  end

  let(:name) { :foo }

  subject { described_class.new(name) }

  context "when a local is found" do
    it_compiles_as do |gen|
      # just to prep
      var = gen.state.scope.new_local(name).reference

      gen.push_local(var.slot)
    end
  end

  context "when a local is NOT found" do
    it_compiles_as do |gen|
      gen.push_self
      gen.allow_private
      gen.send(name, 0)
    end
  end
end

require "spec_helper"

require "atomy/module"
require "atomy/pattern/wildcard"

describe Atomy::Pattern::Wildcard do
  describe "#matches?" do
    it { should === nil }
    it { should === Object.new }
  end

  describe "#target" do
    its(:target) { should eq(Object) }
  end

  describe "#inline_matches?" do
    it_compiles_as(:inline_matches?) do |gen|
      gen.pop
      gen.push_true
    end
  end
end

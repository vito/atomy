require "spec_helper"

require "atomy/module"
require "atomy/pattern/instance_variable"

describe Atomy::Pattern::InstanceVariable do
  subject { described_class.new(:abc) }

  describe "#name" do
    it "returns the name" do
      expect(subject.name).to eq(:abc)
    end
  end

  describe "#matches?" do
    it { should === nil }
    it { should === Object.new }
  end

  describe "#assign" do
    it "assigns the instance variable in the given scope" do
      subject.assign(Rubinius::VariableScope.current, 42)
      expect(@abc).to eq(42)
    end
  end
end

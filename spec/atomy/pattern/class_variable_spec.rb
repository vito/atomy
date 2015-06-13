require "spec_helper"

require "atomy/module"
require "atomy/pattern/class_variable"

describe Atomy::Pattern::ClassVariable do
  let(:klass) { Class.new }
  let(:scope) { Rubinius::ConstantScope.new(klass, nil) }

  subject { described_class.new(scope, :abc) }

  its(:name) { should == :abc }
  its(:scope) { should == scope }

  describe "#matches?" do
    it { should === nil }
    it { should === Object.new }
  end

  describe "#assign" do
    it "assigns the class variable in the given scope" do
      subject.assign(Rubinius::VariableScope.current, 42)
      expect(scope.class_variable_get(:@@abc)).to eq(42)
    end
  end
end

require "spec_helper"

require "atomy/module"
require "atomy/pattern/class_variable"

describe Atomy::Pattern::ClassVariable do
  let(:klass) { Class.new }

  subject { described_class.new(:abc) }

  its(:name) { should == :abc }

  describe "#matches?" do
    it { should === nil }
    it { should === Object.new }
  end
end

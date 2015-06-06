require "spec_helper"

require "atomy/codeloader"
require "atomy/pattern/instance_variable"
require "atomy/pattern/attribute"

module PatternsKernelModule
  class Blah
  end
end

describe "patterns kernel" do
  subject { Atomy::Module.new { use(require_kernel("patterns")) } }

  describe "#pattern" do
    context "with a Compose node with a Constant as the right-hand side" do
      let(:node) { ast("PatternsKernelModule Blah") }

      it "expands it into a KindOf pattern" do
        expanded = subject.evaluate(subject.pattern(node))
        expect(expanded).to be_a(Atomy::Pattern::KindOf)
        expect(expanded.klass).to eq(PatternsKernelModule::Blah)
      end

      it "declares no locals" do
        expect(subject.pattern(node).locals).to be_empty
      end
    end

    context "with a Compose node with a Word as the right-hand side" do
      let(:node) { ast("42 foo") }

      it "expands it into an Attribute pattern" do
        expanded = subject.evaluate(subject.pattern(node))
        expect(expanded).to be_a(Atomy::Pattern::Attribute)
        expect(expanded.receiver).to eq(42)
        expect(expanded.attribute).to eq(:foo)
      end

      it "declares no locals" do
        expect(subject.pattern(node).locals).to be_empty
      end
    end

    context "with an instance variable" do
      let(:node) { ast("@foo") }

      it "expands it into an InstanceVariable pattern" do
        expanded = subject.evaluate(subject.pattern(node))
        expect(expanded).to be_a(Atomy::Pattern::InstanceVariable)
        expect(expanded.name).to eq(:foo)
      end

      it "declares no locals" do
        expect(subject.pattern(node).locals).to be_empty
      end
    end
  end
end

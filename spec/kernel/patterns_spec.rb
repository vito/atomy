require "spec_helper"

require "atomy/codeloader"

module PatternsKernelModule
  class Blah
  end
end

describe "patterns kernel" do
  subject { Atomy::Module.new { use(require_kernel("patterns")) } }

  describe "#pattern" do
    context "with a Compose node with a Constant as the right-hand side" do
      it "expands it into a KindOf pattern" do
        expanded = subject.evaluate(subject.pattern(ast("PatternsKernelModule Blah")))
        expect(expanded).to be_a(Atomy::Pattern::KindOf)
        expect(expanded.klass).to eq(PatternsKernelModule::Blah)
      end

      it "declares no locals" do
        expect(subject.pattern(ast("PatternsKernelModule Blah")).locals).to be_empty
      end
    end
  end
end

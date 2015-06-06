require "spec_helper"

require "atomy/codeloader"

describe "control-flow kernel" do
  subject { Atomy::Module.new { use(require_kernel("control-flow")) } }

  describe "a || b" do
    context "when a is truthy" do
      it "returns a" do
        expect(subject.evaluate(ast("1 || 2"))).to eq(1)
      end

      it "does not evaluate b" do
        expect(subject.evaluate(ast("1 || raise(\"evaluated\")"))).to eq(1)
      end
    end

    context "when a is falsy" do
      it "returns b" do
        expect(subject.evaluate(ast("false || 2"))).to eq(2)
      end
    end
  end
end

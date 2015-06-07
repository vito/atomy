require "spec_helper"

require "atomy/codeloader"

describe "control-flow kernel" do
  subject { Atomy::Module.new { use(require_kernel("control-flow")) } }

  describe "a && b" do
    context "when a is truthy" do
      it "evaluates and returns b" do
        expect(subject.evaluate(ast("1 && 42"))).to eq(42)
      end
    end

    context "when a is falsy" do
      it "returns a" do
        expect(subject.evaluate(ast("false && 2"))).to eq(false)
      end

      it "does not evaluate b" do
        expect(subject.evaluate(ast("false && raise(\"evaluated\")"))).to eq(false)
      end
    end
  end

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

  describe "if(x) then: y; else: z" do
    context "when x is truthy" do
      it "returns y" do
        expect(subject.evaluate(ast("if(true) then: 1; else: 2"))).to eq(1)
      end

      it "does not evaluate z" do
        expect(subject.evaluate(ast("if(true) then: 1; else: raise(\"evaluated\")"))).to eq(1)
      end
    end

    context "when x is falsy" do
      it "returns z" do
        expect(subject.evaluate(ast("if(false) then: 1; else: 2"))).to eq(2)
      end

      it "does not evaluate y" do
        expect(subject.evaluate(ast("if(false) then: raise(\"evaluated\"); else: 2"))).to eq(2)
      end
    end
  end

  describe "when(x): y" do
    context "when x is truthy" do
      it "returns y" do
        expect(subject.evaluate(ast("when(true): 1"))).to eq(1)
      end
    end

    context "when x is falsy" do
      it "returns nil" do
        expect(subject.evaluate(ast("when(false): 1"))).to be_nil
      end

      it "does not evaluate y" do
        expect { subject.evaluate(ast("when(false): raise(\"evaluated\")")) }.to_not raise_error
      end
    end
  end

  describe "unless(x): y" do
    context "when x is truthy" do
      it "returns nil" do
        expect(subject.evaluate(ast("unless(true): 1"))).to be_nil
      end

      it "does not evaluate y" do
        expect { subject.evaluate(ast("unless(true): raise(\"evaluated\")")) }.to_not raise_error
      end
    end

    context "when x is falsy" do
      it "returns y" do
        expect(subject.evaluate(ast("unless(false): 1"))).to eq(1)
      end
    end
  end

  describe "while(x): y" do
    it "continuously runs as long as evaluating 'x' is truthy" do
      a = 1
      expect(subject.evaluate(seq("while(a != 10): a =! (a + 1)"))).to be_nil
      expect(a).to eq(10)
    end
  end

  describe "until(x): y" do
    it "continuously runs as long as evaluating 'x' is falsy" do
      a = 1
      expect(subject.evaluate(seq("until(a == 10): a =! (a + 1)"))).to be_nil
      expect(a).to eq(10)
    end
  end
end

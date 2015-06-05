require "spec_helper"

require "atomy/codeloader"

describe "define kernel" do
  subject { Atomy::Module.new { use(require_kernel("define")) } }

  describe "method definition" do
    it "implements method definition notation" do
      subject.evaluate(ast("def(foo(a)): a + 1"), subject.compile_context)
      expect(subject.foo(41)).to eq(42)
    end

    it "defines branches that close over its scope" do
      subject.evaluate(seq("a = 1, def(foo(b)): a + b"), subject.compile_context)
      expect(subject.foo(41)).to eq(42)
    end
  end
end

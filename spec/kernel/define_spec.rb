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

  describe "function definition" do
    it "implements function definition notation" do
      expect(subject.evaluate(seq("
        fn(foo(a)): a + 1
        foo(2)
      "))).to eq(3)
    end

    it "defines function that close over their scope" do
      expect(subject.evaluate(seq("
        b = 1
        fn(foo(a)): a + b
        foo(2)
      "))).to eq(3)
    end

    it "defines function branches" do
      expect(subject.evaluate(seq("
        fn(fib(0)): 0
        fn(fib(1)):1
        fn(fib(n)): fib(n - 2) + fib(n - 1)
        fib(5)
       "))).to eq(5)
    end

    it "does not define any methods" do
      expect(subject).to_not respond_to(:foo)

      expect {
        subject.evaluate(ast("fn(foo(a)): a + 1"), subject.compile_context)
      }.to_not change { subject.respond_to?(:foo) }
    end
  end
end

require "spec_helper"

require "atomy/codeloader"

describe "define kernel" do
  subject { Atomy::Module.new { use(require_kernel("define")) } }

  describe "method definition" do
    it "implements method definition notation" do
      subject.evaluate(ast("def(foo(a)): a + 1"), subject.compile_context)
      expect(subject.foo(41)).to eq(42)
    end

    it "can define methods with blocks" do
      expect(subject.evaluate(seq("
        def(foo(a) &b): a + b call
        foo(2): 3
      "))).to eq(5)
    end

    it "implements method definition notation with no args" do
      expect(subject.evaluate(seq("
        a = 0
        def(foo):
          a =! (a + 1)
          a

        foo()
        foo()
        foo()
      "))).to eq(3)
    end

    it "implements method invocation notation with no args" do
      expect(subject.evaluate(seq("
        a = 0
        def(foo):
          a =! (a + 1)
          a

        foo
        foo
        foo
      "))).to eq(3)
    end

    it "implements method definition notation with no args and a block" do
      expect(subject.evaluate(seq("
        def(foo &blk): blk call
        foo(): 3
      "))).to eq(3)
    end

    it "implements method invocation notation with no args and a block" do
      expect(subject.evaluate(seq("
        def(foo &blk): blk call
        foo: 3
      "))).to eq(3)
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

    it "can define function branches with blocks" do
      expect(subject.evaluate(seq("
        fn(foo(a) &b): a + b call
        foo(2): 3
      "))).to eq(5)
    end

    it "implements function definition notation with no args" do
      expect(subject.evaluate(seq("
        a = 0
        fn(foo):
          a =! (a + 1)
          a

        foo()
        foo()
        foo()
      "))).to eq(3)
    end

    it "implements function invocation notation with no args" do
      expect(subject.evaluate(seq("
        a = 0
        fn(foo):
          a =! (a + 1)
          a

        foo
        foo
        foo
      "))).to eq(3)
    end

    it "implements function definition notation with no args and a block" do
      expect(subject.evaluate(seq("
        fn(foo &blk): blk call
        foo(): 3
      "))).to eq(3)
    end

    it "implements function invocation notation with no args and a block" do
      expect(subject.evaluate(seq("
        fn(foo &blk): blk call
        foo: 3
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

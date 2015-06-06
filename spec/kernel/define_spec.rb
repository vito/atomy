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

  describe "class creation" do
    it "constructs an anonymous class" do
      expect(subject.evaluate(ast("class {}"))).to be_a(Class)
    end

    it "evaluates the body with the class as the method target" do
      klass = subject.evaluate(ast("class: def(foo): 42"))
      expect(klass).to be_a(Class)
      expect(klass.respond_to?(:foo)).to eq(false)
      expect(klass.new.foo).to eq(42)
      expect(subject.respond_to?(:foo)).to eq(false)
    end

    it "closes over the scope" do
      klass, a = subject.evaluate(seq("
        a = 1

        x = class:
          a = (a + 1)
          def(foo): a

        [x, a]
      "))
      expect(klass).to be_a(Class)
      expect(klass.respond_to?(:foo)).to eq(false)
      expect(klass.new.foo).to eq(2)
      expect(a).to eq(1)
      expect(subject.respond_to?(:foo)).to eq(false)
    end

    context "with a superclass" do
      it "constructs an anonymous subclass of the given class" do
        parent = Class.new
        klass = subject.evaluate(ast("parent class {}"))
        expect(klass).to be_a(Class)
        expect(klass.new).to be_a(parent)
      end
    end
  end

  describe "module creation" do
    it "constructs an anonymous module" do
      expect(subject.evaluate(ast("module {}"))).to be_a(Module)
    end

    it "evaluates the body with the module as the method target" do
      mod = subject.evaluate(ast("module: def(foo): 42"))
      expect(mod).to be_a(Module)
      expect(mod.respond_to?(:foo)).to eq(false)
      expect(subject.respond_to?(:foo)).to eq(false)

      subject.use(mod)

      expect(subject.foo).to eq(42)
    end
  end

  describe "module opening" do
    it "can reopen modules" do
      expect(subject.evaluate(ast("Atomy Grammar open: AST"))).to eq(Atomy::Grammar::AST)
    end
  end

  describe "class opening" do
    it "can reopen classes" do
      x = Class.new
      subject.evaluate(ast("x open: def(foo): 42"))
      expect(x.new.foo).to eq(42)
    end

    it "can reopen singleton classes" do
      x = Class.new
      subject.evaluate(ast("x singleton: def(foo): 42"))
      expect(x.foo).to eq(42)
    end

    it "can reopen the current singleton class" do
      klass = subject.evaluate(ast("class: singleton: def(foo): 42"))
      expect(klass.foo).to eq(42)
    end
  end

  describe "pattern defining" do
    it "provides a macro for defining patterns" do
      subject.evaluate(
        ast("pattern(42 foo(~(bar & Word))): pattern(bar)"),
        subject.compile_context,
      )

      patcode = subject.pattern(ast("42 foo(fizz)"))
      pat = subject.evaluate(patcode)
      expect(patcode.locals).to eq([:fizz])
      expect(pat).to be_a(Atomy::Pattern::Wildcard)
      expect(pat.name).to eq(:fizz)
    end
  end
end

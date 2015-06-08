require "spec_helper"

require "atomy/codeloader"
require "atomy/message_structure"
require "atomy/node/equality"

describe "define kernel" do
  subject { Atomy::Module.new { use(require_kernel("define")) } }

  describe "method definition" do
    it "implements method definition using MessageStructure to determine everything" do
      fake_structure = instance_double(
        "Atomy::MessageStruture",
        name: :some_name,
        proc_argument: ast("some-block"),
        arguments: [ast("arg-1"), ast("arg-2")],
        receiver: ast("SomeClass"),
      )

      allow(Atomy::MessageStructure).to receive(:new).and_call_original
      expect(Atomy::MessageStructure).to receive(:new).with(ast("some-method-definition")).and_return(fake_structure)

      some_class = Class.new
      subject.const_set(:SomeClass, some_class)

      subject.evaluate(ast("
        def(some-method-definition):
          some-block call(arg-1, arg-2)
      "), subject.compile_context)

      expect(some_class.new.some_name(1, 2) { |a, b| a + b }).to eq(3)
    end

    it "closes over its scope" do
      subject.evaluate(seq("a = 1, def(foo(b)): a + b"), subject.compile_context)
      expect(subject.foo(41)).to eq(42)
    end
  end

  describe "function definition" do
    it "implements function definition using MessageStructure to determine everything" do
      fake_structure = instance_double(
        "Atomy::MessageStruture",
        name: :some_name,
        proc_argument: ast("some-block"),
        arguments: [ast("arg-1"), ast("arg-2")],
        receiver: nil, #ast("SomeClass"),
      )

      allow(Atomy::MessageStructure).to receive(:new).and_call_original
      expect(Atomy::MessageStructure).to receive(:new).with(ast("some-method-definition")).and_return(fake_structure)

      some_class = Class.new
      subject.const_set(:SomeClass, some_class)

      expect(subject.evaluate(seq("
        fn(some-method-definition):
          some-block call(arg-1, arg-2)

        some-name(1, 2) [a, b]: a + b
      "), subject.compile_context)).to eq(3)
    end

    it "can be recursive, as the body sees itself as a function" do
      expect(subject.evaluate(seq("
        fn(foo(2)): foo(4)
        fn(foo(4)): 42
        foo(2)
      "))).to eq(42)
    end

    it "can define branches in separate evaluations" do
      subject.evaluate(ast("fn(foo(2)): foo(4)"))
      subject.evaluate(ast("fn(foo(4)): 42"))
      expect(subject.evaluate(ast("foo(2)"))).to eq(42)
    end

    it "defines function that close over their scope" do
      expect(subject.evaluate(seq("
        b = 1
        fn(foo(a)): a + b
        foo(2)
      "))).to eq(3)
    end

    it "defines multiple function branches" do
      expect(subject.evaluate(seq("
        fn(fib(0)): 0
        fn(fib(1)):1
        fn(fib(n)): fib(n - 2) + fib(n - 1)
        fib(5)
       "))).to eq(5)
    end

    it "does not define any methods, unlike def" do
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

  describe "variable mutation" do
    it "implements +=" do
      expect(subject.evaluate(seq("a = 1, { a += 1 } call, a"))).to eq(2)
    end

    it "implements -=" do
      expect(subject.evaluate(seq("a = 1, { a -= 1 } call, a"))).to eq(0)
    end

    it "implements *=" do
      expect(subject.evaluate(seq("a = 2, { a *= 5 } call, a"))).to eq(10)
    end

    it "implements **=" do
      expect(subject.evaluate(seq("a = 5, { a **= 2 } call, a"))).to eq(25)
    end

    it "implements /=" do
      expect(subject.evaluate(seq("a = 10, { a /= 5 } call, a"))).to eq(2)
    end
  end
end

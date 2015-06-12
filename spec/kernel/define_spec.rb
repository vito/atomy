require "spec_helper"

require "atomy/codeloader"
require "atomy/message_structure"
require "atomy/node/equality"

describe "define kernel" do
  subject { Atomy::Module.new { use(require("define")) } }

  describe "method definition" do
    it "implements method definition using MessageStructure to determine everything" do
      fake_structure = instance_double(
        "Atomy::MessageStruture",
        name: :some_name,
        receiver: ast("SomeClass"),
        arguments: [ast("arg-1"), ast("arg-2")],
        default_arguments: [
          Atomy::MessageStructure::DefaultArgument.new(ast("default-arg-1"), ast(".default-for-1")),
          Atomy::MessageStructure::DefaultArgument.new(ast("default-arg-2"), ast(".default-for-2")),
        ],
        splat_argument: ast("some-splat"),
        post_arguments: [ast("post-arg-1"), ast("post-arg-2")],
        proc_argument: ast("some-block"),
      )

      allow(Atomy::MessageStructure).to receive(:new).and_call_original
      expect(Atomy::MessageStructure).to receive(:new).with(ast("some-method-definition")).and_return(fake_structure)

      some_class = Class.new
      subject.const_set(:SomeClass, some_class)

      subject.evaluate(ast("
        def(some-method-definition):
          some-block call(arg-1, arg-2, default-arg-1, default-arg-2, some-splat, post-arg-1, post-arg-2)
      "), subject.compile_context)

      expect(some_class.new.some_name(
        :arg_1,
        :arg_2,
        :default_1,
        :default_2,
        :splat_a,
        :splat_b,
        :splat_c,
        :post_1,
        :post_2,
      ) { |*args| args }).to eq([
        :arg_1,
        :arg_2,
        :default_1,
        :default_2,
        [:splat_a, :splat_b, :splat_c],
        :post_1,
        :post_2,
      ])

      expect(some_class.new.some_name(
        :arg_1,
        :arg_2,
        :post_1,
        :post_2,
      ) { |*args| args }).to eq([
        :arg_1,
        :arg_2,
        :default_for_1,
        :default_for_2,
        [],
        :post_1,
        :post_2,
      ])
    end

    describe "defaults" do
      it "supports default arguments" do
        subject.evaluate(seq("def(foo(a, b = 2)): [a, b]"), subject.compile_context)
        expect(subject.foo(1)).to eq([1, 2])
        expect(subject.foo(1, 3)).to eq([1, 3])
      end

      it "supports default arguments that close over the branch's scope" do
        subject.evaluate(seq("x = 42, def(foo(a, b = x)): [a, b]"), subject.compile_context)
        expect(subject.foo(1)).to eq([1, 42])
        expect(subject.foo(1, 3)).to eq([1, 3])
      end

      it "supports default arguments that refer to each other" do
        subject.evaluate(seq("def(foo(a, b = (a + 1))): [a, b]"), subject.compile_context)
        expect(subject.foo(1)).to eq([1, 2])
        expect(subject.foo(2)).to eq([2, 3])
        expect(subject.foo(1, 3)).to eq([1, 3])
      end

      it "only evaluates the default once per invocation" do
        subject.evaluate(seq("x = 0, def(foo(a, b = (x += 1))): [a, b]"), subject.compile_context)
        expect(subject.foo(1)).to eq([1, 1])
        expect(subject.foo(1)).to eq([1, 2])
      end

      it "does not evaluate the default if a value is given" do
        subject.evaluate(seq("x = 0, def(foo(a, b = (x += 1))): [a, b]"), subject.compile_context)
        expect(subject.foo(1)).to eq([1, 1])
        expect(subject.foo(1, 30)).to eq([1, 30])
        expect(subject.foo(1)).to eq([1, 2])
      end

      it "pattern-matches the given value" do
        subject.evaluate(seq("x = 0, def(foo(a, 2 = (x += 1))): [a, x]"), subject.compile_context)
        expect { subject.foo(1, 30) }.to raise_error(Atomy::MessageMismatch)
        expect(subject.foo(1, 2)).to eq([1, 0])
      end

      it "pattern-matches the default value" do
        subject.evaluate(seq("x = 0, def(foo(a, 2 = (x += 1))): [a, x]"), subject.compile_context)
        expect { subject.foo(1) }.to raise_error(Atomy::MessageMismatch)
        expect(subject.foo(1)).to eq([1, 2])
        expect { subject.foo(1) }.to raise_error(Atomy::MessageMismatch)
      end
    end

    describe "posts" do
      it "supports post arguments after defaults" do
        subject.evaluate(seq("def(foo(a, b = 2, c)): [a, b, c]"), subject.compile_context)
        expect { subject.foo(1) }.to raise_error(ArgumentError)
        expect(subject.foo(1, 3)).to eq([1, 2, 3])
        expect(subject.foo(1, 42, 3)).to eq([1, 42, 3])
      end

      it "supports post arguments after splats" do
        subject.evaluate(seq("def(foo(a, *bs, c)): [a, bs, c]"), subject.compile_context)
        expect { subject.foo(1) }.to raise_error(ArgumentError)
        expect(subject.foo(1, 2)).to eq([1, [], 2])
        expect(subject.foo(1, 2, 3)).to eq([1, [2], 3])
      end

      it "supports post arguments after defaults and splats" do
        subject.evaluate(seq("def(foo(a, b = 2, *cs, d)): [a, b, cs, d]"), subject.compile_context)
        expect { subject.foo(1) }.to raise_error(ArgumentError)
        expect(subject.foo(1, 3)).to eq([1, 2, [], 3])
        expect(subject.foo(1, 42, 3)).to eq([1, 42, [], 3])
        expect(subject.foo(1, 42, 43, 44, 3)).to eq([1, 42, [43, 44], 3])
      end
    end

    it "closes over its scope" do
      subject.evaluate(seq("a = 1, def(foo(b)): a + b"), subject.compile_context)
      expect(subject.foo(41)).to eq(42)
    end
  end

  describe "function definition" do
    it "can be recursive, as the body sees itself as a function" do
      expect(subject.evaluate(seq("
        fn(foo(2)): foo(4)
        fn(foo(4)): 42
        foo(2)
      "))).to eq(42)
    end

    it "can predeclare a function" do
      expect(subject.evaluate(seq("
        fn(bar)
        fn(foo(x)): bar(x * 2)
        fn(bar(x)): x + 1
        foo(15)
      "))).to eq(31)
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

    describe "defaults" do
      it "supports default arguments" do
        subject.evaluate(seq("fn(foo(a, b = 2)): [a, b]"))
        expect(subject.evaluate(ast("foo(1)"))).to eq([1, 2])
        expect(subject.evaluate(ast("foo(1, 3)"))).to eq([1, 3])
      end

      it "supports default arguments that close over the branch's scope" do
        subject.evaluate(seq("x = 42, fn(foo(a, b = x)): [a, b]"))
        expect(subject.evaluate(ast("foo(1)"))).to eq([1, 42])
        expect(subject.evaluate(ast("foo(1, 3)"))).to eq([1, 3])
      end

      it "supports default arguments that refer to each other" do
        subject.evaluate(seq("fn(foo(a, b = (a + 1))): [a, b]"))
        expect(subject.evaluate(ast("foo(1)"))).to eq([1, 2])
        expect(subject.evaluate(ast("foo(2)"))).to eq([2, 3])
        expect(subject.evaluate(ast("foo(1, 3)"))).to eq([1, 3])
      end

      it "only evaluates the default once per invocation" do
        subject.evaluate(seq("x = 0, fn(foo(a, b = (x += 1))): [a, b]"))
        expect(subject.evaluate(ast("foo(1)"))).to eq([1, 1])
        expect(subject.evaluate(ast("foo(1)"))).to eq([1, 2])
      end

      it "does not evaluate the default if a value is given" do
        subject.evaluate(seq("x = 0, fn(foo(a, b = (x += 1))): [a, b]"))
        expect(subject.evaluate(ast("foo(1)"))).to eq([1, 1])
        expect(subject.evaluate(ast("foo(1, 30)"))).to eq([1, 30])
        expect(subject.evaluate(ast("foo(1)"))).to eq([1, 2])
      end

      it "pattern-matches the given value" do
        subject.evaluate(seq("x = 0, fn(foo(a, 2 = (x += 1))): [a, x]"))
        expect { subject.evaluate(ast("foo(1, 30)")) }.to raise_error(Atomy::MessageMismatch)
        expect(subject.evaluate(ast("foo(1, 2)"))).to eq([1, 0])
      end

      it "pattern-matches the default value" do
        subject.evaluate(seq("x = 0, fn(foo(a, 2 = (x += 1))): [a, x]"))
        expect { subject.evaluate(ast("foo(1)")) }.to raise_error(Atomy::MessageMismatch)
        expect(subject.evaluate(ast("foo(1)"))).to eq([1, 2])
        expect { subject.evaluate(ast("foo(1)")) }.to raise_error(Atomy::MessageMismatch)
      end
    end

    describe "posts" do
      it "supports post arguments after defaults" do
        subject.evaluate(seq("fn(foo(a, b = 2, c)): [a, b, c]"))
        expect { subject.evaluate(ast("foo(1)")) }.to raise_error(ArgumentError)
        expect(subject.evaluate(ast("foo(1, 3)"))).to eq([1, 2, 3])
        expect(subject.evaluate(ast("foo(1, 42, 3)"))).to eq([1, 42, 3])
      end

      it "supports post arguments after splats" do
        subject.evaluate(seq("fn(foo(a, *bs, c)): [a, bs, c]"))
        expect { subject.evaluate(ast("foo(1)")) }.to raise_error(ArgumentError)
        expect(subject.evaluate(ast("foo(1, 2)"))).to eq([1, [], 2])
        expect(subject.evaluate(ast("foo(1, 2, 3)"))).to eq([1, [2], 3])
      end

      it "supports post arguments after defaults and splats" do
        subject.evaluate(seq("fn(foo(a, b = 2, *cs, d)): [a, b, cs, d]"))
        expect { subject.evaluate(ast("foo(1)")) }.to raise_error(ArgumentError)
        expect(subject.evaluate(ast("foo(1, 3)"))).to eq([1, 2, [], 3])
        expect(subject.evaluate(ast("foo(1, 42, 3)"))).to eq([1, 42, [], 3])
        expect(subject.evaluate(ast("foo(1, 42, 43, 44, 3)"))).to eq([1, 42, [43, 44], 3])
      end
    end

    SpecHelpers::MESSAGE_FORMS.each do |form|
      node = ast(form)

      structure = Atomy::MessageStructure.new(node)
      next if structure.receiver # cannot possibly be a function definition

      next if structure.block # defining with block literal arg means nothing

      it "implements function defining and calling in the form '#{form}'" do
        receiver = Object.new

        # define a function that just calls through to the receiver
        subject.evaluate(ast("fn(#{form}): receiver #{form}"))

        # be sure to hide away these locals so the function doesn't just close
        # over them
        proc do
          arg_1 = Object.new
          arg_2 = Object.new
          splat_args = [Object.new, Object.new]
          proc_arg = proc {}
          block_body = Object.new
          result = Object.new

          expect(receiver).to receive(structure.name) do |*args, &blk|
            expected_args = [arg_1, arg_2][0...structure.arguments.size]
            expected_args += splat_args if structure.splat_argument

            expect(args).to eq(expected_args)

            if structure.proc_argument
              expect(blk).to eq(proc_arg)
            elsif structure.block
              if structure.block.is_a?(Atomy::Grammar::AST::Compose)
                # block has arguments
                expect(blk.call(1, 2)).to eq([1, 2])
              else
                # block has no args
                expect(blk.call).to eq(block_body)
              end
            end

            result
          end

          expect(subject.evaluate(node)).to eq(result)
        end.call
      end
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

    it "implements &=" do
      expect(subject.evaluate(seq("a = 258, { a &= 2 } call, a"))).to eq(2)
    end

    it "implements |=" do
      expect(subject.evaluate(seq("a = 256, { a |= 2 } call, a"))).to eq(258)
    end
  end
end

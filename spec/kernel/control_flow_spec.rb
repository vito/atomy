require "spec_helper"

require "atomy/codeloader"

describe "control-flow kernel" do
  subject { Atomy::Module.new { use(require("control-flow")) } }

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

    it "implements &&=" do
      expect(subject.evaluate(seq("a = nil, { a &&= 1 } call, a"))).to eq(nil)
      expect(subject.evaluate(seq("a = 1, { a &&= 2 } call, a"))).to eq(2)
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

    it "implements ||=" do
      expect(subject.evaluate(seq("a = nil, { a ||= 1 } call, a"))).to eq(1)
      expect(subject.evaluate(seq("a = 1, { a ||= 2 } call, a"))).to eq(1)
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

  describe "!x" do
    context "when x is truthy" do
      it "returns false" do
        expect(subject.evaluate(ast("!true"))).to eq(false)
        expect(subject.evaluate(ast("!42"))).to eq(false)
      end
    end

    context "when x is falsy" do
      it "returns true" do
        expect(subject.evaluate(ast("!false"))).to eq(true)
        expect(subject.evaluate(ast("!nil"))).to eq(true)
      end
    end
  end

  describe "return" do
    it "performs local return" do
      expect(subject.evaluate(ast("
        {
          return(1 + { return(2), 42 } call)
          42
        } call
      "))).to eq(3)
    end
  end

  describe "ensuring" do
    it "evaluates the block in the happy path, returning the original value" do
      expect(subject.evaluate(seq("
        a = 0
        val = (true ensuring: a += 1)
        [a, val]
      "))).to eq([1, true])
    end

    it "evaluates the block in the sad path, reraising the exception" do
      a = []

      expect {
        subject.evaluate(seq("
          do {
            a << .a,
            raise(\"hell\")
            a << .b
          } ensuring:
            a << .c
        "))
      }.to raise_error("hell")

      expect(a).to eq([:a, :c])
    end
  end

  describe "super" do
    context "with no arguments" do
      it "calls the parent method with no arguments" do
        parent = Class.new
        child = Class.new(parent)

        subject.evaluate(seq("
          parent open:
            def(foo(*args)): args

          child open:
            def(foo(*args)): super
        "))

        expect(child.new.foo(1, 2, 3)).to eq([])
      end
    end

    context "with arguments" do
      it "calls the parent method with the given arguments" do
        parent = Class.new
        child = Class.new(parent)

        subject.evaluate(seq("
          parent open:
            def(foo(*args)): args

          child open:
            def(foo(*args)): super(1, 2)
        "))

        expect(child.new.foo(42)).to eq([1, 2])
      end

      context "and a block" do
        it "calls the parent method with the given arguments and block" do
          parent = Class.new
          child = Class.new(parent)

          subject.evaluate(seq("
            parent open:
              def(foo(*args) &blk): [args, blk]

            child open:
              def(foo(*args)): super(1, 2) { .called }
          "))

          args, blk = child.new.foo(42)
          expect(args).to eq([1, 2])
          expect(blk.call).to eq(:called)
        end

        context "with arguments" do
          it "calls the parent method with the given arguments and block" do
            parent = Class.new
            child = Class.new(parent)

            subject.evaluate(seq("
              parent open:
                def(foo(*args) &blk): [args, blk]

              child open:
                def(foo(*args)): super(1, 2) [a, b] { a + b }
            "))

            args, blk = child.new.foo(42)
            expect(args).to eq([1, 2])
            expect(blk.call(3, 4)).to eq(7)
          end
        end
      end

      context "and a proc argument" do
        it "calls the parent method with the given arguments and proc argument" do
          parent = Class.new
          child = Class.new(parent)

          subject.evaluate(seq("
            parent open:
              def(foo(*args) &blk): [args, blk]

            child open:
              def(foo(*args) &blk): super(1, 2) &blk
          "))

          args, blk = child.new.foo(42) { :called_original }
          expect(args).to eq([1, 2])
          expect(blk.call).to eq(:called_original)
        end
      end
    end

    context "and a block" do
      it "calls the parent method with the given arguments and block" do
        parent = Class.new
        child = Class.new(parent)

        subject.evaluate(seq("
          parent open:
            def(foo(*args) &blk): [args, blk]

          child open:
            def(foo(*args)): super { .called }
         "))

        args, blk = child.new.foo(42)
        expect(args).to be_empty
        expect(blk.call).to eq(:called)
      end

      context "with arguments" do
        it "calls the parent method with the given arguments and block" do
          parent = Class.new
          child = Class.new(parent)

          subject.evaluate(seq("
            parent open:
              def(foo(*args) &blk): [args, blk]

            child open:
              def(foo(*args)): super [a, b] { a + b }
          "))

          args, blk = child.new.foo(42)
          expect(args).to be_empty
          expect(blk.call(3, 4)).to eq(7)
        end
      end
    end

    context "and a proc argument" do
      it "calls the parent method with the given arguments and proc argument" do
        parent = Class.new
        child = Class.new(parent)

        subject.evaluate(seq("
          parent open:
            def(foo(*args) &blk): [args, blk]

          child open:
            def(foo(*args) &blk): super &blk
         "))

        args, blk = child.new.foo(42) { :called_original }
        expect(args).to be_empty
        expect(blk.call).to eq(:called_original)
      end
    end
  end

  describe "break" do
    it "breaks the outer loop, returning nil if no argument is given" do
      as = []
      expect(subject.evaluate(seq(<<EOF))).to eq(nil)
[1, 2, 3] collect [a]:
  as << a

  when(a == 2):
    break

  a
EOF
      expect(as).to eq([1, 2])
    end

    it "breaks the outer loop, returning the given value" do
      as = []
      expect(subject.evaluate(seq(<<EOF))).to eq(42)
[1, 2, 3] collect [a]:
  as << a

  when(a == 2):
    break(42)

  a
EOF
      expect(as).to eq([1, 2])
    end
  end

  describe "next" do
    it "returns nil from the innermost block" do
      as = []
      expect(subject.evaluate(seq(<<EOF))).to eq([1, nil, 3])
[1, 2, 3] collect [a]:
  when(a == 2):
    next

  a
EOF
    end

    it "returns the given value from the innermost block" do
      expect(subject.evaluate(seq(<<EOF))).to eq([1, 42, 3])
[1, 2, 3] collect [a]:
  when(a == 2):
    next(42)

  a
EOF
    end
  end

  describe "condition" do
    it "evaluates the first branch whose condition is true" do
      checked = []

      failed = proc { |x|
        checked << x
        false
      }

      succeeded = proc { |x|
        checked << x
        true
      }

      expect(subject.evaluate(seq(<<EOF))).to eq(:third)
condition:
  failed[.first]: .first
  failed[.second]: .second
  succeeded[.third]: .third
  failed[.fourth]: raise("def not evaluated")
EOF

      expect(checked).to eq([:first, :second, :third])
    end

    it "evaluates branches with 'otherwise' mapped to 'true'" do
      expect(subject.evaluate(seq(<<EOF))).to eq(:third)
condition:
  false: .first
  false: .second
  otherwise: .third
  otherwise: .fourth
EOF
    end

    it "returns nil if no branches match" do
      expect(subject.evaluate(seq(<<EOF))).to eq(nil)
condition:
  false: .first
  false: .second
  false: .third
  false: .fourth
EOF
    end
  end
end

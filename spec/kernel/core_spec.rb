require "spec_helper"

require "atomy/codeloader"

module ABC; end

describe "core kernel" do
  subject { Atomy::Module.new { use(require_kernel("core")) } }

  it "implements do: notation for evaluating sequences" do
    expect(subject).to receive(:foo).and_return(1)
    expect(subject).to receive(:bar).and_return(2)
    expect(subject.evaluate(ast("do: foo, bar"), subject.compile_context)).to eq(2)
  end

  describe "macro defining" do
    it "implements a macro-defining macro" do
      subject.evaluate(ast("macro(1): '2"), subject.compile_context)
      expect(subject.evaluate(ast("1"))).to eq(2)
    end

    it "closes over its scope" do
      subject.evaluate(seq("a = '2, macro(1): a"), subject.compile_context)
      expect(subject.evaluate(ast("1"))).to eq(2)
    end
  end

  it "implements sending messages to self" do
    bnd = 1.instance_eval { binding }
    expect(subject.evaluate(ast("inspect"), bnd)).to eq("1")
  end

  it "implements sending messages to self, with arguments" do
    bnd = 128.instance_eval { binding }
    expect(subject.evaluate(ast("to-s(16)"), bnd)).to eq("80")
  end

  it "implements sending messages to self, with blocks" do
    bnd = [1, 2, 3].instance_eval { binding }
    expect(subject.evaluate(ast("collect: 1"), bnd)).to eq([1, 1, 1])
  end

  it "implements sending messages to self, with blocks with argumennts" do
    bnd = [1, 2, 3].instance_eval { binding }
    expect(subject.evaluate(ast("collect [x]: x + 1"), bnd)).to eq([2, 3, 4])
  end

  it "implements sending messages to self, with arguments and blocks" do
    bnd = [1, 2, 3].instance_eval { binding }
    expect(subject.evaluate(ast("fetch(3): 42"), bnd)).to eq(42)
  end

  it "implements sending messages to self, with arguments and blocks with arguments" do
    bnd = [1, 2, 3].instance_eval { binding }
    expect(subject.evaluate(ast("inject(3) [a, b]: a + b"), bnd)).to eq(9)
  end

  it "implements sending messages to self with ! at the end of the name" do
    foo = Object.new
    bnd = foo.instance_eval { binding }
    expect(foo).to receive(:bar!).and_return(42)
    expect(subject.evaluate(ast("bar!"), bnd)).to eq(42)
  end

  it "implements sending messages to self with ? at the end of the name" do
    foo = Object.new
    bnd = foo.instance_eval { binding }
    expect(foo).to receive(:bar?).and_return(42)
    expect(subject.evaluate(ast("bar?"), bnd)).to eq(42)
  end

  it "implements sending messages to self with ! at the end of the name, with arguments" do
    foo = Object.new
    bnd = foo.instance_eval { binding }
    expect(foo).to receive(:bar!).with(1, 2).and_return(42)
    expect(subject.evaluate(ast("bar!(1, 2)"), bnd)).to eq(42)
  end

  it "implements sending messages to self with ? at the end of the name, with arguments" do
    foo = Object.new
    bnd = foo.instance_eval { binding }
    expect(foo).to receive(:bar?).with(1, 2).and_return(42)
    expect(subject.evaluate(ast("bar?(1, 2)"), bnd)).to eq(42)
  end

  it "implements sending messages to self with ! at the end of the name, with a block that has no arguments" do
    foo = Object.new
    bnd = foo.instance_eval { binding }

    block = proc{}
    expect(foo).to receive(:bar!) { |&blk|
      blk.call + 1
    }

    expect(subject.evaluate(ast("bar!: 41"), bnd)).to eq(42)
  end

  it "implements sending messages to self with ? at the end of the name, with a block that has no arguments" do
    foo = Object.new
    bnd = foo.instance_eval { binding }

    block = proc{}
    expect(foo).to receive(:bar?) { |&blk|
      blk.call + 1
    }

    expect(subject.evaluate(ast("bar?: 41"), bnd)).to eq(42)
  end

  it "implements sending messages to self with ! at the end of the name, with a block that has arguments" do
    foo = Object.new
    bnd = foo.instance_eval { binding }

    block = proc{}
    expect(foo).to receive(:bar!) { |&blk|
      blk.call(40, 1) + 1
    }

    expect(subject.evaluate(ast("bar! [a, b]: a + b"), bnd)).to eq(42)
  end

  it "implements sending messages to self with ? at the end of the name, with a block that has arguments" do
    foo = Object.new
    bnd = foo.instance_eval { binding }

    block = proc{}
    expect(foo).to receive(:bar?) { |&blk|
      blk.call(40, 1) + 1
    }

    expect(subject.evaluate(ast("bar? [a, b]: a + b"), bnd)).to eq(42)
  end

  it "implements sending messages to self with ! at the end of the name, with arguments and a block that has no arguments" do
    foo = Object.new
    bnd = foo.instance_eval { binding }

    block = proc{}
    expect(foo).to receive(:bar!).with(1, 2) { |&blk|
      blk.call + 1
    }

    expect(subject.evaluate(ast("bar!(1, 2): 41"), bnd)).to eq(42)
  end

  it "implements sending messages to self with ? at the end of the name, with arguments and a block that has no arguments" do
    foo = Object.new
    bnd = foo.instance_eval { binding }

    block = proc{}
    expect(foo).to receive(:bar?).with(1, 2) { |&blk|
      blk.call + 1
    }

    expect(subject.evaluate(ast("bar?(1, 2): 41"), bnd)).to eq(42)
  end

  it "implements sending messages to self with ! at the end of the name, with arguments and a block that has arguments" do
    foo = Object.new
    bnd = foo.instance_eval { binding }

    block = proc{}
    expect(foo).to receive(:bar!).with(1, 2) { |&blk|
      blk.call(40, 1) + 1
    }

    expect(subject.evaluate(ast("bar!(1, 2) [a, b]: a + b"), bnd)).to eq(42)
  end

  it "implements sending messages to self with ? at the end of the name, with arguments and a block that has arguments" do
    foo = Object.new
    bnd = foo.instance_eval { binding }

    block = proc{}
    expect(foo).to receive(:bar?).with(1, 2) { |&blk|
      blk.call(40, 1) + 1
    }

    expect(subject.evaluate(ast("bar?(1, 2) [a, b]: a + b"), bnd)).to eq(42)
  end

  it "implements sending messages to receivers" do
    expect(subject.evaluate(ast("1 inspect"))).to eq("1")
  end

  it "implements sending messages to receivers, with arguments" do
    expect(subject.evaluate(ast("128 to-s(16)"))).to eq("80")
  end

  it "implements sending messages to receivers, with blocks" do
    expect(subject.evaluate(ast("[1, 2, 3] collect: 1"))).to eq([1, 1, 1])
  end

  it "implements sending messages to receivers, with blocks with argumennts" do
    expect(subject.evaluate(ast("[1, 2, 3] collect [x]: x + 1"))).to eq([2, 3, 4])
  end

  it "implements sending messages to receivers, with arguments and blocks" do
    expect(subject.evaluate(ast("[1, 2, 3] fetch(3): 42"))).to eq(42)
  end

  it "implements sending messages to receivers, with arguments and blocks with arguments" do
    expect(subject.evaluate(ast("[1, 2, 3] inject(3) [a, b]: a + b"))).to eq(9)
  end

  it "implements sending messages to receivers with ! at the end of the name" do
    foo = Object.new
    expect(foo).to receive(:bar!).and_return(42)
    expect(subject.evaluate(ast("foo bar!"))).to eq(42)
  end

  it "implements sending messages to receivers with ? at the end of the name" do
    foo = Object.new
    expect(foo).to receive(:bar?).and_return(42)
    expect(subject.evaluate(ast("foo bar?"))).to eq(42)
  end

  it "implements sending messages to receivers with ! at the end of the name, with arguments" do
    foo = Object.new
    expect(foo).to receive(:bar!).with(1, 2).and_return(42)
    expect(subject.evaluate(ast("foo bar!(1, 2)"))).to eq(42)
  end

  it "implements sending messages to receivers with ? at the end of the name, with arguments" do
    foo = Object.new
    expect(foo).to receive(:bar?).with(1, 2).and_return(42)
    expect(subject.evaluate(ast("foo bar?(1, 2)"))).to eq(42)
  end

  it "implements sending messages to receivers with ! at the end of the name, with a block that has no arguments" do
    foo = Object.new

    block = proc{}
    expect(foo).to receive(:bar!) { |&blk|
      blk.call + 1
    }

    expect(subject.evaluate(ast("foo bar!: 41"))).to eq(42)
  end

  it "implements sending messages to receivers with ? at the end of the name, with a block that has no arguments" do
    foo = Object.new

    block = proc{}
    expect(foo).to receive(:bar?) { |&blk|
      blk.call + 1
    }

    expect(subject.evaluate(ast("foo bar?: 41"))).to eq(42)
  end

  it "implements sending messages to receivers with ! at the end of the name, with a block that has arguments" do
    foo = Object.new

    block = proc{}
    expect(foo).to receive(:bar!) { |&blk|
      blk.call(40, 1) + 1
    }

    expect(subject.evaluate(ast("foo bar! [a, b]: a + b"))).to eq(42)
  end

  it "implements sending messages to receivers with ? at the end of the name, with a block that has arguments" do
    foo = Object.new

    block = proc{}
    expect(foo).to receive(:bar?) { |&blk|
      blk.call(40, 1) + 1
    }

    expect(subject.evaluate(ast("foo bar? [a, b]: a + b"))).to eq(42)
  end

  it "implements sending messages to receivers with ! at the end of the name, with arguments and a block that has no arguments" do
    foo = Object.new

    block = proc{}
    expect(foo).to receive(:bar!).with(1, 2) { |&blk|
      blk.call + 1
    }

    expect(subject.evaluate(ast("foo bar!(1, 2): 41"))).to eq(42)
  end

  it "implements sending messages to receivers with ? at the end of the name, with arguments and a block that has no arguments" do
    foo = Object.new

    block = proc{}
    expect(foo).to receive(:bar?).with(1, 2) { |&blk|
      blk.call + 1
    }

    expect(subject.evaluate(ast("foo bar?(1, 2): 41"))).to eq(42)
  end

  it "implements sending messages to receivers with ! at the end of the name, with arguments and a block that has arguments" do
    foo = Object.new

    block = proc{}
    expect(foo).to receive(:bar!).with(1, 2) { |&blk|
      blk.call(40, 1) + 1
    }

    expect(subject.evaluate(ast("foo bar!(1, 2) [a, b]: a + b"))).to eq(42)
  end

  it "implements sending messages to receivers with ? at the end of the name, with arguments and a block that has arguments" do
    foo = Object.new

    block = proc{}
    expect(foo).to receive(:bar?).with(1, 2) { |&blk|
      blk.call(40, 1) + 1
    }

    expect(subject.evaluate(ast("foo bar?(1, 2) [a, b]: a + b"))).to eq(42)
  end

  it "implements sending #[]" do
    expect(subject.evaluate(ast("[1, 2, 3, 4, 5] [1, 2]"))).to eq([2, 3])
  end

  it "implements nested constant notation" do
    expect(subject.evaluate(ast("Atomy Module"))).to eq(Atomy::Module)
  end

  it "implements boolean literals" do
    expect(subject.evaluate(ast("false"))).to eq(false)
    expect(subject.evaluate(ast("true"))).to eq(true)
  end

  it "implements nil literals" do
    expect(subject.evaluate(ast("nil"))).to eq(nil)
  end

  it "implements symbol literals for words" do
    expect(subject.evaluate(ast(".to-s"))).to eq(:to_s)
  end

  it "implements symbol literals for constants" do
    expect(subject.evaluate(ast(".String"))).to eq(:String)
  end

  describe "assignment" do
    context "with =" do
      it "implements local variable assignment notation" do
        expect(subject.evaluate(seq("a = 1, a + 2"))).to eq(3)
      end

      it "assigns variables spanning evals" do
        expect(subject.evaluate(seq("a = 1"))).to eq(1)
        expect(subject.evaluate(seq("a + 2"))).to eq(3)
      end

      it "raises an error when the patterns don't match" do
        expect {
          subject.evaluate(ast("2 = 1"))
        }.to raise_error(Atomy::PatternMismatch)
      end

      it "assigns only in the innermost scope" do
        expect(subject.evaluate(seq("
          a = 1
          b = { a = 2, a } call
          [a, b]
        "))).to eq([1, 2])
      end

      it "does not zero-out already-existing values during assignment" do
        expect(subject.evaluate(seq("
          a = 1
          a = (a + 1)
          a
        "))).to eq(2)
      end

      it "does not zero-out already-existing values during assignment in a nested scope" do
        expect(subject.evaluate(seq("
          a = 1
          b = { a = (a + 1) } call
          [a, b]
        "))).to eq([1, 2])
      end
    end

    context "with =!" do
      it "implements local variable assignment notation" do
        expect(subject.evaluate(seq("a =! 1, a + 2"))).to eq(3)
      end

      it "assigns variables spanning evals" do
        expect(subject.evaluate(seq("a =! 1"))).to eq(1)
        expect(subject.evaluate(seq("a + 2"))).to eq(3)
      end

      it "raises an error when the patterns don't match" do
        expect {
          subject.evaluate(ast("2 =! 1"))
        }.to raise_error(Atomy::PatternMismatch)
      end

      it "overrides existing locals if possible" do
        expect(subject.evaluate(seq("
          a = 1
          b = { a =! 2, a } call
          [a, b]
        "))).to eq([2, 2])
      end

      it "does not zero-out already-existing values during assignment" do
        expect(subject.evaluate(seq("
          a = 1
          a =! (a + 1)
          { a =! (a + 1) } call
          a
        "))).to eq(3)
      end
    end
  end

  describe "blocks" do
    it "implements block literals" do
      blk = subject.evaluate(ast("{ 1 + 2 }"))
      expect(blk).to be_kind_of(Proc)
      expect(blk.call).to eq(3)
    end

    it "implements block literals with arguments" do
      blk = subject.evaluate(ast("[a, b]: a + b"))
      expect(blk).to be_kind_of(Proc)
      expect(blk.call(1, 2)).to eq(3)
    end

    it "constructs blocks that close over their scope" do
      blk = subject.evaluate(seq("a = 1, [b]: a + b"))
      expect(blk).to be_kind_of(Proc)
      expect(blk.call(2)).to eq(3)
    end

    it "pattern-matches block arguments" do
      blk = subject.evaluate(seq("[a, `(1 + ~b)]: [a, b value]"))
      expect(blk).to be_kind_of(Proc)
      expect(blk.call(1, ast("1 + 2"))).to eq([1, 2])
    end
  end

  it "implements toplevel constant access" do
    Thread.current[:binding] = nil

    module XYZ
      module ABC
      end

      Thread.current[:binding] = binding
    end

    bnd = Thread.current[:binding]

    expect(subject.evaluate(ast("//ABC"), bnd)).to eq(::ABC)
  end
end

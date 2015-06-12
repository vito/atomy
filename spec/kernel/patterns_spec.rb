require "spec_helper"

require "atomy/codeloader"
require "atomy/pattern/attribute"
require "atomy/pattern/instance_variable"
require "atomy/pattern/or"
require "atomy/node/equality"

module PatternsKernelModule
  class Blah
  end
end

describe "patterns kernel" do
  subject { Atomy::Module.new { use(require("patterns")) } }

  it "defines a pattern for nested consts" do
    expect(subject.evaluate(ast("PatternsKernelModule Blah = PatternsKernelModule Blah new"))).to be_a(PatternsKernelModule::Blah)
    expect { subject.evaluate(ast("PatternsKernelModule Blah = Object new")) }.to raise_error(Atomy::PatternMismatch)
  end

  it "defines a pattern for assigning object attributes" do
    klass = Class.new { attr_accessor :y }
    x = klass.new
    expect(subject.evaluate(ast("x y = 1"))).to eq(1)
    expect(x.y).to eq(1)
  end

  it "defines a pattern for assigning indices" do
    x = [1, 2, 3, 4]
    expect(subject.evaluate(ast("x [1, 2] = 42"))).to eq(42)
    expect(x).to eq([1, 42, 4])
  end

  it "defines a pattern for setting instance variables" do
    expect(subject.evaluate(ast("@foo = 42"))).to eq(42)
    expect(@foo).to eq(42)
  end

  it "defines a pattern for setting instance variables ending in ?" do
    expect(subject.evaluate(ast("@foo? = 42"))).to eq(42)
    expect(instance_variable_get(:"@foo?")).to eq(42)
  end

  it "defines a pattern for setting instance variables ending in !" do
    expect(subject.evaluate(ast("@foo! = 42"))).to eq(42)
    expect(instance_variable_get(:"@foo!")).to eq(42)
  end

  it "defines a pattern for setting global variables" do
    expect(subject.evaluate(ast("$foo = 42"))).to eq(42)
    expect($foo).to eq(42)
  end

  it "defines a pattern for matching nil" do
    expect(subject.evaluate(ast("nil = nil"))).to eq(nil)
    expect { subject.evaluate(ast("nil = 42")) }.to raise_error(Atomy::PatternMismatch)
  end

  it "defines a pattern for matching true" do
    expect(subject.evaluate(ast("true = true"))).to eq(true)
    expect { subject.evaluate(ast("true = 42")) }.to raise_error(Atomy::PatternMismatch)
  end

  it "defines a pattern for matching false" do
    expect(subject.evaluate(ast("false = false"))).to eq(false)
    expect { subject.evaluate(ast("false = 42")) }.to raise_error(Atomy::PatternMismatch)
  end

  it "defines an or pattern" do
    expect(subject.evaluate(seq("((a & 1) | (b & 2)) = 1, [a, b]"))).to eq([1, nil])
    expect(subject.evaluate(seq("((c & 1) | (d & 2)) = 2, [c, d]"))).to eq([nil, 2])
    expect { subject.evaluate(ast("((c & 1) | (d & 2)) = 3")) }.to raise_error(Atomy::PatternMismatch)
  end

  it "defines a 'with' pattern for matching evaluations on an object" do
    klass = Class.new { attr_accessor :foo }
    x = klass.new

    x.foo = 1
    expect(subject.evaluate(seq("with(@foo, a) = x, a"))).to eq(1)

    x.foo = 2
    expect(subject.evaluate(seq("with(@foo, a & 2) = x, a"))).to eq(2)

    x.foo = 3
    expect { subject.evaluate(seq("with(@foo, a & 2) = x, a")) }.to raise_error(Atomy::PatternMismatch)
  end

  describe "predicate patterns" do
    it "defines a block pattern for evaluating a boolean expression on the value" do
      klass = Class.new { attr_accessor :foo }
      x = klass.new

      x.foo = 1
      subject.evaluate(seq("{ @foo == 1 } = x"))

      x.foo = 2
      expect { subject.evaluate(seq("{ @foo == 1 } = x")) }.to raise_error(Atomy::PatternMismatch)
    end

    it "defines on Object when the target of a definition" do
      subject.evaluate(seq("def({ even? } whoa-even?): true"))
      subject.evaluate(seq("def({ odd? } whoa-even?): false"))
      subject.evaluate(seq("def({ maybe_even? } whoa-even?): .maybe"))

      expect(1.whoa_even?).to eq(false)
      expect(2.whoa_even?).to eq(true)

      maybe_even = double(:even? => false, :odd? => false, :maybe_even? => true)
      expect(maybe_even.whoa_even?).to eq(:maybe)
    end
  end

  describe "list patterns" do
    it "succeeds in a basic equality case" do
      expect(subject.evaluate(ast("[1, 2, 3] = [1, 2, 3]"))).to eq([1, 2, 3])
    end

    it "binds locals" do
      expect(subject.evaluate(seq("[a, 2, b] = [1, 2, 3], [a, b]"))).to eq([1, 3])
    end

    it "does not match if the other array is too long" do
      expect {
        subject.evaluate(ast("[1, 2, 3] = [1, 2, 3, 4]"))
      }.to raise_error(Atomy::PatternMismatch)
    end

    it "does not match if the other array is too short" do
      expect {
        subject.evaluate(ast("[1, 2, 3] = [1, 2]"))
      }.to raise_error(Atomy::PatternMismatch)
    end

    it "does not match if the sub-patterns do not match" do
      expect {
        subject.evaluate(ast("[1, 2, 3] = [1, 2, 4]"))
      }.to raise_error(Atomy::PatternMismatch)
    end

    context "with splats" do
      it "matches the rest of the list via a splat" do
        expect(subject.evaluate(seq("[a, *bs] = [1, 2, 3], [a, bs]"))).to eq([1, [2, 3]])
      end

      it "matches when the rest is empty" do
        expect(subject.evaluate(seq("[a, *bs] = [1], [a, bs]"))).to eq([1, []])
      end

      it "does not match if the array does not fit the minimum length" do
        expect {
          subject.evaluate(seq("[a, b, *cs] = [1]"))
        }.to raise_error(Atomy::PatternMismatch)
      end

      it "does not match if the splat pattern does not match" do
        expect {
          subject.evaluate(seq("[a, *[3]] = [1, 2]"))
        }.to raise_error(Atomy::PatternMismatch)
      end

      it "binds locals from the splat" do
        expect(subject.evaluate(seq("[a, *[2, b]] = [1, 2, 3], [a, b]"))).to eq([1, 3])
      end
    end
  end

  describe "match" do
    it "evaluates whichever branch matches the value" do
      expect(subject.evaluate(ast("
        1 match:
          1: .one
          2: .two
      "))).to eq(:one)
    end

    it "captures locals from the pattern" do
      expect(subject.evaluate(ast("
        '(1 + 2) match:
          `(~a + ~b): [a, b]
      "))).to eq([ast("1"), ast("2")])
    end

    it "shadows locals" do
      expect(subject.evaluate(seq("
        a = 1
        '(1 + 2) match:
          `(~a + ~b): [a, b]
        a
      "))).to eq(1)
    end

    context "when no branches match" do
      it "returns nil" do
        expect(subject.evaluate(ast("
          1 match:
            2: .two
        "))).to be_nil
      end
    end
  end

  describe "rescue" do
    context "when no exception is raised" do
      it "returns the result, having not evaluated any branches" do
        expect(subject.evaluate(seq("
          a = 0
          val = (true rescue: _: a += 1)
          [a, val]
        "))).to eq([0, true])
      end
    end

    context "when an exception is raised" do
      it "evaluates the branch matching the exception, returning its value" do
        expect(subject.evaluate(seq("
          a = 0
          val = (raise(\"hell\") rescue: _: a += 1, .ok)
          [a, val]
        "))).to eq([1, :ok])
      end

      context "when no branches match" do
        it "reraises the exception" do
          expect {
            subject.evaluate(seq("
              a = 0
              val = (raise(\"hell\") rescue: NoMethodError: a += 1, .ok)
              [a, val]
            "))
          }.to raise_error("hell")
        end
      end
    end
  end
end

require "spec_helper"

require "atomy/codeloader"
require "atomy/pattern/attribute"
require "atomy/pattern/instance_variable"
require "atomy/pattern/or"

module PatternsKernelModule
  class Blah
  end
end

describe "patterns kernel" do
  subject { Atomy::Module.new { use(require_kernel("patterns")) } }

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
end

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
end

require "spec_helper"

require "atomy/codeloader"

describe "dynamic kernel" do
  subject { Atomy::Module.new { use(require("dynamic")) } }

  it "implements dynamic variable literals, defaulting to undefined" do
    var = subject.evaluate(ast("dynamic"), subject.compile_context)
    expect(var).to be_a(subject::Dynvar)
    expect(var.send(:"^@") == undefined).to eq(true)
  end

  describe "Dynvar" do
    let(:var) { subject.evaluate(ast("dynamic(.default)"), subject.compile_context) }

    it "defaults to the given value" do
      expect(var.send(:"^@")).to eq(:default)
    end

    it "stores and retrieves the value" do
      expect(var.send(:"^@")).to eq(:default)
      expect(var.get == undefined).to eq(true)
      var.set(42)
      expect(var.send(:"^@")).to eq(42)
      expect(var.get).to eq(42)
    end

    it "can be temporarily overridden with with(bindings): body" do
      expect(subject.evaluate(seq("x = with(var = 42) { ^var }, [x, ^var]"))).to eq([42, :default])
    end

    it "does not restore the value to the default, but rather leaves it undefined" do
      expect(subject.evaluate(seq("x = with(var = 42) { ^var }, [x, ^var]"))).to eq([42, :default])
      expect(var.send(:"^@")).to eq(:default)
      expect(var.get == undefined).to eq(true)
    end

    it "restores the original values in the event of an exception" do
      expect { subject.evaluate(seq("with(var = 42) { raise(\"hell\") }")) }.to raise_error("hell")
      expect(var.send(:"^@")).to eq(:default)

      var.set(42)
      expect { subject.evaluate(seq("with(var = 42) { raise(\"hell\") }")) }.to raise_error("hell")
      expect(var.send(:"^@")).to eq(42)
    end
  end
end

require "spec_helper"

require "atomy/module"

describe Atomy::Module do
  describe "#expand" do
    context "when an expansion rule matched" do
      it "returns the expanded node"
    end

    context "when NO expansion rule matched" do
      it "returns the original node"
    end
  end

  describe "#evaluate" do
    it "compiles the given expression"
    it "executes the compiled code"
    it "executes with the module as 'self'"
  end

  describe "#compile" do
    let(:apply) { ast("foo(1)") }
    let(:generator) { mock }
    let(:expansion) { mock }

    it "expands the node and compiles the expansion" do
      # TODO: less stubby
      subject.should_receive(:expand).with(apply) do
        expansion
      end

      expansion.should_receive(:bytecode).with(generator, subject)

      subject.compile(generator, apply)
    end
  end
end

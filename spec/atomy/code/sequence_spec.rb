require "spec_helper"

require "atomy/bootstrap"
require "atomy/module"
require "atomy/code/sequence"

describe Atomy::Code::Sequence do
  let(:compile_module) do
    Atomy::Module.new do
      use Atomy::Bootstrap
    end
  end

  subject { described_class.new(nodes) }

  context "with no nodes" do
    let(:nodes) { [] }

    it_compiles_as do |gen|
      gen.push_nil
    end
  end

  context "with one node" do
    let(:nodes) { [ast('"foo"')] }

    it_compiles_as do |gen|
      gen.push_literal "foo"
      gen.string_dup
    end
  end

  context "with more than one node" do
    let(:nodes) { [ast('"foo"'), ast('"bar"')] }

    it_compiles_as do |gen|
      gen.push_literal "foo"
      gen.string_dup
      gen.pop
      gen.push_literal "bar"
      gen.string_dup
    end
  end
end

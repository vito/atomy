require "spec_helper"

require "atomy/bootstrap"
require "atomy/module"
require "atomy/code/send"

describe Atomy::Code::Send do
  let(:receiver) { nil }
  let(:name) { :foo }
  let(:arguments) { [] }

  let(:compile_module) do
    Atomy::Module.new do
      use Atomy::Bootstrap
    end
  end

  subject { described_class.new(receiver, name, arguments) }

  context "with a receiver" do
    let(:receiver) { ast('"foo"') }

    it_compiles_as do |gen|
      gen.push_literal "foo"
      gen.string_dup
      gen.send :foo, 0
    end

    context "and arguments" do
      let(:arguments) { [ast('"bar"'), ast('"baz"')] }

      it_compiles_as do |gen|
        gen.push_literal "foo"
        gen.string_dup
        gen.push_literal "bar"
        gen.string_dup
        gen.push_literal "baz"
        gen.string_dup
        gen.send :foo, 2
      end
    end
  end

  context "with no receiver" do
    it_compiles_as do |gen|
      gen.push_self
      gen.allow_private
      gen.send :foo, 0
    end

    context "with arguments" do
      let(:arguments) { [ast('"foo"'), ast('"bar"')] }

      it_compiles_as do |gen|
        gen.push_self
        gen.push_literal "foo"
        gen.string_dup
        gen.push_literal "bar"
        gen.string_dup
        gen.allow_private
        gen.send :foo, 2
      end
    end
  end
end

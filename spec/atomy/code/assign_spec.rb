require "spec_helper"

require "atomy/code/assign"

describe Atomy::Code::Assign do
  let(:compile_module) { Atomy::Module.new { use Atomy::Bootstrap } }

  subject { described_class.new(pattern, value) }

  context "with a wildcard matcher" do
    context "with bindings" do
      let(:pattern) { ast("a") }
      let(:value) { ast("1") }

      it_compiles_as do |gen|
        gen.push_int 1
        gen.set_local 0
      end
    end

    context "with no bindings" do
      let(:pattern) { ast("_") }
      let(:value) { ast("1") }

      it_compiles_as do |gen|
        gen.push_int 1
      end
    end
  end

  context "with a matcher than can mismatch" do
    let(:pattern) { ast("1") }
    let(:value) { ast("1") }

    it_compiles_as do |gen|
      mismatch = gen.new_label
      done = gen.new_label

      gen.push_int(1)
      gen.dup
      gen.push_int(1)
      gen.send(:==, 1)
      gen.gif(mismatch)

      gen.goto(done)

      mismatch.set!
      gen.dup
      gen.push_cpath_top
      gen.find_const(:Atomy)
      gen.find_const(:PatternMismatch)
      gen.swap
      gen.push_cpath_top
      gen.find_const(:Atomy)
      gen.find_const(:Grammar)
      gen.find_const(:AST)
      gen.find_const(:Number)
      gen.push_int(1)
      gen.send(:new, 1)
      gen.swap
      gen.send(:new, 2)
      gen.raise_exc

      done.set!
    end
  end
end

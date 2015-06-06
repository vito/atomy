require "spec_helper"

require "atomy/bootstrap"
require "atomy/code/quasi_quote"
require "atomy/module"
require "atomy/node/equality"
require "atomy/node/pretty"

describe Atomy::Code::QuasiQuote do
  let(:compile_module) { Atomy::Bootstrap }

  let(:quoted) { ast("[a + b c, ~'42]") }

  let(:eval_binding) { compile_module.compile_context }

  subject { described_class.new(quoted) }

  def eval!
    code = Atomy::Compiler.package(__FILE__.to_sym, __LINE__) do |gen|
      subject.bytecode(gen, compile_module)
    end

    blk = Atomy::Compiler.construct_block(code, eval_binding)

    blk.call
  end

  it "constructs a Node" do
    expect(eval!).to eq(ast("[a + b c, 42]"))
  end

  context "when nested" do
    let(:quoted) { ast("`(1 + ~'~'42)") }

    it "follows through quasiquotes and unquotes" do
      expect(eval!).to eq(ast("`(1 + ~'42)"))
    end
  end

  context "with a splat" do
    let(:quoted) { ast("{ ~*['1, '2, '3] }") }

    it "inlines the nodes into the node" do
      expect(eval!).to eq(ast("{ 1, 2, 3 }"))
    end

    context "with nodes preceding the splat" do
      let(:quoted) { ast("{ 0, ~*['1, '2, '3] }") }

      it "inlines the nodes into the node" do
        expect(eval!).to eq(ast("{ 0, 1, 2, 3 }"))
      end
    end

    context "with nodes following the splat" do
      let(:quoted) { ast("{ ~*['1, '2, '3], 4}") }

      it "inlines the nodes into the node" do
        expect(eval!).to eq(ast("{ 1, 2, 3, 4 }"))
      end
    end

    context "with nodes surrounding the splat" do
      let(:quoted) { ast("{ 0, ~*['1, '2, '3], 4}") }

      it "inlines the nodes into the node" do
        expect(eval!).to eq(ast("{ 0, 1, 2, 3, 4 }"))
      end
    end

    context "when splats and nodes interleaved" do
      let(:quoted) { ast("{ 0, ~*['1, '2, '3], 4, ~*['5, '6], 7}") }

      it "inlines the nodes into the node" do
        expect(eval!).to eq(ast("{ 0, 1, 2, 3, 4, 5, 6, 7 }"))
      end
    end

    context "when splats and nodes interleaved, ending with a splat" do
      let(:quoted) { ast("{ 0, ~*['1, '2, '3], 4, ~*['5, '6], 7, ~*['8, '9]}") }

      it "inlines the nodes into the node" do
        expect(eval!).to eq(ast("{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }"))
      end
    end
  end
end

require "spec_helper"

require "atomy/bootstrap"
require "atomy/code/block"

describe Atomy::Code::Block do
  let(:compile_module) { Atomy::Module.new { use Atomy::Bootstrap } }

  let(:body) { ast("a + b") }
  let(:args) { [ast("a"), ast("b")] }
  let(:proc_argument) { nil }
  let(:lambda_style) { true }

  subject { described_class.new(body, args, proc_argument, lambda_style) }

  it "constructs a Proc with the correct arity" do
    blk = compile_module.evaluate(subject)
    expect(blk).to be_kind_of(Proc)
    expect(blk.arity).to eq(2)
  end

  context "when called with the correct argument count" do
    it "binds arguments as locals and executes the body" do
      expect(compile_module.evaluate(subject).call(1, 2)).to eq(3)
    end
  end

  context "when any argument patterns do not match" do
    let(:args) { [ast("1"), ast("b")] }
    let(:body) { ast("b + 3") }

    it "raises Atomy::PatternMismatch" do
      expect(compile_module.evaluate(subject).call(1, 2)).to eq(5)

      expect {
        compile_module.evaluate(subject).call(2, 2)
      }.to raise_error(Atomy::PatternMismatch)
    end
  end

  context "with lambda-style" do
    let(:lambda_style) { true }

    context "when called with too many arguments" do
      it "ignores the extra ones" do
        expect(compile_module.evaluate(subject).call(1, 2, 3)).to eq(3)
      end
    end

    context "when called with an array argument" do
      let(:body) { ast("as") }
      let(:args) { [ast("as")] }

      it "returns the array argument" do
        expect(compile_module.evaluate(subject).call([1, 2, 3])).to eq([1, 2, 3])
      end
    end

    context "when called with too few arguments" do
      it "raises ArgumentError" do
        expect {
          compile_module.evaluate(subject).call(1)
        }.to raise_error(ArgumentError)
      end
    end
  end

  context "without lambda-style" do
    let(:lambda_style) { false }

    context "when called with too many arguments" do
      it "ignores the extra ones" do
        expect(compile_module.evaluate(subject).call(1, 2, 3)).to eq(3)
      end
    end

    context "when called with an array argument" do
      let(:body) { ast("as") }
      let(:args) { [ast("as")] }

      it "returns the array argument" do
        expect(compile_module.evaluate(subject).call([1, 2, 3])).to eq([1, 2, 3])
      end
    end

    context "when called with too few arguments" do
      let(:body) { ast("[x, y]") }
      let(:args) { [ast("x"), ast("y")] }

      it "passes nil arguments" do
        expect(compile_module.evaluate(subject).call(1)).to eq([1, nil])
      end
    end
  end

  context "with a splat argument" do
    let(:args) { [ast("a"), ast("b"), ast("*cs")] }
    let(:body) { ast("[a, b, cs]") }

    it "constructs a Proc with the correct arity" do
      blk = compile_module.evaluate(subject)
      expect(blk).to be_kind_of(Proc)
      expect(blk.arity).to eq(-3)
    end

    context "when called with the minimal argument count" do
      it "binds the splat as an empty array" do
        expect(compile_module.evaluate(subject).call(1, 2)).to eq([1, 2, []])
      end
    end

    context "when the splat pattern does not match" do
      let(:args) { [ast("a"), ast("b"), ast("*String")] }
      let(:body) { ast("42") }

      it "raises Atomy::PatternMismatch" do
        expect {
          compile_module.evaluate(subject).call(1, 2, 3, 4)
        }.to raise_error(Atomy::PatternMismatch)

        expect {
          compile_module.evaluate(subject).call(1, 2, 4)
        }.to raise_error(Atomy::PatternMismatch)

        expect {
          compile_module.evaluate(subject).call(1, 2)
        }.to raise_error(Atomy::PatternMismatch)
      end
    end

    context "when called with too many arguments" do
      it "collects the extra ones via the splat" do
        expect(compile_module.evaluate(subject).call(1, 2, 3, 4)).to eq([1, 2, [3, 4]])
      end
    end

    context "when called with too few arguments" do
      it "raises ArgumentError" do
        expect {
          compile_module.evaluate(subject).call(1)
        }.to raise_error(ArgumentError)
      end
    end
  end

  context "with only a splat argument" do
    let(:args) { [ast("*cs")] }
    let(:body) { ast("cs") }

    it "constructs a Proc with the correct arity" do
      blk = compile_module.evaluate(subject)
      expect(blk).to be_kind_of(Proc)
      expect(blk.arity).to eq(-1)
    end

    context "when called with no arguments" do
      it "binds the splat as an empty array" do
        expect(compile_module.evaluate(subject).call).to eq([])
      end
    end

    context "when the splat pattern does not match" do
      let(:args) { [ast("*String")] }
      let(:body) { ast("42") }

      it "raises Atomy::PatternMismatch" do
        expect {
          compile_module.evaluate(subject).call(1)
        }.to raise_error(Atomy::PatternMismatch)

        expect {
          compile_module.evaluate(subject).call(1, 2)
        }.to raise_error(Atomy::PatternMismatch)

        expect {
          compile_module.evaluate(subject).call
        }.to raise_error(Atomy::PatternMismatch)
      end
    end

    context "when called with too many arguments" do
      it "collects the extra ones via the splat" do
        expect(compile_module.evaluate(subject).call(1, 2, 3, 4)).to eq([1, 2, 3, 4])
      end
    end
  end
end

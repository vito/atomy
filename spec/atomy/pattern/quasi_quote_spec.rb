require "spec_helper"

require "atomy/bootstrap"
require "atomy/module"
require "atomy/node/equality"
require "atomy/pattern/quasi_quote"

describe Atomy::Pattern::QuasiQuote do
  let(:mod) { Atomy::Bootstrap }

  subject { described_class.make(mod, ast("`foo")) }

  describe "#node" do
    it "returns the quasiquotation being matched" do
      expect(subject.node).to eq(ast("foo"))
    end
  end

  describe "#matches?" do
    describe "basic equality" do
      it { should === ast("foo") }
    end

    describe "with wildcard patterns" do
      subject { described_class.make(mod, ast("`(~a + 1)")) }

      it { should     === ast("1 + 1") }
      it { should     === ast("2 + 1") }
      it { should_not === ast("2 * 1") }
      it { should_not === ast("1 + 2") }
    end

    describe "with non-wildcard patterns" do
      subject { described_class.make(mod, ast("`(~`2 + 1)")) }

      it { should_not === ast("1 + 1") }
      it { should     === ast("2 + 1") }
      it { should_not === ast("2 * 1") }
      it { should_not === ast("1 + 2") }
    end

    describe "matching many subnodes" do
      context "when there are no nodes" do
        subject { described_class.make(mod, ast("`[]")) }

        it { should === ast("[]") }
        it { should_not === ast("[a]") }
      end

      context "when there is one node" do
        subject { described_class.make(mod, ast("`[1]")) }

        it { should_not === ast("[]") }
        it { should_not === ast("[a]") }
        it { should === ast("[1]") }
      end

      context "when there are multiple nodes" do
        subject { described_class.make(mod, ast("`[a, 1, 3.0]")) }

        it { should_not === ast("[]") }
        it { should_not === ast("[a]") }
        it { should_not === ast("[a, 1]") }
        it { should === ast("[a, 1, 3.0]") }
        it { should_not === ast('[a, 1, "foo"]') }
        it { should_not === ast("[a, 1, 3.0, 4]") }
      end

      context "when the only element is a wildcard" do
        subject { described_class.make(mod, ast("`[~_]")) }

        it { should_not === ast("[]") }
        it { should === ast("[a]") }
        it { should_not === ast("[a, 1]") }
      end

      context "when some elements are wildcards" do
        subject { described_class.make(mod, ast("`[a, 1, ~c]")) }

        it { should_not === ast("[]") }
        it { should_not === ast("[a]") }
        it { should_not === ast("[a, 1]") }
        it { should_not === ast("[a, 2, 3.0]") }
        it { should_not === ast("[b, 1, 3.0]") }
        it { should === ast("[a, 1, 3.0]") }
        it { should === ast('[a, 1, "foo"]') }
        it { should_not === ast("[a, 1, 3.0, 4]") }
      end

      context "with splats" do
        context "when there is only a splat" do
          subject { described_class.make(mod, ast("`[~*a]")) }

          it { should === ast("[]") }
          it { should === ast("[1]") }
          it { should === ast("[1, 2]") }
        end

        context "when there are other entries and then a splat" do
          subject { described_class.make(mod, ast("`[1, ~*a]")) }

          it { should === ast("[1]") }
          it { should === ast("[1, 2]") }
          it { should_not === ast("[2]") }
          it { should_not === ast("[2, 1]") }
        end

        context "when they're not at depth 0" do
          subject { described_class.make(mod, ast("``[1, ~*a]")) }

          it { should === ast("`[1, ~*a]") }
          it { should_not === ast("`[1]") }
          it { should_not === ast("`[1, 2]") }
          it { should_not === ast("`[2]") }
          it { should_not === ast("`[2, 1]") }
        end
      end
    end
  end
end

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

  describe "#bindings" do
    context "when there are no bindings" do
      it "returns an empty array" do
        expect(subject.bindings(ast("x"))).to be_empty
      end
    end

    context "when there is a binding" do
      subject { described_class.make(mod, ast("`(1 + ~a)")) }

      it "returns its bound value" do
        expect(subject.bindings(ast("1 + 2"))).to eq([ast("2")])
      end
    end

    context "when there are two bindings" do
      subject { described_class.make(mod, ast("`(~a + ~b)")) }

      it "returns the bound values" do
        expect(subject.bindings(ast("1 + 2"))).to eq([ast("1"), ast("2")])
      end
    end

    context "when there is one binding repeated" do
      subject { described_class.make(mod, ast("`(~a + ~a)")) }

      it "returns all bound values regardless" do
        expect(subject.bindings(ast("1 + 2"))).to eq([ast("1"), ast("2")])
      end
    end

    context "with splats" do
      context "when there is only a splat" do
        subject { described_class.make(mod, ast("`[~*a]")) }

        it "binds the splatted node array" do
          expect(subject.bindings(ast("[1, 2]"))).to eq([[ast("1"), ast("2")]])
        end
      end

      context "when there are other entries and then a splat" do
        subject { described_class.make(mod, ast("`[1, 2, ~*a]")) }

        it "assigns the matched nodes" do
          expect(subject.bindings(ast("[1, 2, 3, 4]"))).to eq([[ast("3"), ast("4")]])
        end
      end

      context "when they're not at depth 0" do
        subject { described_class.make(mod, ast("``[1, ~*a]")) }

        it "returns no bindings" do
          expect(subject.bindings(ast("`[1, ~*a]"))).to be_empty
        end
      end
    end
  end
end

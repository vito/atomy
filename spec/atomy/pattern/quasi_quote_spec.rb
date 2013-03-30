require "spec_helper"

require "atomy/bootstrap"
require "atomy/module"
require "atomy/node/equality"
require "atomy/pattern/quasi_quote"

describe Atomy::Pattern::QuasiQuote do
  let(:mod) { Atomy::Bootstrap }

  subject { described_class.make(mod, ast("foo")) }

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
      subject { described_class.make(mod, ast("~a + 1")) }

      it { should     === ast("1 + 1") }
      it { should     === ast("2 + 1") }
      it { should_not === ast("2 * 1") }
      it { should_not === ast("1 + 2") }
    end

    describe "with non-wildcard patterns" do
      subject { described_class.make(mod, ast("~`2 + 1")) }

      it { should_not === ast("1 + 1") }
      it { should     === ast("2 + 1") }
      it { should_not === ast("2 * 1") }
      it { should_not === ast("1 + 2") }
    end

    describe "matching many subnodes" do
      context "when there are no nodes" do
        subject { described_class.make(mod, ast("[]")) }

        it { should === ast("[]") }
        it { should_not === ast("[a]") }
      end

      context "when there is one node" do
        subject { described_class.make(mod, ast("[1]")) }

        it { should_not === ast("[]") }
        it { should_not === ast("[a]") }
        it { should === ast("[1]") }
      end

      context "when there are multiple nodes" do
        subject { described_class.make(mod, ast("[a, 1, 3.0]")) }

        it { should_not === ast("[]") }
        it { should_not === ast("[a]") }
        it { should_not === ast("[a, 1]") }
        it { should === ast("[a, 1, 3.0]") }
        it { should_not === ast('[a, 1, "foo"]') }
        it { should_not === ast("[a, 1, 3.0, 4]") }
      end

      context "when the only element is a wildcard" do
        subject { described_class.make(mod, ast("[~_]")) }

        it { should_not === ast("[]") }
        it { should === ast("[a]") }
        it { should_not === ast("[a, 1]") }
      end

      context "when some elements are wildcards" do
        subject { described_class.make(mod, ast("[a, 1, ~c]")) }

        it { should_not === ast("[]") }
        it { should_not === ast("[a]") }
        it { should_not === ast("[a, 1]") }
        it { should_not === ast("[a, 2, 3.0]") }
        it { should_not === ast("[b, 1, 3.0]") }
        it { should === ast("[a, 1, 3.0]") }
        it { should === ast('[a, 1, "foo"]') }
        it { should_not === ast("[a, 1, 3.0, 4]") }
      end
    end
  end

  describe "#deconstruct" do
    context "when there are no bindings" do
      it_compiles_as(:deconstruct) {}
    end
  end

  describe "#wildcard?" do
    it "returns false" do
      expect(subject.wildcard?).to eq(false)
    end
  end

  describe "#binds?" do
    context "when any unquoted patterns bind" do
      it "returns true"
    end

    context "when no unquoted patterns bind" do
      it "returns false" do
        expect(subject.binds?).to eq(false)
      end
    end
  end

  describe "#precludes?" do
    context "when the other pattern is an Equality matching a Node" do
      let(:other) { Atomy::Pattern::Equality.new(ast("foo")) }

      context "and it has unquotes" do
        let(:other) { Atomy::Pattern::Equality.new(ast("1 + ~abc")) }
        subject { described_class.make(mod, ast("1 + ~abc")) }

        context "and I have an unquote" do
          it "returns true" do
            expect(subject.precludes?(other)).to eq(true)
          end

          context "and it does NOT preclude the unquote" do
            subject { described_class.make(mod, ast("1 + ~'abc")) }

            it "returns false" do
              expect(subject.precludes?(other)).to eq(false)
            end
          end
        end
      end

      context "and I have unquote patterns" do
        context "and the patterns preclude the respective node" do
          subject { described_class.make(mod, ast("~abc")) }

          it "returns true" do
            expect(subject.precludes?(other)).to eq(true)
          end
        end
          
        context "and the patterns do NOT preclude the respective node" do
          subject { described_class.make(mod, ast("~'bar")) }

          it "returns false" do
            expect(subject.precludes?(other)).to eq(false)
          end
        end
      end

      context "and I have no unquotes" do
        context "and the nodes are equal" do
          subject { described_class.make(mod, ast("~abc")) }

          it "returns true" do
            expect(subject.precludes?(other)).to eq(true)
          end
        end
      end
    end

    context "when the other pattern is a QuasiQuote" do
      context "and it has unquote patterns" do
        let(:other) { described_class.make(mod, ast("~'a + 2")) }

        context "and my pattern precludes the respective node or pattern" do
          subject { described_class.make(mod, ast("~a + 2")) }

          it "returns true" do
            expect(subject.precludes?(other)).to eq(true)
          end

          context "but the rest of the expression differs" do
            subject { described_class.make(mod, ast("~a * 2")) }

            it "returns false" do
              expect(subject.precludes?(other)).to eq(false)
            end
          end
        end
          
        context "and the patterns do NOT preclude the respective node or pattern" do
          subject { described_class.make(mod, ast("~'b + 2")) }

          it "returns false" do
            expect(subject.precludes?(other)).to eq(false)
          end
        end
      end

      context "and it has no unquotes" do
        let(:other) { described_class.make(mod, ast("foo")) }

        context "and I have unquotes" do
          subject { described_class.make(mod, ast("~abc")) }

          it "returns true" do
            expect(subject.precludes?(other)).to eq(true)
          end
        end

        context "and I have no unquotes" do
          subject { described_class.make(mod, ast("foo")) }

          context "and the nodes are equal" do
            it "returns true" do
              expect(subject.precludes?(other)).to eq(true)
            end
          end

          context "and the nodes are not equal" do
            subject { described_class.make(mod, ast("bar")) }

            it "returns false" do
              expect(subject.precludes?(other)).to eq(false)
            end
          end
        end
      end
    end

    context "when the other pattern is something else" do
      it "returns false" do
        expect(subject.precludes?(Object.new)).to eq(false)
      end
    end
  end
end

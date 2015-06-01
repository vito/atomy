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

  describe "#assign" do
    context "when there are no bindings" do
      it "does nothing" do
        a = 1
        subject.assign(Rubinius::VariableScope.current, ast("x"))
        expect(a).to eq(1)
      end
    end

    context "when there is a binding" do
      subject { described_class.make(mod, ast("`(1 + ~a)")) }

      it "assigns locals to their matched bindings" do
        a = nil
        subject.assign(Rubinius::VariableScope.current, ast("1 + 2"))
        expect(a).to eq(ast("2"))
      end
    end

    context "when there are two bindings" do
      subject { described_class.make(mod, ast("`(~a + ~b)")) }

      it "assigns locals to their matched bindings" do
        a = nil
        b = nil
        subject.assign(Rubinius::VariableScope.current, ast("1 + 2"))
        expect(a).to eq(ast("1"))
        expect(b).to eq(ast("2"))
      end
    end

    context "when there is one binding repeated" do
      subject { described_class.make(mod, ast("`(~a + ~a)")) }

      it "assigns in order of occurrence in the tree" do
        a = nil
        subject.assign(Rubinius::VariableScope.current, ast("1 + 2"))
        expect(a).to eq(ast("2"))
      end
    end

    context "with splats" do
      context "when there is only a splat" do
        subject { described_class.make(mod, ast("`[~*a]")) }

        it "assigns the matched nodes" do
          a = nil
          subject.assign(Rubinius::VariableScope.current, ast("[1, 2]"))
          expect(a).to eq([ast("1"), ast("2")])
        end
      end

      context "when there are other entries and then a splat" do
        subject { described_class.make(mod, ast("`[1, 2, ~*a]")) }

        it "assigns the matched nodes" do
          a = nil
          subject.assign(Rubinius::VariableScope.current, ast("[1, 2, 3, 4]"))
          expect(a).to eq([ast("3"), ast("4")])
        end
      end

      context "when they're not at depth 0" do
        subject { described_class.make(mod, ast("``[1, ~*a]")) }

        it "does not assign anything" do
          a = nil
          subject.assign(Rubinius::VariableScope.current, ast("`[1, ~*a]"))
          expect(a).to be_nil
        end
      end
    end
  end

  describe "#locals" do
    context "when any unquoted patterns bind" do
      subject { described_class.make(mod, ast("`[1, ~a]")) }

      it "returns their locals" do
        expect(subject.locals).to eq([:a])
      end
    end

    context "when no unquoted patterns bind" do
      it "returns no locals" do
        expect(subject.locals).to be_empty
      end
    end
  end

  describe "#precludes?" do
    context "when the other pattern is an Equality matching a Node" do
      let(:other) { Atomy::Pattern::Equality.new(ast("foo")) }

      context "and it has unquotes" do
        let(:other) { Atomy::Pattern::Equality.new(ast("1 + ~abc")) }
        subject { described_class.make(mod, ast("`(1 + ~abc)")) }

        context "and I have an unquote" do
          it "returns true" do
            expect(subject.precludes?(other)).to eq(true)
          end

          context "and it does NOT preclude the unquote" do
            subject { described_class.make(mod, ast("`(1 + ~'abc)")) }

            it "returns false" do
              expect(subject.precludes?(other)).to eq(false)
            end
          end
        end
      end

      context "and I have unquote patterns" do
        context "and the patterns preclude the respective node" do
          subject { described_class.make(mod, ast("`~abc")) }

          it "returns true" do
            expect(subject.precludes?(other)).to eq(true)
          end
        end

        context "and the patterns do NOT preclude the respective node" do
          subject { described_class.make(mod, ast("`~'bar")) }

          it "returns false" do
            expect(subject.precludes?(other)).to eq(false)
          end
        end
      end

      context "and I have no unquotes" do
        context "and the nodes are equal" do
          subject { described_class.make(mod, ast("`~abc")) }

          it "returns true" do
            expect(subject.precludes?(other)).to eq(true)
          end
        end
      end
    end

    context "when the other pattern is a QuasiQuote" do
      context "and it has unquote patterns" do
        let(:other) { described_class.make(mod, ast("`(~'a + 2)")) }

        context "and my pattern precludes the respective node or pattern" do
          subject { described_class.make(mod, ast("`(~a + 2)")) }

          it "returns true" do
            expect(subject.precludes?(other)).to eq(true)
          end

          context "but the rest of the expression differs" do
            subject { described_class.make(mod, ast("`(~a * 2)")) }

            it "returns false" do
              expect(subject.precludes?(other)).to eq(false)
            end
          end
        end

        context "and the patterns do NOT preclude the respective node or pattern" do
          subject { described_class.make(mod, ast("`(~'b + 2)")) }

          it "returns false" do
            expect(subject.precludes?(other)).to eq(false)
          end
        end

        context "in a many-child" do
          let(:other) { described_class.make(mod, ast("`[0, ~'a, 2]")) }

          context "and my pattern precludes the respective node or pattern" do
            subject { described_class.make(mod, ast("`[0, ~a, 2]")) }

            it "returns true" do
              expect(subject.precludes?(other)).to eq(true)
            end
          end

          context "and my pattern does NOT preclude the respective node or pattern" do
            subject { described_class.make(mod, ast("`[0, ~'b, 2]")) }

            it "returns false" do
              expect(subject.precludes?(other)).to eq(false)
            end
          end
        end
      end

      context "and it has no unquotes" do
        let(:other) { described_class.make(mod, ast("`foo")) }

        context "and I have unquotes" do
          subject { described_class.make(mod, ast("`~abc")) }

          it "returns true" do
            expect(subject.precludes?(other)).to eq(true)
          end
        end

        context "and I have no unquotes" do
          subject { described_class.make(mod, ast("`foo")) }

          context "and the nodes are equal" do
            it "returns true" do
              expect(subject.precludes?(other)).to eq(true)
            end
          end

          context "and the nodes are not equal" do
            subject { described_class.make(mod, ast("`bar")) }

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

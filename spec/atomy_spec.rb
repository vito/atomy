require "atomy"
require "spec_helper"

require "atomy/bootstrap"
require "atomy/code/constant"
require "atomy/module"
require "atomy/pattern/equality"
require "atomy/pattern/kind_of"
require "atomy/pattern/wildcard"

describe Atomy do
  describe ".define_branch" do
    def wildcard(name = nil)
      Atomy::Pattern::Wildcard.new(name)
    end

    def equality(value)
      Atomy::Pattern::Equality.new(value)
    end

    def kind_of_pat(klass)
      Atomy::Pattern::KindOf.new(klass)
    end

    class SomeTarget
    end

    let(:target) { Atomy::Module.new }

    context "when the pattern has a target" do
      it "defines the method branch on the target" do
        described_class.define_branch(
          binding,
          :foo,
          Atomy::Method::Branch.new(kind_of_pat(SomeTarget), [], []) { 2 },
        )

        expect(SomeTarget.new.foo).to eq(2)
        expect { Object.new.foo }.to raise_error
      end
    end

    context "when the pattern does not have a target" do
      it "defines the method branch on the module definition target" do
        def_binding = nil

        foo = Module.new { def_binding = binding }

        described_class.define_branch(
          def_binding,
          :foo,
          Atomy::Method::Branch.new(nil, [], []) { 2 },
        )

        bar = Class.new { include foo }

        expect(bar.new.foo).to eq(2)
      end
    end

    describe "pattern-matching" do
      it "pattern-matches the message with the given pattern" do
        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [equality(0)], []) { 42 },
        )

        expect(target.foo(0)).to eq(42)
        expect { target.foo(1) }.to raise_error(Atomy::MessageMismatch)
      end

      it "extends methods with branches for different patterns" do
        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [equality(0)], []) { 42 },
        )

        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [equality(1)], []) { 43 },
        )

        expect(target.foo(0)).to eq(42)
        expect(target.foo(1)).to eq(43)
      end

      it "does not match if not enough arguments were given" do
        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [equality(1), wildcard], []) { 42 },
        )

        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [equality(0)], []) { 43 },
        )

        expect { target.foo(1) }.to raise_error(Atomy::MessageMismatch)
      end

      it "does not match if too many arguments were given" do
        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [equality(1), wildcard], []) { 42 },
        )

        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [equality(2), wildcard, wildcard], []) { 43 },
        )

        expect { target.foo(1, 2, 3) }.to raise_error(Atomy::MessageMismatch)
      end

      context "when a wildcard method is defined after a specific one" do
        it "does not clobber the more specific one, as it was defined first" do
          described_class.define_branch(
            target.module_eval { binding },
            :foo,
            Atomy::Method::Branch.new(nil, [equality(0)], []) { 0 },
          )

          described_class.define_branch(
            target.module_eval { binding },
            :foo,
            Atomy::Method::Branch.new(nil, [wildcard], []) { 42 },
          )

          expect(target.foo(0)).to eq(0)
          expect(target.foo(1)).to eq(42)
        end
      end

      context "when a wildcard method is defined before a specific one" do
        it "clobbers later definitions" do
          described_class.define_branch(
            target.module_eval { binding },
            :foo,
            Atomy::Method::Branch.new(nil, [wildcard], []) { 42 },
          )

          described_class.define_branch(
            target.module_eval { binding },
            :foo,
            Atomy::Method::Branch.new(nil, [equality(0)], []) { 0 },
          )

          expect(target.foo(0)).to eq(42)
          expect(target.foo(1)).to eq(42)
        end
      end

      context "when pattern-matching fails" do
        context "and a method is defined on super" do
          it "sends it to super" do
            base = Class.new
            sub = Class.new(base)

            described_class.define_branch(
              base.class_eval { binding },
              :foo,
              Atomy::Method::Branch.new(nil, [equality(0)], []) { 0 },
            )

            described_class.define_branch(
              sub.class_eval { binding },
              :foo,
              Atomy::Method::Branch.new(nil, [equality(1)], []) { 1 },
            )

            expect(sub.new.foo(0)).to eq(0)
            expect(sub.new.foo(1)).to eq(1)
          end
        end

        context "and a method is NOT defined on super" do
          it "fails with MessageMismatch" do
            described_class.define_branch(
              target.module_eval { binding },
              :foo,
              Atomy::Method::Branch.new(nil, [equality(0)], []) { 0 },
            )

            expect { target.foo(1) }.to raise_error(Atomy::MessageMismatch)
          end
        end
      end
    end
  end
end

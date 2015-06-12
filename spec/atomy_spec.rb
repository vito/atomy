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
          Atomy::Method::Branch.new(kind_of_pat(SomeTarget)) { 2 },
        )

        expect(SomeTarget.new.foo).to eq(2)
        expect(Object.new).to_not respond_to(:foo)
      end
    end

    context "when the pattern does not have a target" do
      it "defines the method branch on the module definition target" do
        def_binding = nil

        foo = Module.new { def_binding = binding }

        described_class.define_branch(
          def_binding,
          :foo,
          Atomy::Method::Branch.new { 2 },
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
          Atomy::Method::Branch.new(nil, [equality(0)]) { 42 },
        )

        expect(target.foo(0)).to eq(42)
        expect { target.foo(1) }.to raise_error(Atomy::MessageMismatch)
      end

      it "extends methods with branches for different patterns" do
        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [equality(0)]) { 42 },
        )

        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [equality(1)]) { 43 },
        )

        expect(target.foo(0)).to eq(42)
        expect(target.foo(1)).to eq(43)
      end

      it "permits defining branches with different default argument counts" do
        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [equality(1)], []) { 42 },
        )

        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [equality(1)], [[wildcard, proc{}]]) { 43 },
        )

        expect(target.foo(1)).to eq(42)
        expect(target.foo(1, 2)).to eq(43)
      end

      it "does not permit defining branches with different splat indexes" do
        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [equality(1)], [], wildcard) { 42 },
        )

        expect {
          described_class.define_branch(
            target.module_eval { binding },
            :foo,
            Atomy::Method::Branch.new(nil, [equality(1)], [[wildcard, proc{}]], wildcard) { 42 },
          )
        }.to raise_error(Atomy::InconsistentArgumentForms)
      end

      it "does not permit defining branches with different required argument counts" do
        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [wildcard]) { 42 },
        )

        expect {
          described_class.define_branch(
            target.module_eval { binding },
            :foo,
            Atomy::Method::Branch.new(nil, [wildcard, wildcard]) { 42 },
          )
        }.to raise_error(Atomy::InconsistentArgumentForms)
      end

      it "does not permit defining branches with different post-argument counts" do
        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [wildcard], [], nil, [wildcard]) { 42 },
        )

        expect {
          described_class.define_branch(
            target.module_eval { binding },
            :foo,
            Atomy::Method::Branch.new(nil, [wildcard], [], nil, [wildcard, wildcard]) { 42 },
          )
        }.to raise_error(Atomy::InconsistentArgumentForms)
      end

      it "pattern-matches on the splat argument" do
        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [wildcard], [], equality([2, 3])) { :a },
        )

        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [wildcard], [], wildcard) { :b },
        )

        expect(target.foo(1, 2, 3)).to eq(:a)
        expect(target.foo(2, 2, 3)).to eq(:a)
        expect(target.foo(2, 2, 3, 4)).to eq(:b)
        expect(target.foo(1)).to eq(:b)
        expect { target.foo }.to raise_error(ArgumentError)
      end

      it "captures the splat argument" do
        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(
            nil,
            [wildcard(:x)],
            [],
            wildcard(:ys),
            [],
            nil,
            [:x, :ys],
          ) { |x, ys| [x, ys] },
        )

        expect(target.foo(1, 2, 3)).to eq([1, [2, 3]])
      end

      it "pattern-matches on the block argument" do
        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [], [], nil, [], equality(nil), []) { :not_provided },
        )

        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [], [], nil, [], wildcard, []) { :provided },
        )

        expect(target.foo {}).to eq(:provided)
        expect(target.foo).to eq(:not_provided)
      end

      it "captures the block argument" do
        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [], [], nil, [], wildcard(:x), [:x]) { |x| x.call },
        )

        expect(target.foo { 42 }).to eq(42)
      end

      context "when a wildcard method is defined after a specific one" do
        it "does not clobber the more specific one, as it was defined first" do
          described_class.define_branch(
            target.module_eval { binding },
            :foo,
            Atomy::Method::Branch.new(nil, [equality(0)]) { 0 },
          )

          described_class.define_branch(
            target.module_eval { binding },
            :foo,
            Atomy::Method::Branch.new(nil, [wildcard]) { 42 },
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
            Atomy::Method::Branch.new(nil, [wildcard]) { 42 },
          )

          described_class.define_branch(
            target.module_eval { binding },
            :foo,
            Atomy::Method::Branch.new(nil, [equality(0)]) { 0 },
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
              Atomy::Method::Branch.new(nil, [equality(0)]) { 0 },
            )

            described_class.define_branch(
              sub.class_eval { binding },
              :foo,
              Atomy::Method::Branch.new(nil, [equality(1)]) { 1 },
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
              Atomy::Method::Branch.new(nil, [equality(0)]) { 0 },
            )

            expect { target.foo(1) }.to raise_error(Atomy::MessageMismatch)
          end
        end
      end
    end
  end
end

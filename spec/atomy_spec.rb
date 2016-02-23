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
        kopat = kind_of_pat(SomeTarget)

        described_class.define_branch(
          binding,
          :foo,
          Atomy::Method::Branch.new(kopat) { |*args| args },
        )

        recv = SomeTarget.new
        expect(recv.foo).to eq([kopat, recv])
        expect(Object.new).to respond_to(:foo)
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
      # helpers for checking equality
      let(:eq0) { equality(0) }
      let(:eq1) { equality(1) }
      let(:w) { wildcard }

      it "pattern-matches the message with the given pattern, calling the body with the args and patterns" do
        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [eq0]) { |*args| args }
        )

        expect(target.foo(0)).to eq([eq0, 0])
        expect { target.foo(1) }.to raise_error(Atomy::MessageMismatch)
      end

      it "extends methods with branches for different patterns" do
        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [eq0]) { |*args| [:first, args] }
        )

        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [eq1]) { |*args| [:second, args] }
        )

        expect(target.foo(0)).to eq([:first, [eq0, 0]])
        expect(target.foo(1)).to eq([:second, [eq1, 1]])
      end

      it "permits defining branches with different default argument counts" do
        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [eq1], []) { |*args| [:first, args] }
        )

        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [eq1], [w]) { |*args| [:second, args] }
        )

        expect(target.foo(1)).to eq([:first, [eq1, 1]])
        expect(target.foo(1, 2)).to eq([:second, [eq1, 1, w, 2]])
      end

      it "passes undefined default arguments along to the branch" do
        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [eq1], [w]) { |*args| args }
        )

        expect(target.foo(1)).to eq([eq1, 1, w, undefined])
      end

      it "does not permit defining branches with different splat indexes" do
        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [eq1], [], w) { |*args| args },
        )

        expect {
          described_class.define_branch(
            target.module_eval { binding },
            :foo,
            Atomy::Method::Branch.new(nil, [eq1], [w], w) { |*args| args },
          )
        }.to raise_error(Atomy::InconsistentArgumentForms)
      end

      it "does not permit defining branches with different required argument counts" do
        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [w]) { |*args| args },
        )

        expect {
          described_class.define_branch(
            target.module_eval { binding },
            :foo,
            Atomy::Method::Branch.new(nil, [w, w]) { |*args| args },
          )
        }.to raise_error(Atomy::InconsistentArgumentForms)
      end

      it "does not permit defining branches with different post-argument counts" do
        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [w], [], nil, [w]) { |*args| args },
        )

        expect {
          described_class.define_branch(
            target.module_eval { binding },
            :foo,
            Atomy::Method::Branch.new(nil, [w], [], nil, [w, w]) { |*args| args },
          )
        }.to raise_error(Atomy::InconsistentArgumentForms)
      end

      it "pattern-matches on the splat argument" do
        eq23 = equality([2, 3])

        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [w], [], eq23) { |*args| [:first, args] },
        )

        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [w], [], w) { |*args| [:second, args] },
        )

        expect(target.foo(1, 2, 3)).to eq([:first, [w, 1, eq23, [2, 3]]])
        expect(target.foo(2, 2, 3)).to eq([:first, [w, 2, eq23, [2, 3]]])
        expect(target.foo(2, 2, 3, 4)).to eq([:second, [w, 2, w, [2, 3, 4]]])
        expect(target.foo(1)).to eq([:second, [w, 1, w, []]])
        expect { target.foo }.to raise_error(ArgumentError)
      end

      it "captures the splat argument" do
        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(
            nil,
            [eq1],
            [],
            w,
          ) { |*args| args },
        )

        expect(target.foo(1, 2, 3)).to eq([eq1, 1, w, [2, 3]])
      end

      it "pattern-matches on the block argument" do
        eqn = equality(nil)

        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [], [], nil, [], eqn) { |*args| [:not_provided, args] },
        )

        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [], [], nil, [], w) { |pat, prc| [:provided, [pat, prc.call]] },
        )

        expect(target.foo { 42 }).to eq([:provided, [w, 42]])
        expect(target.foo).to eq([:not_provided, [eqn, nil]])
      end

      it "captures the block argument" do
        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          Atomy::Method::Branch.new(nil, [], [], nil, [], w) { |pat, prc| [pat, prc.call] },
        )

        expect(target.foo { 42 }).to eq([w, 42])
      end

      context "when a wildcard method is defined after a specific one" do
        it "does not clobber the more specific one, as it was defined first" do
          described_class.define_branch(
            target.module_eval { binding },
            :foo,
            Atomy::Method::Branch.new(nil, [eq0]) { |*args| args },
          )

          described_class.define_branch(
            target.module_eval { binding },
            :foo,
            Atomy::Method::Branch.new(nil, [w]) { |*args| args },
          )

          expect(target.foo(0)).to eq([eq0, 0])
          expect(target.foo(1)).to eq([w, 1])
        end
      end

      context "when a wildcard method is defined before a specific one" do
        it "clobbers later definitions" do
          described_class.define_branch(
            target.module_eval { binding },
            :foo,
            Atomy::Method::Branch.new(nil, [w]) { |*args| args },
          )

          described_class.define_branch(
            target.module_eval { binding },
            :foo,
            Atomy::Method::Branch.new(nil, [eq0]) { |*args| args },
          )

          expect(target.foo(0)).to eq([w, 0])
          expect(target.foo(1)).to eq([w, 1])
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
              Atomy::Method::Branch.new(nil, [eq0]) { |*args| [:parent, args] },
            )

            described_class.define_branch(
              sub.class_eval { binding },
              :foo,
              Atomy::Method::Branch.new(nil, [eq1]) { |*args| [:child, args] },
            )

            expect(sub.new.foo(0)).to eq([:parent, [eq0, 0]])
            expect(sub.new.foo(1)).to eq([:child, [eq1, 1]])
          end
        end

        context "and a method is NOT defined on super" do
          it "fails with MessageMismatch" do
            described_class.define_branch(
              target.module_eval { binding },
              :foo,
              Atomy::Method::Branch.new(nil, [eq0]) { |*args| args },
            )

            expect { target.foo(1) }.to raise_error(Atomy::MessageMismatch)
          end
        end
      end
    end
  end
end

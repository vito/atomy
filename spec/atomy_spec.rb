require "atomy"
require "spec_helper"

require "atomy/bootstrap"
require "atomy/code/constant"
require "atomy/module"
require "atomy/pattern/equality"
require "atomy/pattern/kind_of"
require "atomy/pattern/message"
require "atomy/pattern/wildcard"

describe Atomy do
  describe ".define_branch" do
    def wildcard(name = nil)
      Atomy::Pattern::Wildcard.new(name)
    end

    def equality(value)
      Atomy::Pattern::Equality.new(value)
    end

    def message(receiver = wildcard, arguments = [])
      Atomy::Pattern::Message.new(receiver, arguments)
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
          message(kind_of_pat(SomeTarget)),
          ast("2"),
          Atomy::Bootstrap,
        )

        expect(SomeTarget.new.foo).to eq(2)
      end
    end

    context "when the pattern does not have a target" do
      it "defines the method branch on the module definition target" do
        def_binding = nil

        foo = Module.new { def_binding = binding }

        described_class.define_branch(
          def_binding,
          :foo,
          message(nil),
          ast("2"),
          Atomy::Bootstrap, # so we can compile '2'
        )

        bar = Class.new { include foo }

        expect(bar.new.foo).to eq(2)
      end
    end

    describe "pattern-matching" do
      it "pattern-matches the message with the given pattern" do
        pattern = message(nil, [equality(0)])

        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          pattern,
          ast("42"),
          Atomy::Bootstrap,
        )

        expect(target.foo(0)).to eq(42)
        expect { target.foo(1) }.to raise_error(Atomy::MessageMismatch)
      end

      it "extends methods with branches for different patterns" do
        pattern_0 = message(nil, [equality(0)])
        pattern_1 = message(nil, [equality(1)])

        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          pattern_0,
          ast("42"),
          Atomy::Bootstrap,
        )

        described_class.define_branch(
          target.module_eval { binding },
          :foo,
          pattern_1,
          ast("43"),
          Atomy::Bootstrap,
        )

        expect(target.foo(0)).to eq(42)
        expect(target.foo(1)).to eq(43)
      end

      context "when a wildcard method is defined after a specific one" do
        it "ensures that the more specific method is not clobbered" do
          pattern_0 = message(nil, [equality(0)])
          pattern_wildcard = message(nil, [wildcard])

          described_class.define_branch(
            target.module_eval { binding },
            :foo,
            pattern_0,
            ast("0"),
            Atomy::Bootstrap,
          )

          described_class.define_branch(
            target.module_eval { binding },
            :foo,
            pattern_wildcard,
            ast("42"),
            Atomy::Bootstrap,
          )

          expect(target.foo(0)).to eq(0)
          expect(target.foo(1)).to eq(42)
        end
      end

      context "when a wildcard method is defined before a specific one" do
        it "ensures that the more specific method is not clobbered" do
          pattern_0 = message(nil, [equality(0)])
          pattern_wildcard = message(nil, [wildcard])

          described_class.define_branch(
            target.module_eval { binding },
            :foo,
            pattern_wildcard,
            ast("42"),
            Atomy::Bootstrap,
          )

          described_class.define_branch(
            target.module_eval { binding },
            :foo,
            pattern_0,
            ast("0"),
            Atomy::Bootstrap,
          )

          expect(target.foo(0)).to eq(0)
          expect(target.foo(1)).to eq(42)
        end
      end

      context "when pattern-matching fails" do
        context "and a method is defined on super" do
          it "sends it to super" do
            base = Class.new
            sub = Class.new(base)

            pattern_0 = message(nil, [equality(0)])
            pattern_1 = message(nil, [equality(1)])

            described_class.define_branch(
              base.class_eval { binding },
              :foo,
              pattern_0,
              ast("0"),
              Atomy::Bootstrap,
            )

            described_class.define_branch(
              sub.class_eval { binding },
              :foo,
              pattern_1,
              ast("1"),
              Atomy::Bootstrap,
            )

            expect(sub.new.foo(0)).to eq(0)
            expect(sub.new.foo(1)).to eq(1)
          end
        end

        context "and a method is NOT defined on super" do
          it "fails with MessageMismatch" do
            pattern = message(nil, [equality(0)])

            described_class.define_branch(
              target.module_eval { binding },
              :foo,
              pattern,
              ast("0"),
              Atomy::Bootstrap,
            )

            expect { target.foo(1) }.to raise_error(Atomy::MessageMismatch)
          end
        end
      end
    end
  end
end

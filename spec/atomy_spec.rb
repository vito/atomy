require "atomy"

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

    let(:target) { Atomy::Module.new }

    it "defines the method branch on the target" do
      described_class.define_branch(target, :foo, message) do
        2
      end

      expect(target.foo).to eq(2)
    end

    describe "pattern-matching" do
      it "pattern-matches the message with the given pattern" do
        pattern = message(wildcard, [equality(0)])

        described_class.define_branch(target, :foo, pattern) do |_|
          :zero
        end

        expect(target.foo(0)).to eq(:zero)
      end

      it "extends methods with branches for different patterns" do
        pattern_0 = message(wildcard, [equality(0)])
        pattern_1 = message(wildcard, [equality(1)])

        described_class.define_branch(target, :foo, pattern_0) do |_|
          :zero
        end

        described_class.define_branch(target, :foo, pattern_1) do |_|
          :one
        end

        expect(target.foo(0)).to eq(:zero)
        expect(target.foo(1)).to eq(:one)
      end

      it "has the definition's binding available for pattern-matching" do
        pattern = message(
          wildcard,
          [Atomy::Pattern::KindOf.new(Atomy::Code::Constant.new(:ABC))])

        body = nil
        module X
          class ABC; end

          def self.body
            proc { |_| :ok }
          end
        end

        described_class.define_branch(target, :foo, pattern, &X.body)

        expect(target.foo(X::ABC.new)).to eq(:ok)

        expect {
          target.foo(Object.new)
        }.to raise_error(Atomy::MessageMismatch)
      end

      context "when a wildcard method is defined after a specific one" do
        it "ensures that the more specific method is not clobbered" do
          pattern_0 = message(wildcard, [equality(0)])
          pattern_1 = message(wildcard, [wildcard])

          described_class.define_branch(target, :foo, pattern_0) do |_|
            :zero
          end

          described_class.define_branch(target, :foo, pattern_1) do |_|
            :wild
          end

          expect(target.foo(0)).to eq(:zero)
          expect(target.foo(1)).to eq(:wild)
        end
      end

      context "when a wildcard method is defined before a specific one" do
        it "ensures that the more specific method is not clobbered" do
          pattern_0 = message(wildcard, [equality(0)])
          pattern_1 = message(wildcard, [wildcard])

          described_class.define_branch(target, :foo, pattern_1) do |_|
            :wild
          end

          described_class.define_branch(target, :foo, pattern_0) do |_|
            :zero
          end

          expect(target.foo(0)).to eq(:zero)
          expect(target.foo(1)).to eq(:wild)
        end
      end

      context "when pattern-matching fails" do
        context "and a method is defined on super" do
          it "sends it to super" do
            base = Class.new
            sub = Class.new(base)

            pattern_0 = message(wildcard, [equality(0)])
            pattern_1 = message(wildcard, [equality(1)])

            described_class.define_branch(base, :foo, pattern_0) do |_|
              :zero
            end

            described_class.define_branch(sub, :foo, pattern_1) do |_|
              :one
            end

            expect(sub.new.foo(0)).to eq(:zero)
            expect(sub.new.foo(1)).to eq(:one)
          end
        end

        context "and a method is NOT defined on super" do
          it "fails with MessageMismatch" do
            pattern = message(wildcard, [equality(0)])

            described_class.define_branch(target, :foo, pattern) do |_|
              nil
            end

            expect { target.foo(1) }.to raise_error(Atomy::MessageMismatch)
          end
        end
      end
    end
  end
end

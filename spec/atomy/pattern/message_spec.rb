require "spec_helper"

require "atomy/bootstrap"
require "atomy/module"
require "atomy/node/equality"
require "atomy/pattern/equality"
require "atomy/pattern/message"
require "atomy/pattern/wildcard"

describe Atomy::Pattern::Message do
  def wildcard(name = nil)
    Atomy::Pattern::Wildcard.new(name)
  end

  def equality(name = nil)
    Atomy::Pattern::Equality.new(name)
  end

  subject { described_class.new(wildcard) }

  describe "#matches?" do
    def match_args?(*args)
      code = Atomy::Compiler.package(__FILE__.to_sym) do |gen|
        gen.total_args = gen.required_args = args.size

        args.size.times do |i|
          gen.state.scope.new_local(:"arg:#{i}")
        end

        gen.push_literal(subject)
        gen.push_variables
        gen.send(:matches?, 1)
        gen.ret
      end

      Atomy::Compiler.construct_block(code, binding).call(*args)
    end

    context "with no arguments" do
      it "matches no arguments" do
        expect(match_args?).to eq(true)
      end

      it "does not match extra arguments" do
        expect(match_args?(1)).to eq(false)
      end
    end

    context "with non-wildcard argument patterns" do
      subject { described_class.new(wildcard, [equality(1)]) }

      it "does not match too few arguments" do
        expect(match_args?).to eq(false)
      end

      it "does not match too many arguments" do
        expect(match_args?(1, 2)).to eq(false)
      end

      it "matches if the argument matches" do
        expect(match_args?(1)).to eq(true)
      end

      it "does not match if the argument does not match" do
        expect(match_args?(2)).to eq(false)
      end
    end

    context "with wildcard argument patterns" do
      subject { described_class.new(wildcard, [wildcard]) }

      it "does not match too few arguments" do
        expect(match_args?).to eq(false)
      end

      it "does not match too many arguments" do
        expect(match_args?(1, 2)).to eq(false)
      end

      it "matches any argument" do
        expect(match_args?(1)).to eq(true)
        expect(match_args?("foo")).to eq(true)
      end
    end
  end

  describe "#assign" do
    def star_wars_episode_iv_a_new_scope(self_, locals = [])
      current_scope = Rubinius::VariableScope.current

      Rubinius::VariableScope.synthesize(
        current_scope.method,
        current_scope.module,
        current_scope.parent,
        self_,
        nil,
        locals.to_tuple,
      )
    end

    context "when there are no bindings" do
      it "does nothing" do
        subject.assign(Rubinius::VariableScope.current, Rubinius::VariableScope.current)
      end
    end

    context "when the receiver pattern binds" do
      subject { described_class.new(wildcard(:a)) }

      it "assigns locals against the given scope's receiver" do
        a = nil
        scope = star_wars_episode_iv_a_new_scope(42)
        subject.assign(Rubinius::VariableScope.current, scope)
        expect(a).to eq(42)
      end
    end

    context "when arguments bind" do
      subject { described_class.new(wildcard, [wildcard(:a)]) }

      it "assigns locals against the given scope's argument locals" do
        a = nil
        scope = star_wars_episode_iv_a_new_scope(Object.new, [42])
        subject.assign(Rubinius::VariableScope.current, scope)
        expect(a).to eq(42)
      end
    end

    context "when the arguments bind twice" do
      subject { described_class.new(wildcard, [wildcard(:a), wildcard(:b)]) }

      it "assigns locals against the given scope's argument locals" do
        a = nil
        b = nil
        scope = star_wars_episode_iv_a_new_scope(Object.new, [:a, :b])
        subject.assign(Rubinius::VariableScope.current, scope)
        expect(a).to eq(:a)
        expect(b).to eq(:b)
      end
    end

    context "when the arguments bind one local twice" do
      subject { described_class.new(wildcard, [wildcard(:a), wildcard(:a)]) }

      it "assigns locals against the given scope's argument locals" do
        a = nil
        scope = star_wars_episode_iv_a_new_scope(Object.new, [:a, :b])
        subject.assign(Rubinius::VariableScope.current, scope)
        expect(a).to eq(:b)
      end
    end

    context "when the receiver and arguments both bind" do
      subject { described_class.new(wildcard(:a), [wildcard(:b), wildcard(:c)]) }

      it "assigns locals against the given scope's argument locals" do
        a = nil
        b = nil
        c = nil
        scope = star_wars_episode_iv_a_new_scope(:a, [:b, :c])
        subject.assign(Rubinius::VariableScope.current, scope)
        expect(a).to eq(:a)
        expect(b).to eq(:b)
        expect(c).to eq(:c)
      end
    end
  end

  describe "#precludes?" do
    let(:other) { described_class.new(wildcard) }

    context "when the receiver pattern precludes the other" do
      let(:other) { described_class.new(wildcard) }

      subject { described_class.new(wildcard) }

      context "and the number of arguments differ" do
        let(:other) { described_class.new(wildcard) }

        subject { described_class.new(wildcard, [wildcard]) }

        it "returns false" do
          expect(subject.precludes?(other)).to eq(false)
        end
      end

      context "and the arguments preclude the other arguments" do
        let(:other) { described_class.new(wildcard, [wildcard]) }

        subject { described_class.new(wildcard, [wildcard]) }

        it "returns true" do
          expect(subject.precludes?(other)).to eq(true)
        end
      end

      context "and the arguments do NOT preclude the other arguments" do
        let(:other) { described_class.new(wildcard, [wildcard]) }

        subject { described_class.new(wildcard, [equality(0)]) }

        it "returns false" do
          expect(subject.precludes?(other)).to eq(false)
        end
      end
    end

    context "when the receiver pattern does NOT preclude the other" do
      let(:other) { described_class.new(wildcard) }

      subject { described_class.new(equality(0)) }

      it "returns false" do
        expect(subject.precludes?(other)).to eq(false)
      end

      context "and the arguments preclude the other arguments" do
        let(:other) { described_class.new(wildcard, [wildcard]) }

        subject { described_class.new(equality(0), [wildcard]) }

        it "returns false" do
          expect(subject.precludes?(other)).to eq(false)
        end
      end
    end
  end

  describe "#locals" do
    context "when the receiver pattern binds" do
      subject { described_class.new(wildcard(:a)) }

      its(:locals) { should eq([:a]) }
    end

    context "when any of the argument patterns bind" do
      subject { described_class.new(wildcard, [wildcard(:a)]) }

      its(:locals) { should eq([:a]) }
    end

    context "when the receiver and argument patterns both bind" do
      subject { described_class.new(wildcard(:a), [wildcard(:b)]) }

      its(:locals) { should eq([:a, :b]) }
    end

    context "when neither the receiver nor the arguments bind" do
      its(:locals) { should be_empty }
    end
  end
end

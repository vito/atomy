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

  describe "#bindings" do
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
      it "returns an empty array" do
        expect(subject.bindings(Rubinius::VariableScope.current)).to be_empty
      end
    end

    context "when the receiver pattern binds" do
      subject { described_class.new(wildcard(:a)) }

      it "returns its bound value" do
        scope = star_wars_episode_iv_a_new_scope(42)
        expect(subject.bindings(scope)).to eq([42])
      end
    end

    context "when arguments bind" do
      subject { described_class.new(wildcard, [wildcard(:a)]) }

      it "returns their bound values" do
        scope = star_wars_episode_iv_a_new_scope(Object.new, [42])
        expect(subject.bindings(scope)).to eq([42])
      end
    end

    context "when the arguments bind twice" do
      subject { described_class.new(wildcard, [wildcard(:a), wildcard(:b)]) }

      it "returns their bound values" do
        scope = star_wars_episode_iv_a_new_scope(Object.new, [:a, :b])
        expect(subject.bindings(scope)).to eq([:a, :b])
      end
    end

    context "when the arguments bind one local twice" do
      subject { described_class.new(wildcard, [wildcard(:a), wildcard(:a)]) }

      it "returns the bound values, regardless of its name" do
        scope = star_wars_episode_iv_a_new_scope(Object.new, [:a, :b])
        expect(subject.bindings(scope)).to eq([:a, :b])
      end
    end

    context "when the receiver and arguments both bind" do
      subject { described_class.new(wildcard(:a), [wildcard(:b), wildcard(:c)]) }

      it "returns their bound values" do
        scope = star_wars_episode_iv_a_new_scope(:a, [:b, :c])
        expect(subject.bindings(scope)).to eq([:a, :b, :c])
      end
    end
  end
end

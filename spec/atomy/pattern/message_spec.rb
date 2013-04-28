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
        gen.total_args = gen.required_args = subject.arguments.size

        subject.arguments.size.times do |i|
          gen.state.scope.new_local(:"arg:#{i}")
        end

        subject.matches?(gen)
        gen.ret
      end

      Atomy::Compiler.construct_block(code, binding).call(*args)
    end

    context "with a receiver that always matches self" do
      let(:receiver) { Atomy::Pattern.new }

      subject { described_class.new(receiver) }

      it "skips matching the receiver" do
        receiver.should_receive(:always_matches_self?).and_return(true)
        receiver.should_not_receive(:matches?)
        expect(match_args?).to be_true
      end

      context "with non-wildcard argument patterns" do
        subject { described_class.new(receiver, [equality(1)]) }

        before do
          receiver.should_receive(:always_matches_self?).and_return(true)
          receiver.should_not_receive(:matches?)
        end

        it "does not match too few arguments" do
          expect(match_args?).to be_false
        end

        it "does not match too many arguments" do
          expect(match_args?(1, 2)).to be_false
        end

        it "matches if the argument matches" do
          expect(match_args?(1)).to be_true
        end

        it "does not match if the argument does not match" do
          expect(match_args?(2)).to be_false
        end
      end
    end

    context "with no arguments" do
      it "matches no arguments" do
        expect(match_args?).to be_true
      end

      it "does not match extra arguments" do
        expect(match_args?(1)).to be_false
      end
    end

    context "with non-wildcard argument patterns" do
      subject { described_class.new(wildcard, [equality(1)]) }

      it "does not match too few arguments" do
        expect(match_args?).to be_false
      end

      it "does not match too many arguments" do
        expect(match_args?(1, 2)).to be_false
      end

      it "matches if the argument matches" do
        expect(match_args?(1)).to be_true
      end

      it "does not match if the argument does not match" do
        expect(match_args?(2)).to be_false
      end
    end

    context "with wildcard argument patterns" do
      subject { described_class.new(wildcard, [wildcard]) }

      it "does not match too few arguments" do
        expect(match_args?).to be_false
      end

      it "does not match too many arguments" do
        expect(match_args?(1, 2)).to be_false
      end

      it "matches any argument" do
        expect(match_args?(1)).to be_true
        expect(match_args?("foo")).to be_true
      end
    end
  end

  describe "#inlineable?" do
    let(:uninlineable) { Atomy::Pattern.new }
    let(:receiver) { wildcard }
    let(:arguments) { [] }

    subject { described_class.new(receiver, arguments) }

    context "when there is no receiver pattern" do
      let(:receiver) { nil }

      context "and there are arguments" do
        context "and all arguments are inlineable" do
          let(:arguments) { [wildcard] }

          it { should be_inlineable }
        end

        context "and some of the arguments aren't inlineable" do
          let(:arguments) { [wildcard, uninlineable] }

          it { should_not be_inlineable }
        end

        context "and none of the arguments are inlineable" do
          let(:arguments) { [uninlineable] }

          it { should_not be_inlineable }
        end
      end

      context "and there are no arguments" do
        it { should be_inlineable }
      end
    end

    context "when the receiver is inlineable" do
      context "and there are arguments" do
        context "and all arguments are inlineable" do
          let(:arguments) { [wildcard] }

          it { should be_inlineable }
        end

        context "and some of the arguments aren't inlineable" do
          let(:arguments) { [wildcard, uninlineable] }

          it { should_not be_inlineable }
        end

        context "and none of the arguments are inlineable" do
          let(:arguments) { [uninlineable] }

          it { should_not be_inlineable }
        end
      end

      context "and there are no arguments" do
        it { should be_inlineable }
      end
    end

    context "when the receiver is NOT inlineable" do
      let(:receiver) { uninlineable }

      context "but it always matches self" do
        before do
          receiver.should_receive(:always_matches_self?).and_return(true)
        end

        context "and there are arguments" do
          context "and all arguments are inlineable" do
            let(:arguments) { [wildcard] }

            it { should be_inlineable }
          end

          context "and some of the arguments aren't inlineable" do
            let(:arguments) { [wildcard, uninlineable] }

            it { should_not be_inlineable }
          end

          context "and none of the arguments are inlineable" do
            let(:arguments) { [uninlineable] }

            it { should_not be_inlineable }
          end
        end

        context "and there are no arguments" do
          it { should be_inlineable }
        end
      end

      context "and it doesn't always match self" do
        it { should_not be_inlineable }
      end
    end
  end

  describe "#deconstruct" do
    context "when there are no bindings" do
      it_compiles_as(:deconstruct) {}
    end

    context "when the receiver pattern binds" do
      subject { described_class.new(wildcard(:a)) }

      it_compiles_as(:deconstruct) do |gen|
        gen.push_self
        gen.set_local(0)
        gen.pop
      end
    end

    context "when arguments bind" do
      subject { described_class.new(wildcard, [wildcard(:a)]) }

      it_compiles_as(:deconstruct) do |gen|
        arg = gen.state.scope.new_local(:"arg:0").reference
        pat = gen.state.scope.new_local(:a).reference
        gen.push_local(arg.slot)
        gen.set_local(pat.slot)
      end
    end

    context "when the arguments bind twice" do
      subject { described_class.new(wildcard, [wildcard(:a), wildcard(:b)]) }

      it_compiles_as(:deconstruct) do |gen|
        arg1 = gen.state.scope.new_local(:"arg:0").reference
        arg2 = gen.state.scope.new_local(:"arg:1").reference

        pat1 = gen.state.scope.new_local(:a).reference
        pat2 = gen.state.scope.new_local(:b).reference

        gen.push_local(arg1.slot)
        gen.set_local(pat1.slot)

        gen.push_local(arg2.slot)
        gen.set_local(pat2.slot)
      end
    end

    context "when the arguments bind one local twice" do
      subject { described_class.new(wildcard, [wildcard(:a), wildcard(:a)]) }

      it_compiles_as(:deconstruct) do |gen|
        arg1 = gen.state.scope.new_local(:"arg:0").reference
        arg2 = gen.state.scope.new_local(:"arg:1").reference

        pat = gen.state.scope.new_local(:a).reference

        gen.push_local(arg1.slot)
        gen.set_local(pat.slot)

        gen.push_local(arg2.slot)
        gen.set_local(pat.slot)
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

  describe "#binds?" do
    context "when the receiver pattern binds" do
      subject { described_class.new(wildcard(:a)) }

      it "returns true" do
        expect(subject.binds?).to eq(true)
      end
    end

    context "when any of the argument patterns bind" do
      subject { described_class.new(wildcard, [wildcard(:a)]) }

      it "returns true" do
        expect(subject.binds?).to eq(true)
      end
    end

    context "when neither the receiver nor the arguments bind" do
      it "returns false" do
        expect(subject.binds?).to eq(false)
      end
    end
  end
end

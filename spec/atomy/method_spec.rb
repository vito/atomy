require "spec_helper"

require "atomy/method"
require "atomy/module"
require "atomy/pattern"
require "atomy/pattern/equality"
require "atomy/pattern/message"
require "atomy/pattern/wildcard"

describe Atomy::Method do
  subject { described_class.new(:foo) }

  def wildcard(name = nil)
    Atomy::Pattern::Wildcard.new(name)
  end

  def equality(val)
    Atomy::Pattern::Equality.new(val)
  end

  def message(receiver = wildcard, arguments = [])
    Atomy::Pattern::Message.new(receiver, arguments)
  end

  def block(&blk)
    blk.block
  end

  describe "#add_branch" do
    it "creates a branch and inserts it" do
      expect {
        subject.add_branch(Atomy::Pattern.new, block {}, block {})
      }.to change { subject.branches.size }.from(0).to(1)
    end

    it "inserts branches with unique names" do
      subject.add_branch(equality(0), block {}, block {})
      subject.add_branch(equality(1), block {}, block {})
      expect(subject.branches.collect(&:name).uniq.size).to eq(2)
    end

    it "appends the branch to the end if none preclude it" do
      subject.add_branch(equality(0), block {}, block { :new })
      subject.add_branch(wildcard, block {}, block { :old })
      expect(subject.branches.collect(&:name).uniq.size).to eq(2)
      expect(subject.branches.first.body.call).to eq(:new)
    end

    it "inserts the branch before any branches that preclude it" do
      subject.add_branch(wildcard, block {}, block { :old })
      subject.add_branch(equality(0), block {}, block { :new })
      expect(subject.branches.collect(&:name).uniq.size).to eq(2)
      expect(subject.branches.first.body.call).to eq(:new)
    end

    it "replaces a branch with the new one if they preclude each other" do
      subject.add_branch(equality(0), block {}, block { :old })
      subject.add_branch(equality(0), block {}, block { :new })
      expect(subject.branches.collect(&:name).uniq.size).to eq(1)
      expect(subject.branches.first.body.call).to eq(:new)
    end
  end

  describe "#build" do
    it "returns a CompiledCode" do
      expect(subject.build).to be_a(Rubinius::CompiledCode)
    end

    it "has the method name as the code's name" do
      expect(subject.build.name).to eq(:foo)
    end

    it "has :__wrapper__ as the code's file" do
      expect(subject.build.file).to eq(:__wrapper__)
    end

    describe "invoking the method" do
      let(:target) { Atomy::Module.new }
      let(:branch) { subject.add_branch(message, block { true }, block { :ok }) }
      let(:method_name) { :foo }

      subject { described_class.new(method_name) }

      def define!
        # prep the branch
        Rubinius.add_method(
          branch.name,
          Rubinius::BlockEnvironment::AsMethod.new(branch.body),
          target,
          :private)

        # prep the matcher branch
        Rubinius.add_method(
          branch.matcher_name,
          Rubinius::BlockEnvironment::AsMethod.new(branch.matcher),
          target,
          :private)

        Rubinius.add_method(method_name, subject.build, target, :public)
      end

      it "can be invoked when attached to a target" do
        define!
        expect(target.foo).to eq(:ok)
      end

      context "when the pattern is inlineable" do
        let(:branch) do
          subject.add_branch(
            message(wildcard, [equality(0)]),
            block { |_| true },
            block { |_| :ok })
        end

        it "inlines the matching logic" do
          allow(branch).to receive(:matcher_name).and_return(:foo_matcher)
          define!
          expect(target).to_not receive(branch.matcher_name)
          expect(target.foo(0)).to eq(:ok)
        end

        it "still performs the pattern-matching" do
          allow(branch).to receive(:matcher_name).and_return(:foo_matcher)
          define!
          expect { target.foo(1) }.to raise_error(Atomy::MessageMismatch)
        end
      end

      context "when a block is given" do
        let(:branch) do
          subject.add_branch(message, block { true }, block { |&blk| blk })
        end

        before { define! }

        it "is not passed to the branch" do
          define!
          expect(target.foo {}).to be_nil
        end
      end

      context "when there is a base case" do
        let(:branch) do
          subject.add_branch(
            message(wildcard, [equality(0)]),
            block { true },
            block { |&blk| blk })
        end

        before do
          expect(subject).to receive(:has_base_case?).and_return(true)
        end

        it "does not raise MessageMismatch" do
          define!
          expect(target.foo(1)).to be_nil
        end
      end

      context "when no patterns match" do
        before { define! }

        let(:branch) do
          subject.add_branch(
            message(wildcard, [equality(0)]),
            block { |v| v == 0 },
            block { |x| :ok })
        end

        context "and the method exists on the superclass" do
          let(:a) do
            Class.new do
              def foo(x)
                :from_a
              end
            end
          end

          let(:b) { Class.new(a) }

          let(:target) { b }

          it "invokes the superclass's method" do
            expect(target.new.foo(0)).to eq(:ok)
            expect(target.new.foo(1)).to eq(:from_a)
          end

          context "and the method name is :initialize" do
            let(:method_name) { :initialize }

            it "raises a MessageMismatch" do
              expect {
                target.new(1)
              }.to raise_error(Atomy::MessageMismatch)
            end
          end
        end

        context "and the method does NOT exist on the superclass" do
          it "raises a MessageMismatch" do
            expect { target.foo(1) }.to raise_error(Atomy::MessageMismatch)
          end
        end
      end
    end
  end
end

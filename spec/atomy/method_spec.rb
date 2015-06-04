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
        subject.add_branch(Atomy::Pattern.new, block {}, [])
      }.to change { subject.branches.size }.from(0).to(1)
    end

    it "inserts branches with unique names" do
      subject.add_branch(equality(0), block {}, [])
      subject.add_branch(equality(1), block {}, [])
      expect(subject.branches.collect(&:name).uniq.size).to eq(2)
    end

    it "appends the branch to the end" do
      subject.add_branch(equality(0), block { :new }, [])
      subject.add_branch(wildcard, block { :old }, [])
      expect(subject.branches.collect(&:name).uniq.size).to eq(2)
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
      let(:branch) { subject.add_branch(message, block { :ok }, []) }
      let(:method_name) { :foo }

      subject { described_class.new(method_name) }

      def define!
        # prep the branch
        Rubinius.add_method(
          branch.name,
          Rubinius::BlockEnvironment::AsMethod.new(branch.body),
          target,
          :private)

        Rubinius.add_method(method_name, subject.build, target, :public)
      end

      it "can be invoked when attached to a target" do
        define!
        expect(target.foo).to eq(:ok)
      end

      context "when a block is given" do
        let(:branch) do
          subject.add_branch(message, block { |&blk| blk }, [])
        end

        before { define! }

        it "is not passed to the branch" do
          define!
          expect(target.foo {}).to be_nil
        end
      end

      context "when no patterns match" do
        before { define! }

        let(:branch) do
          subject.add_branch(
            message(wildcard, [equality(0)]),
            block { :ok },
            [])
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

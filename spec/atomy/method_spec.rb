require "spec_helper"

require "atomy/method"
require "atomy/module"
require "atomy/pattern"
require "atomy/pattern/equality"
require "atomy/pattern/wildcard"

describe Atomy::Method do
  subject { described_class.new(:foo) }

  def wildcard(name = nil)
    Atomy::Pattern::Wildcard.new(name)
  end

  def equality(val)
    Atomy::Pattern::Equality.new(val)
  end

  def block(&blk)
    blk.block
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

    it "has a basic constant scope, so that #under_context works" do
      scope = subject.build.scope
      expect(scope).to_not be_nil
      expect(scope.module).to eq(Object)
    end

    describe "invoking the method" do
      let(:target) { Atomy::Module.new }
      let(:branch) { Atomy::Method::Branch.new(wildcard, [], []) { :ok } }
      let(:method_name) { :foo }

      subject { described_class.new(method_name) }

      before do
        subject.add_branch(branch)
        Rubinius.add_method(method_name, subject.build, target, :public)
      end

      it "can be invoked when attached to a target" do
        expect(target.foo).to eq(:ok)
      end

      context "when a block is given" do
        let(:branch) { Atomy::Method::Branch.new(wildcard, [], []) { |&blk| blk } }

        it "is passed to the branch" do
          blk = proc {}
          expect(target.foo(&blk)).to eq(blk)
        end
      end

      context "when no patterns match" do
        let(:branch) { Atomy::Method::Branch.new(wildcard, [equality(0)], []) { :ok } }

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

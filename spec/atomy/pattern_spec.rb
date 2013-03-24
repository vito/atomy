require "spec_helper"

require "atomy/bootstrap"
require "atomy/pattern"

describe Atomy::Pattern do
  let(:compile_module) { Atomy::Module.new { use Atomy::Bootstrap } }

  let(:pattern) { described_class.new }

  subject { pattern }

  describe "#match" do
    subject do
      Class.new do
        def initialize(pattern)
          @pattern = pattern
        end

        def bytecode(gen, mod)
          gen.push_literal("some-value")
          @pattern.match(gen, mod)
        end
      end.new(pattern)
    end

    let(:wildcard) do
      Class.new(described_class) do
        def initialize(name = nil)
          @name = name
        end

        def wildcard?
          true
        end

        def binds?
          !!@name
        end

        def deconstruct(gen, mod)
          assign = assignment_local(gen, @name)
          assign.set_bytecode(gen)
        end
      end
    end

    context "when the pattern is a wildcard" do
      context "and it has bindings" do
        let(:pattern) { wildcard.new(:abc) }

        it_compiles_as do |gen|
          gen.push_literal("some-value")
          gen.set_local(0)
        end
      end

      context "and it does NOT have bindings" do
        let(:pattern) { wildcard.new }

        it_compiles_as do |gen|
          gen.push_literal("some-value")
        end
      end
    end
  end

  describe "#assignment_local" do
    context "when a local is found" do
      context "and its depth is zero" do
        let(:gen) do
          g = Rubinius::Generator.new
          g.push_state(Atomy::LocalState.new)
          @local = g.state.scope.new_local(:a)
          g
        end

        it "returns the found local" do
          assignment = subject.assignment_local(gen, :a)
          expect(assignment.depth).to eq(0)
          expect(assignment.slot).to eq(@local.slot)
        end
      end

      context "and its depth is greater than zero" do
        let(:gen) do
          g = Rubinius::Generator.new

          parent = Atomy::LocalState.new
          @local = parent.new_local(:a)

          g.push_state(Atomy::LocalState.new)
          g.state.scope.parent = parent

          g
        end

        context "and 'set' is false" do
          it "returns a new local" do
            assignment = subject.assignment_local(gen, :a, false)
            expect(assignment.depth).to eq(0)
            expect(assignment.slot).to eq(@local.slot)
          end
        end

        context "and 'set' is true" do
          it "returns the found local" do
            assignment = subject.assignment_local(gen, :a, true)
            expect(assignment.depth).to eq(1)
            expect(assignment.slot).to eq(@local.slot)
          end
        end
      end
    end

    context "when a local is NOT found" do
      let(:gen) do
        g = Rubinius::Generator.new
        g.push_state(Atomy::LocalState.new)
        g
      end

      it "returns a new local" do
        assignment = subject.assignment_local(gen, :a, true)
        expect(assignment.depth).to eq(0)
        expect(assignment.slot).to eq(0)
      end
    end
  end
end

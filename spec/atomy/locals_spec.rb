require "spec_helper"

require "atomy/locals"

describe Atomy::LocalState do
  describe "#new_local" do
    it "returns the new variable" do
      expect(subject.new_local(:a)).to be_a(
        CodeTools::Compiler::LocalVariable)
    end

    it "increases the local count" do
      expect {
        subject.new_local(:a)
      }.to change { subject.local_count }.from(0).to(1)
    end

    it "has the local name in #local_names" do
      expect {
        subject.new_local(:a)
      }.to change { subject.local_names }.from([]).to([:a])
    end

    it "registers the local in #variables" do
      expect(subject.variables[:a]).to be_nil
      var = subject.new_local(:a)
      expect(subject.variables[:a]).to eq(var)
    end
  end

  describe "#search_local" do
    context "when a local is not found" do
      it "returns nil" do
        expect(subject.search_local(:some_invalid_local)).to be_nil
      end
    end

    context "when a local is found in itself" do
      before do
        @a = subject.new_local(:a)
      end

      it "returns a reference to it with depth 0" do
        found = subject.search_local(:a)
        expect(found).to be
        expect(found.depth).to eq(0)
        expect(found.slot).to eq(@a.slot)
      end
    end

    context "when a local is found in its parent" do
      before do
        subject.parent = described_class.new
        @a = subject.parent.new_local(:a)
      end

      it "returns a reference to it with depth 1" do
        found = subject.search_local(:a)
        expect(found).to be
        expect(found.depth).to eq(1)
        expect(found.slot).to eq(@a.slot)
      end
    end

    context "when a local is found in its parent's parent" do
      before do
        subject.parent = described_class.new
        subject.parent.parent = described_class.new
        @a = subject.parent.parent.new_local(:a)
      end

      it "returns a reference to it with depth 2" do
        found = subject.search_local(:a)
        expect(found).to be
        expect(found.depth).to eq(2)
        expect(found.slot).to eq(@a.slot)
      end
    end
  end
end

describe Atomy::EvalLocalState do
  let(:variable_scope) { Rubinius::VariableScope.current }

  subject { described_class.new(variable_scope) }

  describe "#new_local" do
    it "returns an EvalLocalVariable" do
      expect(subject.new_local(:a)).to be_a(
        CodeTools::Compiler::EvalLocalVariable)
    end

    it "does not increase the local count" do
      expect {
        subject.new_local(:a)
      }.to_not change { subject.local_count }
    end

    it "does not have the local name in #local_names" do
      expect {
        subject.new_local(:a)
      }.to_not change { subject.local_names }
    end

    it "registers the local in #variables" do
      expect(subject.variables[:a]).to be_nil
      var = subject.new_local(:a)
      expect(subject.variables[:a]).to eq(var)
    end
  end

  describe "#search_local" do
    context "when a local is not found" do
      it "returns nil" do
        expect(subject.search_local(:some_invalid_local)).to be_nil
      end
    end

    context "when a local is found in itself" do
      before do
        @a = subject.new_local(:a)
      end

      it "returns an EvalLocalReference" do
        found = subject.search_local(:a)
        expect(found).to be_a(CodeTools::Compiler::EvalLocalReference)
      end
    end

    context "when a local is found in its parent" do
      let(:variable_scope) do
        eval("a = 1")

        proc {
          Rubinius::VariableScope.current
        }.call
      end

      it "returns a reference to it with depth 1" do
        found = subject.search_local(:a)
        expect(found).to be
      end
    end

    context "when a local is found in its parent's parent" do
      let(:variable_scope) do
        eval("a = 1")

        proc {
          proc {
            Rubinius::VariableScope.current
          }.call
        }.call
      end


      it "returns a reference to it with depth 2" do
        found = subject.search_local(:a)
        expect(found).to be
      end
    end
  end
end

require "spec_helper"

require "atomy/parser"

describe Atomy::Parser do
  describe ".parse_file" do
    it "returns the parsed nodes from the file as a Sequence" do
      result = subject.parse_file(fixture("parser/parse_file/simple.ay"))
      expect(result).to be_a(Atomy::Grammar::AST::Sequence)
    end

    context "when parsing fails" do
      it "raises a SyntaxError" do
        expect {
          subject.parse_file(fixture("parser/parse_file/invalid.ay"))
        }.to raise_error(SyntaxError)
      end
    end
  end

  describe ".parse_string" do
    it "returns the parsed nodes as a Sequence" do
      result = subject.parse_string("hello")
      expect(result).to be_a(Atomy::Grammar::AST::Sequence)
    end

    context "when parsing fails" do
      it "raises a SyntaxError" do
        expect {
          subject.parse_string("#%$%")
        }.to raise_error(SyntaxError)
      end
    end
  end
end

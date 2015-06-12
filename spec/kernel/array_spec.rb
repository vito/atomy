require "spec_helper"

require "atomy/codeloader"

describe "array kernel" do
  subject { Atomy::Module.new { use(require("array")) } }

  it "implements array consing syntax" do
    expect(subject.evaluate(ast('1 . [2, 3]'))).to eq([1, 2, 3])
  end

  it "implements array de-consing pattern-matching syntax" do
    expect(subject.evaluate(seq('(a . bs) = [1, 2, 3], [a, bs]'))).to eq([1, [2, 3]])
    expect { subject.evaluate(seq('(a . bs) = [], [a, bs]')) }.to raise_error(Atomy::PatternMismatch)
  end
end

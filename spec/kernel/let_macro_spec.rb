require "spec_helper"

require "atomy/codeloader"

describe "let-macro kernel" do
  subject { Atomy::Module.new { use(require("let-macro")) } }

  it "defines the given macros for the duration of the body" do
    expect(subject.evaluate(seq(<<EOF))).to eq([5, 4])
val = let-macro((2 + 2) = '5): 2 + 2
[val, 2 + 2]
EOF
  end

  it "has the macros in-scope of each other" do
    expect(subject.evaluate(seq(<<EOF))).to eq([5, 4, 7])
val = let-macro((2 + 2) = '5, (3 + 4) = '(2 + 2)): 3 + 4
[val, 2 + 2, 3 + 4]
EOF
  end
end

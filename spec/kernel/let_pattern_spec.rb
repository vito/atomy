require "spec_helper"

require "atomy/codeloader"

describe "let-pattern kernel" do
  subject { Atomy::Module.new { use(require("let-pattern")) } }

  it "defines the given pattern for the duration of the body" do
    expect(subject.evaluate(seq(<<EOF))).to eq(5)
let-pattern(Foo = pattern('5)):
  Foo = 5
EOF

    expect { subject.evaluate(seq(<<EOF)) }.to raise_error(Atomy::PatternMismatch)
let-pattern(Foo = pattern('5)):
  Foo = 6
EOF
  end

  it "has the pattern in-scope of each other" do
    expect(subject.evaluate(seq(<<EOF))).to eq(5)
let-pattern(Foo = pattern('5), Bar = pattern(`(baz & Foo))):
  Bar = 5
  baz
EOF
  end
end

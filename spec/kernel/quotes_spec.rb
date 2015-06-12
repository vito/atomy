require "spec_helper"

require "atomy/codeloader"

describe "quotes kernel" do
  subject { Atomy::Module.new { use(require("quotes")) } }

  it "implements word list literals" do
    expect(subject.evaluate(ast('w"foo bar"'))).to eq(["foo", "bar"])
  end

  it "implements symbol list literals" do
    expect(subject.evaluate(ast('s"foo bar fizz-buzz"'))).to eq([:foo, :bar, :fizz_buzz])
  end

  it "implements raw string literals" do
    expect(subject.evaluate(ast('raw"foo\nbar"'))).to eq("foo\\nbar")
  end

  it "defines a macro for defining more macro-quoters" do
    subject.evaluate(ast("
      macro-quoter(foo) [raw, flags, value]:
        Atomy Code StringLiteral new([raw, flags, value] inspect)
    "), subject.compile_context)

    expect(subject.evaluate(ast('foo"bar\nbaz"'), subject.compile_context)).to eq(%Q{["bar\\nbaz", [], "bar\nbaz"]})
    expect(subject.evaluate(ast('foo"bar\nbaz"(a, b)'), subject.compile_context)).to eq(%Q{["bar\\nbaz", [:a, :b], "bar\nbaz"]})
  end
end

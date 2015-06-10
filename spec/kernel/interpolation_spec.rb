require "spec_helper"

require "atomy/codeloader"

describe "interpolation kernel" do
  subject { Atomy::Module.new { use(require_kernel("interpolation")) } }

  it "implements string interpolation literals" do
    expect(subject.evaluate(ast('i"foo bar"'))).to eq("foo bar")
    expect(subject.evaluate(ast('i"foo #{1 + 1} bar"'))).to eq("foo 2 bar")
    expect(subject.evaluate(ast('i"foo\nbar"'))).to eq("foo\nbar")
  end

  it "implements symbol interpolation literals" do
    expect(subject.evaluate(ast('."foo bar"'))).to eq(:"foo bar")
    expect(subject.evaluate(ast('."foo #{1 + 1} bar"'))).to eq(:"foo 2 bar")
    expect(subject.evaluate(ast('."foo\nbar"'))).to eq(:"foo\\nbar")
  end
end

require "spec_helper"

require "atomy/codeloader"

describe "range kernel" do
  subject { Atomy::Module.new { use(require("range")) } }

  it "implements range literals" do
    expect(subject.evaluate(ast('1 .. 2'))).to eq(1 .. 2)
    expect(subject.evaluate(ast('1 ... 2'))).to eq(1 ... 2)
  end
end

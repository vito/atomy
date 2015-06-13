require "spec_helper"

require "atomy/codeloader"

describe "file kernel" do
  subject { Atomy::Module.new { use(require("file")) } }

  it "implements __FILE__" do
    expect(subject.evaluate(ast('__FILE__'))).to eq(__FILE__)
  end
end

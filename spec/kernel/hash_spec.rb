require "spec_helper"

require "atomy/codeloader"

describe "hash kernel" do
  subject { Atomy::Module.new { use(require("hash")) } }

  it "implements hash literals" do
    expect(subject.evaluate(ast('#{ .a -> 1, .b -> 2, 3 -> 4 }'))).to eq({
      :a => 1,
      :b => 2,
      3 => 4,
    })
  end
end

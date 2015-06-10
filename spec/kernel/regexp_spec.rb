require "spec_helper"

require "atomy/codeloader"

describe "regexp kernel" do
  subject { Atomy::Module.new { use(require_kernel("regexp")) } }

  it "implements regexp literals" do
    expect(subject.evaluate(ast('r"foo \b#{2}\b"'))).to eq(/foo \b2\b/u)
    expect(subject.evaluate(ast('r"foo \b#{2}\b"(m)'))).to eq(/foo \b2\b/mu)
    expect(subject.evaluate(ast('r"foo \b#{2}\b"(i)'))).to eq(/foo \b2\b/iu)
    expect(subject.evaluate(ast('r"foo \b#{2}\b"(x)'))).to eq(/foo \b2\b/xu)
    expect(subject.evaluate(ast('r"foo \b#{2}\b"(m, i, x)'))).to eq(/foo \b2\b/mixu)
  end
end

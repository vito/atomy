require "spec_helper"

require "atomy/codeloader"

describe "core kernel" do
  subject { Atomy::Module.new { use(require_kernel("core")) } }

  it "implements do: notation for evaluating sequences" do
    expect(subject).to receive(:foo).and_return(1)
    expect(subject).to receive(:bar).and_return(2)
    expect(subject.evaluate(ast("do: foo, bar"), subject.compile_context)).to eq(2)
  end

  it "implements a macro-defining macro" do
    subject.evaluate(ast("macro(1): '2"), subject.compile_context)
    expect(subject.evaluate(ast("1"))).to eq(2)
  end

  it "implements sending messages to receivers" do
    expect(subject.evaluate(ast("1 inspect"))).to eq("1")
  end

  it "implements sending messages to receivers, with arguments" do
    expect(subject.evaluate(ast("128 to-s(16)"))).to eq("80")
  end

  it "implements nested constant notation" do
    expect(subject.evaluate(ast("Atomy Module"))).to eq(Atomy::Module)
  end

  it "implements method definition notation" do
    subject.evaluate(ast("def(foo(a)): a + 1"), subject.compile_context)
    expect(subject.foo(41)).to eq(42)
  end

  it "implements local variable assignment notation" do
    expect(subject.evaluate(seq("a = 1, a + 2"))).to eq(3)
  end
end

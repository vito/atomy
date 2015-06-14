require "spec_helper"

require "atomy/codeloader"

describe "loop kernel" do
  subject { Atomy::Module.new { use(require("loop")) } }

  describe "while(x): y" do
    it "continuously runs as long as evaluating 'x' is truthy" do
      a = 1
      expect(subject.evaluate(seq("while(a != 10): a =! (a + 1)"))).to be_nil
      expect(a).to eq(10)
    end

    describe "break" do
      it "breaks the outer loop" do
        a = 1
        expect(subject.evaluate(seq(<<EOF))).to eq(nil)
while(a < 10):
  a += 1

  when(a == 3):
    break
EOF
        expect(a).to eq(3)
      end
    end

    describe "next" do
      it "continues to the next iteration" do
        as = []
        a = 0
        expect(subject.evaluate(seq(<<EOF))).to eq(nil)
while(a < 5):
  a += 1

  when(a == 3):
    next

  as << a
EOF

        expect(as).to eq([1, 2, 4, 5])
      end
    end
  end

  describe "until(x): y" do
    it "continuously runs as long as evaluating 'x' is falsy" do
      a = 1
      expect(subject.evaluate(seq("until(a == 10): a =! (a + 1)"))).to be_nil
      expect(a).to eq(10)
    end

    describe "break" do
      it "breaks the outer loop" do
        a = 1
        expect(subject.evaluate(seq(<<EOF))).to eq(nil)
until(a == 10):
  a += 1

  when(a == 3):
    break
EOF
        expect(a).to eq(3)
      end
    end

    describe "next" do
      it "continues to the next iteration" do
        as = []
        a = 0
        expect(subject.evaluate(seq(<<EOF))).to eq(nil)
until(a == 5):
  a += 1

  when(a == 3):
    next

  as << a
EOF

        expect(as).to eq([1, 2, 4, 5])
      end
    end
  end
end

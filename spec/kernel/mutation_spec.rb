require "spec_helper"

require "atomy/codeloader"
require "atomy/message_structure"
require "atomy/node/equality"

describe "mutation kernel" do
  subject { Atomy::Module.new { use(require("mutation")) } }

  mutations = [
    [1, :+, 1, 2],
    [1, :-, 1, 0],
    [2, :*, 5, 10],
    [5, :**, 2, 25],
    [10, :/, 5, 2],
    [258, :&, 2, 2],
    [256, :|, 2, 258],
  ]

  describe "local variable mutation" do
    mutations.each do |l, o, r, v|
      it "implements #{o}=" do
        expect(subject.evaluate(seq("a = #{l}, { a #{o}= #{r} } call, a"))).to eq(v)
      end
    end

    context "with locals ending in !" do
      mutations.each do |l, o, r, v|
        it "implements #{o}=" do
          expect(subject.evaluate(seq("a! = #{l}, { a! #{o}= #{r} } call, a!"))).to eq(v)
        end
      end
    end

    context "with locals ending in ?" do
      mutations.each do |l, o, r, v|
        it "implements #{o}=" do
          expect(subject.evaluate(seq("a? = #{l}, { a? #{o}= #{r} } call, a?"))).to eq(v)
        end
      end
    end
  end

  describe "attribute mutation" do
    context "with a normal word attribute" do
      let(:klass) { Class.new { attr_accessor :a } }
      let(:object) { klass.new }

      mutations.each do |l, o, r, v|
        it "only evaluates the receiver once" do
          object.a = l
          expect(self).to receive(:object).once.and_call_original
          expect(subject.evaluate(seq("object a #{o}= #{r}"))).to eq(v)
        end

        it "implements #{o}=" do
          expect(subject.evaluate(seq("object a = #{l}, { object a #{o}= #{r} } call, object a"))).to eq(v)
        end
      end
    end

    context "with attributes ending in !" do
      let(:klass) { Class.new { attr_accessor :a! } }
      let(:object) { klass.new }

      mutations.each do |l, o, r, v|
        it "only evaluates the receiver once" do
          object.send(:"a!=", l)
          expect(self).to receive(:object).once.and_call_original
          expect(subject.evaluate(seq("object a! #{o}= #{r}"))).to eq(v)
        end

        it "implements #{o}=" do
          expect(subject.evaluate(seq("object a! = #{l}, { object a! #{o}= #{r} } call, object a!"))).to eq(v)
        end
      end
    end

    context "with attributes ending in ?" do
      let(:klass) { Class.new { attr_accessor :a? } }
      let(:object) { klass.new }

      mutations.each do |l, o, r, v|
        it "only evaluates the receiver once" do
          object.send(:"a?=", l)
          expect(self).to receive(:object).once.and_call_original
          expect(subject.evaluate(seq("object a? #{o}= #{r}"))).to eq(v)
        end

        it "implements #{o}=" do
          expect(subject.evaluate(seq("object a? = #{l}, { object a? #{o}= #{r} } call, object a?"))).to eq(v)
        end
      end
    end
  end

  describe "index mutation" do
    context "with a normal word attribute" do
      let(:object) { [0, 1, 2, 3, 4, 5, 6, 7] }
      let(:index_1) { 2 }
      let(:index_2) { 3 }

      it "only evaluates the receiver and indices once" do
        expect(self).to receive(:object).once.and_call_original
        expect(self).to receive(:index_1).once.and_call_original
        expect(self).to receive(:index_2).once.and_call_original
        expect(subject.evaluate(seq("object[index-1, index-2] *= 2"))).to eq([2, 3, 4, 2, 3, 4])
      end

      mutations.each do |l, o, r, v|
        it "implements #{o}=" do
          object[index_1] = l
          expect(subject.evaluate(seq("object[index-1] #{o}= #{r}, object[index-1]"))).to eq(v)
        end
      end
    end
  end

  describe "instance variable mutation" do
    mutations.each do |l, o, r, v|
      it "implements #{o}=" do
        expect(subject.evaluate(seq("@a = #{l}, @a #{o}= #{r}, @a"))).to eq(v)
      end
    end

    context "with instance variables ending in !" do
      mutations.each do |l, o, r, v|
        it "implements #{o}=" do
          expect(subject.evaluate(seq("@a! = #{l}, @a! #{o}= #{r}, @a!"))).to eq(v)
        end
      end
    end

    context "with instance variables ending in ?" do
      mutations.each do |l, o, r, v|
        it "implements #{o}=" do
          expect(subject.evaluate(seq("@a? = #{l}, @a? #{o}= #{r}, @a?"))).to eq(v)
        end
      end
    end
  end

  describe "global variable mutation" do
    mutations.each do |l, o, r, v|
      it "implements #{o}=" do
        $a = l
        expect(subject.evaluate(seq("$a #{o}= #{r}, $a"))).to eq(v)
      end
    end

    context "with global variables ending in !" do
      mutations.each do |l, o, r, v|
        it "implements #{o}=" do
          expect(subject.evaluate(seq("$a! = #{l}, $a! #{o}= #{r}, $a!"))).to eq(v)
        end
      end
    end

    context "with global variables ending in ?" do
      mutations.each do |l, o, r, v|
        it "implements #{o}=" do
          expect(subject.evaluate(seq("$a? = #{l}, $a? #{o}= #{r}, $a?"))).to eq(v)
        end
      end
    end
  end
end

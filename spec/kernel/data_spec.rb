require "spec_helper"

require "atomy/codeloader"

describe "data kernel" do
  subject { Atomy::Module.new { use(require("data")) } }

  it "returns nil" do
    expect(subject.evaluate(ast("data(Point(@x, @y))"), subject.compile_context)).to be_nil
  end

  class DataParent
  end

  def self.it_defines(parent, klass, attrs = {})
    describe "the defined #{klass}" do
      let(:defined_klass) { subject.const_get(klass) }

      it "is constructed with the given arguments" do
        defined_klass.new(*attrs.values) # depends on hash order
      end

      it "has the correct superclass" do
        superclass = parent
        if superclass.is_a?(Symbol)
          superclass = subject.const_get(superclass)
        end

        expect(defined_klass.direct_superclass).to eq(superclass)
      end

      it "defines attribute accessors for each instance variable" do
        point = defined_klass.new(*attrs.values)

        attrs.each do |a, v|
          expect(point.public_send(a)).to eq(v)
        end
      end

      it "defines a prettier #inspect" do
        args = attrs.values.collect(&:to_s).join(", ")
        expect(defined_klass.new(*attrs.values).inspect).to eq("#{klass}(#{args})")
      end

      it "can be pattern-matched" do
        pats = attrs.keys.collect(&:to_s).join(", ")
        args = attrs.values.collect(&:to_s).join(", ")
        expect(subject.evaluate(seq("
          #{klass}(#{pats}) = #{klass} new(#{args})
          [#{pats}]
        "), subject.compile_context)).to eq(attrs.values)
      end

      it "can be the target of a definition" do
        pats = attrs.keys.collect(&:to_s).join(", ")
        subject.evaluate(ast("def(#{klass}(#{pats}) some-method): .ok"), subject.compile_context)
        expect(defined_klass.new(*attrs.values).some_method).to eq(:ok)
        expect(Object.new).to_not respond_to(:some_method)
      end

      unless attrs.empty?
        context "when infinitely recursive" do
          it "pretty-prints with dots at the recursion point" do
            point = defined_klass.new(*attrs.values)
            point.public_send(:"#{attrs.keys.first}=", point)
            value_args = attrs.values.collect(&:to_s)
            value_args[0] = "#{klass}(...)"
            values = value_args.join(", ")
            expect(point.inspect).to eq("#{klass}(#{values})")
          end
        end
      end
    end
  end

  describe "a class defined with no children and no parent" do
    before do
      subject.evaluate(ast("data(Point(@x, @y))"), subject.compile_context)
    end

    it_defines Object, :Point, x: 1, y: 2
  end

  describe "a class defined with no children and no parent, with default values" do
    before do
      subject.evaluate(ast("data(Point(@x, @y = 2))"), subject.compile_context)
    end

    it_defines Object, :Point, x: 1, y: 2

    it "defaults the arguments" do
      expect(subject::Point.new(1).y).to eq(2)
    end
  end

  describe "a class defined with a parent" do
    before do
      subject.evaluate(ast("DataParent data(Point(@x, @y))"), subject.compile_context)
    end

    it_defines DataParent, :Point, x: 1, y: 2
  end

  describe "a class defined with children" do
    before do
      subject.evaluate(ast("
        data(Shape(@area)):
          Square(@width, @height)
          Triangle(@a, @b, @c)
      "), subject.compile_context)
    end

    it_defines Object, :Shape, area: 42
    it_defines :Shape, :Square, width: 20, height: 20
    it_defines :Shape, :Triangle, a: 1, b: 2, c: 3
  end

  describe "many classes defined in one block" do
    before do
      subject.evaluate(ast("
        data:
          Square(@width, @height)
          Rectangle(@width, @height)
      "), subject.compile_context)
    end

    it_defines Object, :Square, width: 20, height: 20
    it_defines Object, :Rectangle, width: 30, height: 40
  end

  describe "many classes defined in one block with a parent" do
    before do
      subject.evaluate(ast("
        DataParent data:
          Square(@width, @height)
          Rectangle(@width, @height)
      "), subject.compile_context)
    end

    it_defines DataParent, :Square, width: 20, height: 20
    it_defines DataParent, :Rectangle, width: 30, height: 40
  end

  describe "defining a class hierarchy" do
    before do
      subject.evaluate(ast("
        data(Shape):
          Rectangle(@width, @height):
            Square(@width, @height)

          Triangle:
            Isosceles(@a, @b, @c)
            Right
      "), subject.compile_context)
    end

    it_defines Object, :Shape
    it_defines :Shape, :Rectangle, width: 30, height: 40
    it_defines :Rectangle, :Square, width: 20, height: 20
    it_defines :Shape, :Triangle
    it_defines :Triangle, :Isosceles, a: 1, b: 2, c: 3
    it_defines :Triangle, :Right
  end

  describe "defining a class hierarchy with a parent" do
    before do
      subject.evaluate(ast("
        DataParent data(Shape):
          Rectangle(@width, @height):
            Square(@width, @height)

          Triangle:
            Isosceles(@a, @b, @c)
            Right
      "), subject.compile_context)
    end

    it_defines DataParent, :Shape
    it_defines :Shape, :Rectangle, width: 30, height: 40
    it_defines :Rectangle, :Square, width: 20, height: 20
    it_defines :Shape, :Triangle
    it_defines :Triangle, :Isosceles, a: 1, b: 2, c: 3
    it_defines :Triangle, :Right
  end

  describe "defining a class hierarchy with a parent and no initial parent" do
    before do
      subject.evaluate(ast("
        DataParent data:
          Rectangle(@width, @height):
            Square(@width, @height)

          Triangle:
            Isosceles(@a, @b, @c)
            Right
      "), subject.compile_context)
    end

    it_defines DataParent, :Rectangle, width: 30, height: 40
    it_defines :Rectangle, :Square, width: 20, height: 20
    it_defines DataParent, :Triangle
    it_defines :Triangle, :Isosceles, a: 1, b: 2, c: 3
    it_defines :Triangle, :Right
  end
end

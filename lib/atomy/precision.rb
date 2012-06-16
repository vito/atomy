module Atomy::Patterns
  # pattern precision hierarchy, from least precise to most
  [ [ Any, BlockPass, Splat, Attribute,
      NamedClass, NamedGlobal, NamedInstance
    ],

    [Constant, SingletonClass],

    [HeadTail],

    [List, QuasiQuote],

    [Match, Literal, Quote]
  ].each.with_index do |ps, i|
    ps.each do |a|
      a.send(:define_method, :precision) do
        i
      end
    end
  end

  class Pattern
    def precision
      0
    end
  end

  class Named
    def precision
      pattern.precision
    end
  end

  class Pattern
    def <=>(other)
      case other
      when Default, Named, BlockPass, Splat
        self <=> other.pattern
      when Predicate
        -1
      else
        precision <=> other.precision
      end
    end
  end

  class Predicate
    def <=>(other)
      case other
      when Match, Literal, Quote
        -1
      when self.class
        0
      else
        1
      end
    end
  end

  class Match
    def <=>(other)
      return 0 if other.is_a?(self.class)
      1
    end
  end

  class Literal
    def <=>(other)
      return 0 if other.is_a?(self.class)
      1
    end
  end

  class BlockPass
    def <=>(other)
      case other
      when self.class
        pattern <=> other.pattern
      else
        pattern <=> other
      end
    end
  end

  class Constant
    def <=>(other)
      return super unless other.is_a?(self.class)

      if value.is_a?(Module) && other.value.is_a?(Module)
        if res = value <=> other.value
          -res
        else
          0
        end
      else
        0
      end
    end
  end

  class HeadTail
    def <=>(other)
      return super unless other.is_a?(self.class)
      Atomy::Patterns.compare([head, tail], [other.head, other.tail])
    end
  end

  class List
    def <=>(other)
      return super unless other.is_a?(self.class)

      varying, required = splat_info
      ovarying, orequired = other.splat_info

      unless varying && ovarying && required == orequired
        if varying && required > orequired
          return 1
        elsif varying && required <= orequired
          return -1
        elsif ovarying && orequired > required
          return -1
        elsif ovarying && orequired <= required
          return 1
        end
      end

      no_splats = patterns.reject { |p| p.is_a?(Splat) }
      other_no_splats = other.patterns.reject { |p| p.is_a?(Splat) }
      Atomy::Patterns.compare(no_splats, other_no_splats)
    end
  end

  class Splat
    def <=>(other)
      case other
      when self.class
        pattern <=> other.pattern
      else
        pattern <=> other
      end
    end
  end

  class Default
    def <=>(other)
      if other.is_a?(self.class)
        pattern <=> other.pattern
      else
        pattern <=> other
      end
    end
  end

  class Named
    def <=>(other)
      if other.is_a?(self.class)
        pattern <=> other.pattern
      else
        pattern <=> other
      end
    end
  end

  class QuasiQuote
    def <=>(other)
      return super unless other.is_a?(self.class)
      PrecisionWalker.new.go(@quoted, other.quoted)
    end

    class PrecisionWalker
      def initialize
        @total = 0
        @depth = 0
      end

      def fail(type = 0)
        throw(:incomparable, type)
      end

      def compare(x, y)
        if x.is_a?(Atomy::AST::QuasiQuote) && \
            y.is_a?(Atomy::AST::QuasiQuote)
          @depth += 1
        end

        if (x && x.unquote?) || (y && y.unquote?)
          @depth -= 1
        end

        if x.nil?
          return -1

        elsif y.nil?
          return 1

        elsif x.unquote? && y.unquote? && @depth == 0
          return x.expression.pattern <=> y.expression.pattern

        elsif x.unquote? && @depth == 0
          return x.expression.pattern <=> Quote.new(y)

        elsif y.unquote? && @depth == 0
          return Quote.new(x) <=> y.expression.pattern

        elsif !x.is_a?(y.class) || !x.attribute_names.all? { |d| x.send(d) == y.send(d) }
          fail

        elsif x.bottom? || y.bottom?
          fail if x != y
        end

        total = 0
        x.class.children[:required].each do |c|
          total += compare(x.send(c), y.send(c))
        end

        x.class.children[:many].each do |c|
          xs = x.send(c)
          ys = y.send(c)
          [xs.size, ys.size].max.times do |i|
            a = xs[i]
            b = ys[i]

            if a.nil?
              unless b && b.splice? && b.expression.pattern.wildcard?
                total -= 1
              end
            elsif b.nil?
              unless a.splice? && a.expression.pattern.wildcard?
                total += 1
              end
            elsif a.splice? && !b.splice?
              total -= 1
            elsif b.splice? && !a.splice?
              total += 1
            else
              total += compare(a, b)
            end
          end
        end

        total <=> 0
      ensure
        if x && x.unquote? || y && y.unquote?
          @depth += 1
        end

        if x.is_a?(Atomy::AST::QuasiQuote) && \
            y.is_a?(Atomy::AST::QuasiQuote)
          @depth -= 1
        end
      end

      def go(x, y)
        catch(:incomparable) do
          compare(x, y)
        end
      end
    end
  end

  class Quote
    def <=>(other)
      return 0 if other.is_a?(self.class)
      1
    end
  end


  class Pattern
    def =~(other)
      case other
      when Default, Named
        self =~ other.pattern
      else
        self == other
      end
    end
  end

  class SingletonClass
    def =~(other)
      return false unless other.is_a?(self.class)

      if value && other.value
        value == other.value
      else
        false
      end
    end
  end

  class Named
    def =~(other)
      if other.is_a?(self.class)
        pattern =~ other.pattern
      else
        pattern =~ other
      end
    end
  end

  class BlockPass
    def =~(other)
      other.is_a?(self.class) && pattern =~ other.pattern
    end
  end

  class Constant
    def =~(other)
      return false unless other.is_a?(self.class)

      if value && other.value
        value == other.value
      else
        constant == other.constant
      end
    end
  end

  class Default
    def =~(other)
      if other.is_a?(self.class)
        pattern =~ other.pattern
      else
        pattern =~ other
      end
    end
  end

  class HeadTail
    def =~(other)
      other.is_a?(self.class) && head =~ other.head && tail =~ other.tail
    end
  end

  class List
    def =~(other)
      other.is_a?(self.class) &&
        patterns.size == other.patterns.size &&
        patterns.zip(other.patterns).all? do |x, y|
          x =~ y
        end
    end
  end

  class Match
    def =~(other)
      other.is_a?(self.class) && value == other.value
    end
  end

  class Literal
    def =~(other)
      other.is_a?(self.class) && value == other.value
    end
  end

  class Any; def =~(other); other.is_a?(self.class); end; end
  class NamedClass; def =~(other); other.is_a?(self.class); end; end
  class NamedGlobal; def =~(other); other.is_a?(self.class); end; end
  class NamedInstance; def =~(other); other.is_a?(self.class); end; end

  class QuasiQuote
    def =~(other)
      return false unless other.is_a?(self.class)
      EquivalenceWalker.new.go(@quoted, other.quoted)
    end

    class EquivalenceWalker
      def initialize
        @depth = 0
      end

      def fail
        throw(:inequivalent, false)
      end

      def compare(x, y)
        if x.is_a?(Atomy::AST::QuasiQuote) && \
            y.is_a?(Atomy::AST::QuasiQuote)
          @depth += 1
        end

        if (x && x.unquote?) || (y && y.unquote?)
          @depth -= 1
        end

        if x.nil? || y.nil?
          fail

        elsif x.unquote? && y.unquote? && @depth == 0
          if x.expression.pattern =~ y.expression.pattern
            return true
          else
            fail
          end

        elsif x.unquote? && @depth == 0
          if x.expression.pattern =~ Quote.new(y)
            return true
          else
            fail
          end

        elsif y.unquote? && @depth == 0
          if Quote.new(x) =~ y.expression.pattern
            return true
          else
            fail
          end

        elsif !x.is_a?(y.class) || !x.attribute_names.all? { |d| x.send(d) == y.send(d) }
          fail

        elsif x.bottom? || y.bottom?
          fail if x != y
        end

        total = 0
        x.class.children[:required].each do |c|
          compare(x.send(c), y.send(c))
        end

        x.class.children[:many].each do |c|
          xs = x.send(c)
          ys = y.send(c)
          [xs.size, ys.size].max.times do |i|
            a = xs[i]
            b = ys[i]

            if a.nil?
              unless b && b.splice? && b.expression.pattern.wildcard?
                fail
              end
            elsif b.nil?
              unless a.splice? && a.expression.pattern.wildcard?
                fail
              end
            elsif a.splice? && !b.splice?
              fail
            elsif b.splice? && !a.splice?
              fail
            else
              compare(a, b)
            end
          end
        end

        true
      ensure
        if x && x.unquote? || y && y.unquote?
          @depth += 1
        end

        if x.is_a?(Atomy::AST::QuasiQuote) && \
            y.is_a?(Atomy::AST::QuasiQuote)
          @depth -= 1
        end
      end

      def go(x, y)
        catch(:inequivalent) do
          compare(x, y)
        end
      end
    end
  end

  class Quote
    def =~(other)
      other.is_a?(self.class) && expression == other.expression
    end
  end

  class Splat
    def =~(other)
      other.is_a?(self.class) && pattern =~ other.pattern
    end
  end

  class Attribute
    def =~(other)
      other.is_a?(self.class) &&
        receiver == other.receiver &&
        name == other.name &&
        arguments == other.arguments
    end
  end

  # helper for comparing aggregate patterns like lists
  def self.compare(xs, ys)
    total = 0

    xs.zip(ys) do |x, y|
      unless y.nil?
        total += x <=> y
      end
    end

    total <=> 0
  end
end

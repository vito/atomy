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
      when Default, Named
        self <=> other.pattern
      else
        precision <=> other.precision
      end
    end
  end

  class BlockPass
    def <=>(other)
      return super unless other.is_a?(self.class)
      pattern <=> other.pattern
    end
  end

  class Constant
    def <=>(other)
      return super unless other.is_a?(self.class)

      if not (value.is_a?(Class) && other.value.is_a?(Class))
        0
      elsif value.ancestors.nil? or other.value.ancestors.nil?
        0
      elsif value.ancestors.first == other.value.ancestors.first
        0
      elsif other.value.ancestors.include?(value.ancestors.first)
        -1
      elsif value.ancestors.include?(other.value.ancestors.first)
        1
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
      Atomy::Patterns.compare(patterns, other.patterns)
    end
  end

  class Splat
    def <=>(other)
      return super unless other.is_a?(self.class)
      pattern <=> other.pattern
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

      total = 0
      quoted.walk_with(other.quoted,
                       proc { |a, b| a.unquote? && b.unquote? }) do |x, y|
        if x.nil?
          total -= 1 unless y.splice?
        elsif y.nil?
          total += 1 unless x.splice?
        elsif x.unquote? && y.unquote?
          total += x.expression.to_pattern <=> y.expression.to_pattern
        elsif x.unquote?
          total += x.expression.to_pattern <=> Quote.new(y)
        elsif y.unquote?
          total += Quote.new(x) <=> y.expression.to_pattern
        end
      end

      total <=> 0
    end
  end


  class Pattern
    def =~(other)
      case other
      when Default, Named
        self =~ other.pattern
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

      total = 0

      quoted.walk_with(other.quoted,
                       proc { |a, b| a.unquote? && b.unquote? }) do |x, y|
        if x.nil? || y.nil?
          return false

        elsif x.unquote? && y.unquote?
          if x.splice? != y.splice?
            return false
          end

          unless x.expression.to_pattern =~ y.expression.to_pattern
            return false
          end

        elsif x.unquote? || y.unquote?
          return false

        elsif !x.is_a?(y.class) || !x.details.all? { |d| x.send(d) == y.send(d) }
          return false

        elsif x.bottom? || y.bottom?
          unless x == y
            return false
          end
        end
      end

      true
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

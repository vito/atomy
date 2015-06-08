module Atomy
  class MessageStructure
    class UnknownMessageStructure < RuntimeError
      def initialize(node)
        @node = node
      end

      def to_s
        "unknown message structure: #{@node}"
      end
    end

    def initialize(node)
      @node = node
    end

    def name
      name_from(@node)
    end

    def arguments
      arguments_from(@node)
    end

    def receiver
      receiver_from(@node)
    end

    def block
      block_from(@node)
    end

    private

    def unknown_message
      UnknownMessageStructure.new(@node)
    end

    def name_from(node)
      case node
      when Grammar::AST::Word
        return node.text
      when Grammar::AST::Apply
        return name_from(node.node)
      when Grammar::AST::Postfix
        case node.operator
        when :"!", :"?"
          case node.node
          when Grammar::AST::Word
            return :"#{node.node.text}#{node.operator}"
          end
        end
      when Grammar::AST::Compose
        case node.right
        when Grammar::AST::Prefix # block
          return name_from(node.left)
        when Grammar::AST::Word, Grammar::AST::Apply # has a receiver
          return name_from(node.right)
        when Grammar::AST::Postfix
          case node.right.operator
          when :"!", :"?"
            return name_from(node.right)
          end
        end
      end

      raise unknown_message
    end

    def arguments_from(node)
      case node
      when Grammar::AST::Apply
        return node.arguments
      when Grammar::AST::Compose
        case node.right
        when Grammar::AST::Prefix # block
          return arguments_from(node.left)
        when Grammar::AST::Word, Grammar::AST::Apply # has a receiver
          return arguments_from(node.right)
        end
      end

      []
    end

    def block_from(node)
      case node
      when Grammar::AST::Compose
        case node.right
        when Grammar::AST::Prefix
          if node.right.operator == :"&" # block
            return node.right.node
          end
        end
      end
    end

    def receiver_from(node)
      case node
      when Grammar::AST::Compose
        case node.right
        when Grammar::AST::Word, Grammar::AST::Apply
          return node.left
        when Grammar::AST::Postfix
          case node.right.operator
          when :"!", :"?"
            return node.left
          end
        when Grammar::AST::Prefix
          if node.right.operator == :"&" # block
            return receiver_from(node.left)
          end
        end
      end
    end
  end
end

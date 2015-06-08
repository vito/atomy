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

    def proc_argument
      proc_argument_from(@node)
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
      when Grammar::AST::Infix
        return node.operator
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
        when Grammar::AST::Prefix # proc argument
          return name_from(node.left)
        when Grammar::AST::Word, Grammar::AST::Apply # has a receiver
          return name_from(node.right)
        when Grammar::AST::Postfix
          case node.right.operator
          when :"!", :"?"
            return name_from(node.right)
          end
        when Grammar::AST::Block # block literal argument
          case node.left
          when Grammar::AST::Compose
            case node.left.right
            when Grammar::AST::List # block args; skip
              return name_from(node.left.left)
            else
              return name_from(node.left)
            end
          else
            return name_from(node.left)
          end
        when Grammar::AST::List # foo[bar]
          return :[]
        end
      end

      raise unknown_message
    end

    def arguments_from(node)
      case node
      when Grammar::AST::Apply
        return node.arguments
      when Grammar::AST::Infix
        return [node.right]
      when Grammar::AST::Compose
        case node.right
        when Grammar::AST::Prefix # proc argument
          return arguments_from(node.left)
        when Grammar::AST::Word, Grammar::AST::Apply # has a receiver
          return arguments_from(node.right)
        when Grammar::AST::Block # block literal argument
          case node.left
          when Grammar::AST::Compose
            case node.left.right
            when Grammar::AST::List # block args; skip
              return arguments_from(node.left.left)
            else
              return arguments_from(node.left)
            end
          else
            return arguments_from(node.left)
          end
        when Grammar::AST::List # foo[bar]
          return node.right.nodes
        end
      end

      []
    end

    def proc_argument_from(node)
      case node
      when Grammar::AST::Compose
        case node.right
        when Grammar::AST::Prefix
          if node.right.operator == :"&" # proc argument
            return node.right.node
          end
        end
      end
    end

    def receiver_from(node)
      case node
      when Grammar::AST::Infix
        return node.left
      when Grammar::AST::Compose
        case node.right
        when Grammar::AST::Word, Grammar::AST::Apply
          return node.left
        when Grammar::AST::Postfix
          case node.right.operator
          when :"!", :"?"
            return node.left
          end
        when Grammar::AST::Block # block literal argument
          case node.left
          when Grammar::AST::Compose
            case node.left.right
            when Grammar::AST::List # block args; skip
              return receiver_from(node.left.left)
            else
              return receiver_from(node.left)
            end
          else
            return receiver_from(node.left)
          end
        when Grammar::AST::List
          return node.left
        when Grammar::AST::Prefix
          if node.right.operator == :"&" # proc argument
            return receiver_from(node.left)
          end
        end
      end
    end
    
    def block_from(node)
      case node
      when Grammar::AST::Compose
        blk = nil

        case node.right
        when Grammar::AST::Block
          blk = node.right
        else
          return
        end

        case node.left
        when Grammar::AST::Compose
          case node.left.right
          when Grammar::AST::List
            return Grammar::AST::Compose.new(node.left.right, blk)
          end
        end

        return blk
      end
    end
  end
end

module Atomy
  class MessageStructure
    class DefaultArgument
      attr_reader :node, :default

      def initialize(node, default)
        @node = node
        @default = default
      end

      def ==(other)
        other.is_a?(self.class) && \
          other.node == @node && \
          other.default == @default
      end
    end

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
      # don't treat sole constant as message send
      raise unknown_message if @node.is_a?(Atomy::Grammar::AST::Constant)

      name_from(@node)
    end

    def arguments
      pre, defaults, post, splat = arguments_from(argument_list_from(@node))
      pre
    end

    def splat_argument
      pre, defaults, post, splat = arguments_from(argument_list_from(@node))
      splat
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

    def default_arguments
      pre, defaults, post, splat = arguments_from(argument_list_from(@node))
      defaults
    end

    def post_arguments
      pre, defaults, post, splat = arguments_from(argument_list_from(@node))
      post
    end

    private

    def unknown_message
      UnknownMessageStructure.new(@node)
    end

    def name_from(node)
      case node
      when Grammar::AST::Word, Grammar::AST::Constant
        return node.text
      when Grammar::AST::Apply
        return name_from(node.node)
      when Grammar::AST::Infix
        return node.operator
      when Grammar::AST::Postfix
        case node.operator
        when :"!", :"?"
          case node.node
          when Grammar::AST::Word, Grammar::AST::Constant
            return :"#{node.node.text}#{node.operator}"
          end
        end
      when Grammar::AST::Prefix
        return :"#{node.operator}@"
      when Grammar::AST::Compose
        case node.right
        when Grammar::AST::Prefix # proc argument
          return name_from(node.left)
        when Grammar::AST::Word, Grammar::AST::Constant, Grammar::AST::Apply # has a receiver
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

    def arguments_from(list)
      pre = []
      defaults = []
      post = []
      splat = nil

      list.each do |a|
        if a.is_a?(Grammar::AST::Infix) && a.operator == :"="
          if splat || !post.empty?
            raise unknown_message
          end

          defaults << DefaultArgument.new(a.left, a.right)
        elsif a.is_a?(Grammar::AST::Prefix) && a.operator == :"*"
          if splat || !post.empty?
            raise unknown_message
          end

          splat = a.node
        elsif splat || !defaults.empty?
          post << a
        else
          pre << a
        end
      end

      [pre, defaults, post, splat]
    end

    def argument_list_from(node)
      case node
      when Grammar::AST::Apply
        return node.arguments
      when Grammar::AST::Infix
        return [node.right]
      when Grammar::AST::Compose
        case node.right
        when Grammar::AST::Prefix # proc argument
          return argument_list_from(node.left)
        when Grammar::AST::Word, Grammar::AST::Constant, Grammar::AST::Apply # has a receiver
          return argument_list_from(node.right)
        when Grammar::AST::Block # block literal argument
          case node.left
          when Grammar::AST::Compose
            case node.left.right
            when Grammar::AST::List # block args; skip
              return argument_list_from(node.left.left)
            else
              return argument_list_from(node.left)
            end
          else
            return argument_list_from(node.left)
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
        when Grammar::AST::Word, Grammar::AST::Constant, Grammar::AST::Apply
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
      when Grammar::AST::Prefix
        return node.node
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

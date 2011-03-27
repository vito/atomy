module Atomy
  module AST
    module SentientNode
      # hash from attribute to the type of child node it is
      # :normal = normal, required subnode
      # :many = an array of subnodes
      # :optional = optional (might be nil)
      def reset_children
        @@children = {
          :required => [],
          :many => [],
          :optional => []
        }
      end

      def reset_attributes
        @@attributes = {
          :required => [],
          :many => [],
          :optional => []
        }
      end

      def inherited(sub)
        reset_children
        reset_attributes
      end

      def self.extended(sub)
        sub.reset_children
        sub.reset_attributes
      end

      def spec(into, specs)
        specs.each do |s|
          if s.kind_of?(Array)
            if s.size == 2
              into[:optional] << s
            else
              into[:many] << s[0]
            end
          elsif s.to_s[-1] == ??
            into[:optional] << [s.to_s[0..-2].to_sym, "nil"]
          else
            into[:required] << s
          end
        end
      end

      def attributes(*specs)
        spec(@@attributes, specs)
      end

      def children(*specs)
        spec(@@children, specs)
      end

      def generate
        all = []
        args = ""
        (@@children[:required] + @@children[:many] +
         @@attributes[:required] + @@attributes[:many]).each do |x|
          all << x.to_s
          args << ", #{x}_"
        end

        (@@children[:optional] + @@attributes[:optional]).each do |x, d|
          all << x.to_s
          args << ", #{x}_ = #{d}"
        end

        class_eval <<EOF
          attr_accessor :line#{all.collect { |a| ", :#{a}" }.join}
EOF

        class_eval <<EOF
          def initialize(line#{args})
            @line = line
            #{all.collect { |a| "@#{a} = #{a}_" }.join("; ")}
          end
EOF

        class_eval <<EOF
          def construct(g, d = nil)
            get(g)
            g.push_int(@line)

            #{@@children[:required].collect { |n|
                "@#{n}.construct(g, d)"
              }.join("; ")}

            #{@@children[:many].collect { |n|
                "@#{n}.each { |n| n.construct(g, d) }; g.make_array(@#{n}.size)"
              }.join("; ")}

            #{@@attributes[:required].collect { |a|
                "g.push_literal(@#{a})"
              }.join("; ")}

            #{@@attributes[:many].collect { |a|
                "@#{a}.each { |n| g.push_literal n }; g.make_array(@#{a}.size)"
              }.join("; ")}

            #{@@children[:optional].collect { |n, _|
                "if @#{n}; @#{n}.construct(g, d); else; g.push_nil; end"
              }.join("; ")}

            #{@@attributes[:optional].collect { |a, _|
                "g.push_literal(@#{a})"
              }.join("; ")}

            g.send :new, #{all.size + 1}
          end
EOF

        class_eval <<EOF
          def ==(b)
            b.kind_of?(#{self.name}) \\
            #{all.collect { |a| " and @#{a} == b.#{a}" }.join}
          end
EOF

        req_cs =
          @@children[:required].collect { |n|
            ", @#{n}.recursively(pre, post, :#{n}, &f)"
          }.join

        many_cs =
          @@children[:many].collect { |n|
            ", @#{n}.each_with_index.collect { |n, i| n.recursively(pre, post, [:#{n}, i], &f) }"
          }.join

        opt_cs =
          @@children[:optional].collect { |n, _|
            ", @#{n} ? @#{n}.recursively(pre, post, :#{n}, &f) : nil"
          }.join

        req_as =
          (@@attributes[:required] + @@attributes[:many]).collect { |a|
            ", @#{a}"
          }.join

        opt_as = @@attributes[:optional].collect { |a, _|
            ", @#{a}"
          }.join

        class_eval <<EOF
          def recursively(pre = nil, post = nil, context = nil, &f)
            if pre and pre.arity == 2
              stop = pre.call(self, context)
            elsif pre
              stop = pre.call(self)
            else
              stop = false
            end

            if stop
              if f.arity == 2
                res = f.call(self, context)
                post.call(context) if post
                return res
              else
                res = f.call(self)
                post.call(context) if post
                return res
              end
            end

            recursed = #{self.name}.new(
              @line#{req_cs + many_cs + req_as + opt_cs + opt_as}
            )

            if f.arity == 2
              res = f.call(recursed, context)
            else
              res = f.call(recursed)
            end

            post.call(context) if post

            res
          end
EOF

        class_eval <<EOF
          def bottom?
            #{@@children.values.flatten(1).empty?.inspect}
          end
EOF

        attrs =
          @@attributes[:required] + @@attributes[:many] +
            @@attributes[:optional].collect(&:first)

        class_eval <<EOF
          def details
            #{attrs.inspect}
          end
EOF
      end
    end

    module NodeLike
      attr_accessor :line

      # yield this node's subnodes to a block recursively, and then itself
      # override this if for nodes with children, ie lists
      #
      # stop = predicate to determine whether to stop at a node before
      # recursing into its children
      def recursively(stop = nil, &f)
        f.call(self)
      end

      # used to construct this expression in a quasiquote
      # g = generator, d = depth
      #
      # quasiquotes should increase depth, unquotes should decrease
      # an unquote at depth 0 should push the unquote's contents rather
      # than itself
      def construct(g, d)
        raise Rubinius::CompileError, "no #construct for #{self}"
      end

      # TODO: this might not be correct; compare to Patterns::QuasiQuote
      def through_quotes(stop_ = nil, &f)
        stop = proc { |x|
          (stop_ && stop_.call(x)) || \
            x.kind_of?(AST::Quote) || \
            x.kind_of?(AST::QuasiQuote) || \
            x.kind_of?(AST::Unquote)
        }

        depth = 0
        search = nil
        scan = proc do |x|
          case x
          when Atomy::AST::Quote
            Atomy::AST::Quote.new(
              x.line,
              x.expression.recursively(stop, &search)
            )
          when Atomy::AST::QuasiQuote
            depth += 1
            Atomy::AST::QuasiQuote.new(
              x.line,
              x.expression.recursively(stop, &search)
            )
          else
            f.call(x)
          end
        end

        search = proc do |x|
          case x
          when Atomy::AST::QuasiQuote
            depth += 1
            Atomy::AST::QuasiQuote.new(
              x.line,
              x.expression.recursively(stop, &search)
            )
          when Atomy::AST::Unquote
            depth -= 1
            if depth == 0
              Atomy::AST::Unquote.new(
                x.line,
                x.expression.recursively(stop, &scan)
              )
            else
              Atomy::AST::Unquote.new(
                x.line,
                x.expression.recursively(stop, &search)
              )
            end
          else
            x
          end
        end

        recursively(stop, &scan)
      end

      def unquote(d)
        return unless d
        d - 1
      end

      def quote(d)
        return unless d
        d + 1
      end

      def get(g)
        g.push_cpath_top
        self.class.name.split("::").each do |n|
          g.find_const n.to_sym
        end
      end

      def to_node
        self
      end

      def method_name
        nil
      end
    end

    class Node < Rubinius::AST::Node
      include NodeLike
      extend SentientNode
    end

    class Tree
      attr_accessor :nodes

      def initialize(nodes)
        @nodes = Array(nodes)
      end

      def bytecode(g)
        @nodes.each { |n| n.bytecode(g) }
      end

      def collect
        Tree.new(@nodes.collect { |n| yield n })
      end
    end
  end
end

class Object
  def to_node
    Atomy::AST::Primitive.new -1, self
  end
end

module Atomy
  module Code
    class QuasiQuote
      def initialize(node)
        @node = node
      end

      def bytecode(gen, mod)
        Constructor.new(gen, mod).go(@node)
      end

      class Constructor
        def initialize(gen, mod)
          @gen = gen
          @module = mod
          @depth = 1
        end

        def go(x)
          x.accept(self)
        end

        def unquote(x)
          @module.compile(@gen, x.node)
        end

        def visit(x)
          push_class(x.class)

          args = 0
          x.each_child do |_, c|
            if c.is_a?(Array)
              c.each do |e|
                go(e)
              end
              @gen.make_array(c.size)
            else
              go(c)
            end
            args += 1
          end

          x.each_attribute do |_, a|
            push_literal(a)
            args += 1
          end

          @gen.send(:new, args)
        end

        def visit_quasiquote(qq)
          @depth += 1
          visit(qq)
        ensure
          @depth -= 1
        end

        def visit_unquote(x)
          @depth -= 1

          if @depth == 0
            unquote(x)
          else
            visit(x)
          end
        ensure
          @depth += 1
        end

        def push_literal(x)
          case x
          when Array
            x.each { |v| push_literal(v) }
            @gen.make_array(x.size)
          when String
            @gen.push_literal(x)
            @gen.string_dup
          else
            @gen.push_literal(x)
          end
        end

        def push_class(cls)
          @gen.push_cpath_top
          cls.name.split("::").each do |n|
            @gen.find_const(n.to_sym)
          end
        end
      end
    end
  end
end

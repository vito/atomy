require "atomy/code/pattern"

require "atomy/node/meta"


class Atomy::Code::Pattern
  class QuasiQuote < self
    def initialize(node, mod)
      constructor = Constructor.new(mod)
      @pattern = constructor.go(node)
    end

    def bytecode(gen, mod)
      gen.push_cpath_top
      gen.find_const(:Atomy)
      gen.find_const(:Pattern)
      gen.find_const(:QuasiQuote)
      mod.compile(gen, @pattern)
      gen.send(:new, 1)
    end

    def assign(gen)
      AssignWalker.new(gen).go(@pattern.node)
    end

    private

    class Walker
      def initialize
        @depth = 0
      end

      def go(x)
        x.accept(self)
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

      def unquote(_)
        raise NotImplementedError
      end
    end

    class Constructor < Walker
      attr_reader :locals

      def initialize(mod)
        super()

        @module = mod
      end

      def go(x)
        x.accept(self)
      end

      def visit(x)
        x.through do |v|
          go(v)
        end
      end

      def unquote(x)
        x.through do |p|
          @module.pattern(p)
        end
      end
    end

    class AssignWalker
      def initialize(gen)
        @gen = gen

        # [[msg, [args...]]]
        @path = []
      end

      def go(a)
        if a.is_a?(Atomy::Code::Pattern)
          @path.pop # remove .node call from following through the unquote
          assign_using_path(a)
          @path << :node # add it back so the parent .pop doesn't break
        else
          a.each_child do |attr, val|
            @path << [attr, []]

            if val.is_a?(Array)
              go_array(val)
            else
              go(val)
            end

            @path.pop
          end
        end
      end

      def go_array(as)
        splat = nil
        req_size = 0
        as.each do |a|
          if a.is_a?(Atomy::Grammar::AST::Unquote) && a.node.is_a?(Atomy::Code::Pattern) && a.node.splat?
            splat = a.node
            break
          end

          req_size += 1
        end

        req_size.times do |i|
          @path << [:[], [i]]
          go(as[i])
          @path.pop
        end

        if splat
          assign_using_path(splat, req_size)
        end

        true
      end

      def assign_using_path(pattern, splat_index = nil)
        @gen.dup_many(2)

        # get path from value
        push_path

        if splat_index
          @gen.push_int(splat_index)
          @gen.send(:drop, 1)
        end

        @gen.swap

        # get quasiquote tree of pattern
        @gen.send(:node, 0)

        # get path from pattern
        push_path

        if splat_index
          @gen.push_int(splat_index)
          @gen.send(:[], 1)
          @gen.send(:pattern, 0)
        end

        # restore original order
        @gen.swap

        # assign sub-pattern against sub-value
        pattern.assign(@gen)

        @gen.pop_many(2)
      end

      def push_path
        @path.each do |m, args|
          args.each do |a|
            @gen.push(a)
          end

          @gen.send(m, args.size)
        end
      end
    end
  end
end

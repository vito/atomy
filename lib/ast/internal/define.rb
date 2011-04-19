module Atomy
  module AST
    class Define < Node
      children :pattern, :body
      slots :namespace?
      generate

      def arguments
        return @arguments if @arguments

        case pattern
        when BinarySend
          args = [pattern.rhs]
        when Variable, Unary
          args = []
        else
          args = pattern.arguments
        end

        @arguments = args.collect(&:to_pattern)
      end

      def receiver
        return @receiver if @receiver

        case pattern
        when BinarySend
          recv = pattern.lhs
        when Variable
          recv = Primitive.new(pattern.line, :self)
        else
          recv = pattern.receiver
        end

        @receiver = recv.to_pattern
      end

      def method_name
        case pattern
        when Variable
          pattern.name
        else
          pattern.method_name
        end
      end

      def ns_method_name(g)
        if method_name == "initialize"
          g.push_literal :initialize
          return
        end

        if @namespace
          g.push_literal(
            Atomy.namespaced(@namespace, method_name).to_sym
          )
          return
        end

        no_ns = g.new_label
        done = g.new_label

        g.push_cpath_top
        g.find_const :Atomy
        g.push_cpath_top
        g.find_const :Atomy
        g.find_const :Namespace
        g.send :get, 0
        g.dup
        g.gif no_ns

        g.send :name, 0
        g.send :to_s, 0
        g.push_literal method_name
        g.send :namespaced, 2
        g.goto done

        no_ns.set!
        g.pop
        g.pop
        g.push_literal method_name

        done.set!
      end

      def bytecode(g)
        pos(g)

        defn = receiver.kind_of?(Patterns::Match) && receiver.value == :self

        if defn
          g.push_rubinius
          ns_method_name(g)
          g.send :to_sym, 0
          g.dup
          g.push_cpath_top
          g.find_const :Atomy
          g.swap
        else
          g.push_cpath_top
          g.find_const :Atomy
          receiver.target(g)
          ns_method_name(g)
          g.send :to_sym, 0
        end

        create = g.new_label
        added = g.new_label
        receiver.construct(g)
        arguments.each do |p|
          p.construct(g)
        end
        g.make_array arguments.size
        g.make_array 2
        @body.construct(g, nil)
        g.make_array 2

        receiver.target(g)
        g.push_literal "@atomy::"
        ns_method_name(g)
        g.string_build 2
        g.send :to_sym, 0
        g.send :instance_variable_get, 1
        g.dup
        g.gif create

        g.push_cpath_top
        g.find_const :Atomy
        g.move_down 2
        g.send :insert_method, 2
        g.goto added

        create.set!
        g.pop
        g.make_array 1
        receiver.target(g)
        g.swap
        g.push_literal "@atomy::"
        ns_method_name(g)
        g.string_build 2
        g.send :to_sym, 0
        g.swap
        g.send :instance_variable_set, 2

        added.set!

        if defn
          g.push_false
          g.push_scope
          g.send :active_path, 0
          g.push_int @line
          g.send :build_method, 5
          g.push_scope
          g.push_variables
          g.send :method_visibility, 0
          g.send :add_defn_method, 4
        else
          g.push_scope
          g.send :add_method, 4
        end
      end

      def local_count
        local_names.size
      end

      def local_names
        arguments.inject(receiver.local_names) do |acc, a|
          acc + a.local_names
        end
      end
    end
  end
end

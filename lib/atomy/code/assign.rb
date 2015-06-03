module Atomy
  module Code
    class Assign
      def initialize(pattern, value)
        @pattern = pattern
        @value = value
      end

      def bytecode(gen, mod)
        pattern = mod.pattern(@pattern)

        vars = []
        pattern.locals.each do |name|
          vars << assignment_local(gen, name)
        end

        # [value]
        mod.compile(gen, @value)
        # [value, value]
        gen.dup
        # [pattern, value, value]
        mod.compile(gen, pattern)
        # [value, pattern, value]
        gen.swap

        # [value, pattern, value, pattern, value]
        gen.dup_many(2)

        mismatch = gen.new_label
        done = gen.new_label

        # [bool, value, pattern, value]
        gen.send(:matches?, 1)

        # [value, pattern, value]
        gen.gif(mismatch)

        # [[bindings], value]
        gen.send(:bindings, 1)

        vars.each do |v|
          # [binding, [bindings], value]
          gen.shift_array

          # [binding, [bindings], value]
          v.set_bytecode(gen)

          # [[bindings], value]
          gen.pop
        end

        # [value]
        gen.pop

        # [value]
        gen.goto(done)

        # [value, pattern, value]
        mismatch.set!

        # [::, value, pattern, value]
        gen.push_cpath_top
        # [::Atomy, value, pattern, value]
        gen.find_const(:Atomy)
        # [::Atomy::PatternMismatch, value, pattern, value]
        gen.find_const(:PatternMismatch)
        # [value, pattern, ::Atomy::PatternMismatch, value]
        gen.move_down(2)
        # [#<Atomy::PatternMismatch>, value]
        gen.send(:new, 2)
        # exception
        gen.raise_exc

        # [value]
        done.set!
      end

      private

      def assignment_local(gen, name, set = false)
        var = gen.state.scope.search_local(name)

        if var && (set || var.depth == 0)
          var
        else
          gen.state.scope.new_local(name).nested_reference
        end
      end
    end
  end
end

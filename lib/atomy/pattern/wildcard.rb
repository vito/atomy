require "atomy/pattern"

class Atomy::Pattern
  class Wildcard < self
    attr_reader :name

    def initialize(name = nil)
      @name = name
    end

    def matches?(_)
      true
    end

    def assign(scope, val)
      if @name
        cur = scope
        while cur
          if local = cur.method.local_names.find_index(@name)
            cur.set_local(local, val)
            return
          end

          if cur.eval_local_defined?(@name)
            cur.set_eval_local(@name, val)
            return
          end

          cur = cur.parent
        end

        raise "could not find local for #@name"
      end
    end
  end
end

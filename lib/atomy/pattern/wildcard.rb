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
        if scope.eval_local_defined?(@name)
          scope.set_eval_local(@name, val)
          return
        end

        cur = scope
        until local = cur.method.local_names.find_index(@name)
          cur = cur.parent
          if !cur
            raise "could not find declaration for #{@name}"
          end
        end

        cur.set_local(local, val)
      end
    end

    def locals
      [@name].compact
    end
  end
end

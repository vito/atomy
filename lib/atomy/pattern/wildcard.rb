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
          if cur.dynamic_locals.key?(@name)
            p [:setting_dynamic_local, @name, val]
            cur.dynamic_locals[name] = val
            return
          end

          if local = cur.method.local_names.find_index(@name)
            p [:found_local, local, cur.locals]
            cur.set_local(local, val)
            return
          end

          p [:not_in, cur]

          cur = cur.parent
        end

        raise "could not find local for #@name"
      end
    end
  end
end

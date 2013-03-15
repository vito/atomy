module Atomy
  class Module < ::Module
    def initialize(&blk)
      module_eval(&blk) if blk
    end

    def compile(gen, node)
      expand(node).bytecode(gen, self)
    end
  end
end

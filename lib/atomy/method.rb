require "atomy/locals"

module Atomy
  class Method
    class Branch
      @@branch = 0

      attr_reader :method, :pattern, :body, :name

      def initialize(method, pattern, body)
        @method = method
        @pattern = pattern
        @body = body.block
        @name = :"#@method-#{tick}"
      end

      private

      def tick
        @@branch += 1
      end
    end

    attr_reader :name, :branches

    def initialize(name)
      @name = name
      @branches = []
    end

    def add_branch(pattern, body)
      branch = Branch.new(@name, pattern, body)

      index = nil
      replace = false

      @branches.each.with_index do |b, i|
        if b.pattern.precludes?(pattern)
          index = i

          if pattern.precludes?(b.pattern)
            replace = true
          end

          break
        end
      end

      if replace
        @branches[index] = branch
      elsif index
        @branches.insert(index, branch)
      else
        @branches << branch
      end

      branch
    end

    def build
      gen = make_generator

      done = gen.new_label

      build_branches(gen, done)

      try_super(gen, done) unless @name == :initialize

      raise_mismatch(gen)

      done.set!
      gen.ret

      package(gen)
    end

    private

    def make_generator
      gen = Rubinius::Generator.new
      gen.name = @name
      gen.file = :__wrapper__
      gen.set_line(0)

      gen.push_state(Atomy::LocalState.new)

      gen.splat_index = 0
      gen.total_args = 0
      gen.required_args = 0

      gen
    end

    def build_branches(gen, done)
      @branches.each do |b|
        skip = gen.new_label

        gen.push_local(0)
        b.pattern.matches?(gen)
        gen.gif(skip)

        gen.push_self
        gen.push_local(0)
        gen.push_proc
        gen.send_with_splat(b.name, 0, true)
        gen.goto(done)

        skip.set!
      end
    end

    def try_super(gen, done)
      no_super = gen.new_label

      gen.invoke_primitive :vm_check_super_callable, 0
      gen.gif(no_super)

      gen.push_proc
      if gen.state.super?
        gen.zsuper(g.state.super.name)
      else
        gen.zsuper(nil)
      end

      gen.goto(done)

      no_super.set!
    end

    def raise_mismatch(gen)
      gen.push_cpath_top
      gen.find_const(:Atomy)
      gen.find_const(:MessageMismatch)
      gen.push_literal(@name)
      gen.push_self
      gen.push_local(0)
      gen.send(:new, 3)
      gen.raise_exc
    end

    def package(gen)
      gen.close

      gen.local_count = 1
      gen.local_names = [:__arguments__] # TODO: make real?

      gen.encode

      gen.package(Rubinius::CompiledCode)
    end
  end
end

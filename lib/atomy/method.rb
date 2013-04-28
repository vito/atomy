require "atomy/compiler"
require "atomy/locals"

module Atomy
  class Method
    class Branch
      @@branch = 0

      attr_reader :method, :pattern, :matcher, :body, :name

      def initialize(method, pattern, matcher, body)
        @method = method
        @pattern = pattern
        @body = body
        @matcher = matcher
        @name = :"#@method-#{tick}"
      end

      def matcher_name
        :"#@name-matcher"
      end

      def total_args
        @pattern.arguments.size
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

    def add_branch(pattern, matcher, body)
      branch = Branch.new(@name, pattern, matcher, body)

      index = nil
      replace = false

      # TODO: ensure it's inserted after *all* the patterns it precludes, not
      # just the first
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
      Atomy::Compiler.package(:__wrapper__) do |gen|
        gen.name = @name

        total, req = argument_count
        gen.total_args = total
        gen.required_args = req

        total.times do |i|
          gen.state.scope.new_local(:"arg:#{i}")
        end

        done = gen.new_label

        build_branches(gen, done)

        unless has_base_case?
          try_super(gen, done) unless @name == :initialize
          raise_mismatch(gen)
        end

        gen.push_nil

        done.set!
      end
    end

    private

    def argument_count
      total = 0
      req = nil

      @branches.each do |b|
        args = b.total_args
        total = args if args > total
        req = args if !req || args < req
      end

      [total, req]
    end

    def has_base_case?
      @branches.any? do |b|
        # receiver must always match
        (!b.pattern.receiver || b.pattern.receiver.always_matches_self?) &&
          # must take no arguments (otherwise calling with invalid arg
          # count would match, as branches can take different arg sizes)
          (uniform_argument_count? && b.total_args == 0) # &&

          # and either have no splat or a wildcard splat
          #(!b.splat || b.splat.wildcard?)
      end
    end

    def total_args
      @branches.collect(&:total_args).max
    end

    def required_args
      @branches.collect(&:total_args).min
    end

    def uniform_argument_count?
      total_args == required_args
    end

    def build_branches(gen, done)
      @branches.each do |b|
        skip = gen.new_label

        gen.push_self
        b.total_args.times do |i|
          gen.push_local(i)
        end
        gen.send(b.matcher_name, b.total_args, true)

        gen.gif(skip)

        gen.push_self
        b.total_args.times do |i|
          gen.push_local(i)
        end
        gen.send(b.name, b.total_args, true)

        gen.goto(done)

        skip.set!
      end
    end

    def try_super(gen, done)
      no_super = gen.new_label

      gen.invoke_primitive(:vm_check_super_callable, 0)
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
      gen.send(:new, 2)
      gen.raise_exc
    end
  end
end

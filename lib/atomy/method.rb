# dispatch strategy:
#
#   1 foo([a, b]) := a + 1
#   2 foo([c]) := 4
#
# defines:
#
#   Integer#foo           (arity 1) : 1 concrete arg
#   Integer#foo-branch-1  (arity 2) : 2 bindings
#   Integer#foo-branch-2  (arity 1) : 1 binding
#
# so, doing 1.foo([1, 2]) will execute:
#
# Integer#foo:
#   - locals tuple: [arg:0]
#   - invoke Pattern#matches? with var scope
#     - if true, invoke Integer#foo-match-1(*Pattern#bindings(scope))
#     - if false, invoke Pattern#matches? with var scope
#       - if true, invoke Integer#foo-match-2(*Pattern#bindings(scope))
#       - if false, raise Atomy::MessageMismatch
#

require "atomy/compiler"
require "atomy/locals"

module Atomy
  class Method
    class Branch
      @@branch = 0

      attr_reader :method, :pattern, :body, :name, :locals

      def initialize(method, pattern, body, locals)
        @method = method
        @pattern = pattern
        @body = body
        @locals = locals
        @name = :"#@method-#{tick}"
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

    def add_branch(pattern, body, locals)
      branch = Branch.new(@name, pattern, body, locals)
      @branches << branch
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

        declared_locals = {}
        @branches.each do |b|
          b.locals.each do |loc|
            if !declared_locals[loc]
              gen.state.scope.new_local(loc)
              declared_locals[loc] = true
            end
          end
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
        #
        # TODO: KindOf/Wildcard should count as 'base cases' for the receiver
        !b.pattern.receiver &&
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

        # check for too few arguments
        gen.passed_arg(b.pattern.required_arguments - 1)
        gen.gif(skip)

        # check for too many arguments
        gen.passed_arg(b.pattern.total_arguments)
        gen.git(skip)

        if b.pattern.receiver
          gen.push_literal(b.pattern.receiver)
          gen.push_self
          gen.send(:matches?, 1)
          gen.gif(skip)
        end

        b.pattern.arguments.each.with_index do |p, i|
          gen.push_literal(p)
          gen.push_local(i)
          gen.send(:matches?, 1)
          gen.gif(skip)
        end

        if b.pattern.receiver
          gen.push_literal(b.pattern.receiver)
          gen.push_variables
          gen.push_self
          gen.send(:assign, 2)
          gen.pop
        end

        b.pattern.arguments.each.with_index do |p, i|
          gen.push_literal(p)
          gen.push_variables
          gen.push_local(i)
          gen.send(:assign, 2)
          gen.pop
        end

        gen.push_self

        b.locals.each do |loc|
          if local = gen.state.scope.search_local(loc)
            local.get_bytecode(gen)
          else
            raise "undeclared local: #{loc}"
          end
        end

        gen.send(b.name, b.locals.size, true)

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

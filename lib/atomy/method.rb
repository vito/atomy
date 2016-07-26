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
  class InconsistentArgumentForms < RuntimeError
    def to_s
      "inconsistent method argument forms"
    end
  end

  class Method
    class Branch
      attr_reader :body, :receiver, :arguments, :default_arguments,
        :splat_argument, :post_arguments, :proc_argument

      attr_accessor :name

      def initialize(receiver = nil, arguments = [], default_arguments = [],
                     splat_argument = nil, post_arguments = [],
                     proc_argument = nil, &body)
        @body = body.block
        @receiver = receiver
        @arguments = arguments
        @default_arguments = default_arguments
        @splat_argument = splat_argument
        @post_arguments = post_arguments
        @proc_argument = proc_argument
      end

      def pre_arguments_count
        @arguments.size
      end

      def default_arguments_count
        @default_arguments.size
      end

      def post_arguments_count
        @post_arguments.size
      end

      def splat_index
        @arguments.size + @default_arguments.size if @splat_argument
      end

      def for_method!
        @method = true
        self
      end

      def method?
        @method
      end

      def as_method
        Rubinius::BlockEnvironment::AsMethod.new(@body)
      end
    end

    attr_reader :name, :branches

    def initialize(name)
      @name = name
      @branches = []
    end

    @@tick = 0

    def add_branch(branch)
      @branches << branch

      if branch.method?
        @@tick += 1
        branch.name = :"#{@name}:branch:#{@@tick}"
      end

      branch
    end

    def build
      Atomy::Compiler.package(:__wrapper__) do |gen|
        gen.name = @name

        pre, default, splat, post = argument_form
        gen.total_args = pre + default + post
        gen.required_args = pre + post
        gen.splat_index = splat
        gen.post_args = post

        arg = 0
        pre.times do
          gen.state.scope.new_local(:"arg:#{arg}")
          arg += 1
        end

        default.times do
          gen.state.scope.new_local(:"arg:#{arg}")
          arg += 1
        end

        if gen.splat_index
          gen.state.scope.new_local(:"arg:splat")
        end

        post.times do
          gen.state.scope.new_local(:"arg:#{arg}")
          arg += 1
        end

        done = gen.new_label

        build_branches(gen, done)

        try_super(gen, done) unless @name == :initialize
        raise_mismatch(gen)

        gen.push_nil

        done.set!
      end.tap do |cm|
        cm.scope = Rubinius::ConstantScope.new(Object)
      end
    end

    private

    def uniform_argument_forms?
      return true if @branches.empty?

      return false unless @branches.collect(&:pre_arguments_count).uniq.size == 1
      return false unless @branches.collect(&:splat_index).uniq.size == 1
      return false unless @branches.collect(&:post_arguments_count).uniq.size == 1

      # permit varying default argument counts; as long as the rest are the
      # same it's unambiguous

      true
    end

    def argument_form
      return [0, 0, nil, 0] if @branches.empty?

      raise InconsistentArgumentForms unless uniform_argument_forms?

      [
        @branches.collect(&:pre_arguments_count).first,
        @branches.collect(&:default_arguments_count).max,
        @branches.collect(&:splat_index).first,
        @branches.collect(&:post_arguments_count).first,
      ]
    end

    def build_branches(gen, done)
      @branches.each do |b|
        skip = gen.new_label

        # check for too few arguments
        gen.passed_arg(b.pre_arguments_count - 1)
        gen.goto_if_false(skip)

        # check for too many arguments
        unless b.splat_index
          gen.passed_arg(b.pre_arguments_count + b.default_arguments_count + b.post_arguments_count)
          gen.goto_if_true(skip)
        end

        if b.receiver
          gen.push_self
          b.receiver.inline_matches?(gen)
          gen.goto_if_false(skip)
        end

        arg = 0
        b.arguments.each do |pat|
          gen.push_local(arg)
          pat.inline_matches?(gen)
          gen.goto_if_false(skip)

          arg += 1
        end

        b.default_arguments.each do |pat|
          skip_check = gen.new_label

          gen.push_local(arg)
          gen.goto_if_undefined(skip_check)

          gen.push_local(arg)
          pat.inline_matches?(gen)
          gen.goto_if_false(skip)

          skip_check.set!

          arg += 1
        end

        if b.splat_argument
          gen.push_local(b.splat_index)
          b.splat_argument.inline_matches?(gen)
          gen.goto_if_false(skip)

          arg += 1
        end

        b.post_arguments.each do |pat|
          gen.push_local(arg)
          pat.inline_matches?(gen)
          gen.goto_if_false(skip)

          arg += 1
        end

        if b.proc_argument
          gen.push_proc
          b.proc_argument.inline_matches?(gen)
          gen.goto_if_false(skip)
        end

        branch_args = 0
        method_arg = 0

        if pat = b.receiver
          gen.push_literal(pat)
          gen.push_self
          branch_args += 2
        end

        b.arguments.each do |pat|
          gen.push_literal(pat)
          gen.push_local(method_arg)
          method_arg += 1
          branch_args += 2
        end

        b.default_arguments.each do |pat|
          gen.push_literal(pat)
          gen.push_local(method_arg)
          method_arg += 1
          branch_args += 2
        end

        if pat = b.splat_argument
          gen.push_literal(pat)
          gen.push_local(b.splat_index)
          method_arg += 1
          branch_args += 2
        end

        b.post_arguments.each do |pat|
          gen.push_literal(pat)
          gen.push_local(method_arg)
          method_arg += 1
          branch_args += 2
        end

        if pat = b.proc_argument
          gen.push_literal(pat)
          gen.push_proc
          branch_args += 2
        end

        if b.name
          gen.push_self
          gen.move_down(branch_args)

          gen.send(b.name, branch_args, true)
        else
          gen.push_literal(b.as_method)
          gen.move_down(branch_args)

          gen.push_literal(@name)
          gen.move_down(branch_args)

          gen.push_literal(b.body.constant_scope.module)
          gen.move_down(branch_args)

          gen.push_self
          gen.move_down(branch_args)

          gen.make_array(branch_args)

          gen.push_nil

          gen.send(:invoke, 5)
        end

        gen.goto(done)

        skip.set!
      end
    end

    def try_super(gen, done)
      no_super = gen.new_label

      gen.invoke_primitive(:vm_check_super_callable, 0)
      gen.goto_if_false(no_super)

      gen.push_proc
      gen.zsuper(@name)

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

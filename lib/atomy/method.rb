class Module
  def atomy_methods
    @atomy_methods ||= {}
  end
end

class Rubinius::StaticScope
  def atomy_methods
    @atomy_methods ||= {}
  end
end

module Atomy
  class Branch
    attr_accessor :module, :body, :receiver, :required, :defaults,
                  :splat, :block

    def initialize(mod, receiver, required = [], defaults = [],
                   splat = nil, block = nil, &body)
      @module = mod
      @body = (body && body.block) || proc { raise "branch has no body " }
      @receiver = receiver
      @required = required
      @defaults = defaults
      @splat = splat
      @block = block
    end

    def ==(b)
      equal?(b) or \
        @receiver == b.receiver and \
        @required == b.required and \
        @defaults == b.defaults and \
        @splat == b.splat and \
        @block == b.block
    end

    def total_args
      @required.size + @defaults.size
    end

    # compare one branch's precision to another
    def <=>(other)
      return 1 if total_args > other.total_args
      return -1 if total_args < other.total_args

      total = 0

      unless @receiver.always_matches_self? && \
              other.receiver.always_matches_self?
        total += @receiver <=> other.receiver
      end

      @required.zip(other.required) do |x, y|
        total += x <=> y unless y.nil?
      end

      @defaults.zip(other.defaults) do |x, y|
        total += x <=> y unless y.nil?
      end

      if @splat and other.splat
        total += @splat <=> other.splat
      end

      if @block and other.block
        total += @block <=> other.block
      end

      total <=> 0
    end

    # will two branches always match the same cases?
    def =~(other)
      return false unless total_args == other.total_args

      return false unless @receiver =~ other.receiver

      @required.zip(other.required) do |x, y|
        return false unless x =~ y
      end

      @defaults.zip(other.defaults) do |x, y|
        return false unless x =~ y
      end

      if @splat or other.splat
        return false unless @splat =~ other.splat
      end

      if @block or other.block
        return false unless @block =~ other.block
      end

      true
    end
  end

  class Method
    include Enumerable

    def initialize(name)
      @name = name
      @branches = []
      @sorted = false
    end

    def add(branch)
      insert(branch, @branches)
      nil
    end

    def size
      @branches.size
    end

    def each(*args, &blk)
      @branches.each(*args, &blk)
    end

    def build
      g = Rubinius::Generator.new
      g.name = @name
      g.file = :wrapper
      g.set_line 0

      done = g.new_label
      mismatch = g.new_label

      g.push_state Rubinius::AST::ClosedScope.new(0)

      g.state.push_name @name

      g.splat_index = 0
      g.total_args = 0
      g.required_args = 0

      build_methods(g, @branches, done)

      unless @name == :initialize
        g.invoke_primitive :vm_check_super_callable, 0
        g.gif mismatch

        g.push_proc
        if g.state.super?
          g.zsuper g.state.super.name
        else
          g.zsuper nil
        end

        g.goto done
      end

      # no method branches matched; fail
      mismatch.set!
      g.push_self
      g.push_cpath_top
      g.find_const :Atomy
      g.find_const :MethodFail
      g.push_literal @name
      g.push_local 0
      g.send :new, 2
      g.allow_private
      g.send :raise, 1

      # successfully evaluated a branch
      done.set!

      g.state.pop_name

      g.ret
      g.close

      g.local_names = g.state.scope.local_names
      g.local_count = g.state.scope.local_count

      g.pop_state
      g.use_detected
      g.encode

      cm = g.package Rubinius::CompiledMethod

      cm.scope = Rubinius::StaticScope.new(Object)

      cm
    end

  private

    # insert method `new` into the list of branches
    #
    # if <=> isn't defined, we can't compare precision, so
    # just unshift it
    #
    # if it is defined, but the branches aren't sorted, sort them
    #
    # if it is defined, and the branches are already sorted, insert
    # it in the proper order
    #
    # during insertion, branches with equivalent patterns will
    # be replaced
    def insert(new, branches)
      branches.each_with_index do |branch, i|
        case new <=> branch
        when 1
          return branches.insert(i, new)
        when 0
          if new =~ branch
            branches[i] = new
            return branches
          end
        end
      end

      branches << new
    end

    # build all the method branches, assumed to be from the
    # same namespace
    def build_methods(g, methods, done)
      methods.each do |meth|
        mod = meth.module
        recv = meth.receiver
        reqs = meth.required
        defs = meth.defaults
        splat = meth.splat
        block = meth.block
        body = meth.body

        has_args = meth.total_args > 0

        skip = g.new_label
        argmis = g.new_label

        if reqs.size > 0
          g.passed_arg(reqs.size - 1)
          g.gif skip
        end

        unless recv.always_matches_self?
          g.push_self
          recv.matches_self?(g, mod)
          g.gif skip
        end

        if has_args
          g.push_local 0

          reqs.each_with_index do |a, i|
            g.shift_array

            if a.wildcard?
              g.pop
            else
              a.matches?(g, mod)
              g.gif argmis
            end
          end

          defs.each_with_index do |d, i|
            no_value = g.new_label

            num = reqs.size + i
            g.passed_arg num
            g.gif no_value

            g.shift_array
            d.matches?(g, mod)
            g.gif argmis

            no_value.set!
          end

          if splat and s = splat.pattern
            s.matches?(g, mod)
            g.gif skip
          else
            g.pop
          end
        end

        g.push_literal body
        g.push_self
        g.push_literal body.static_scope
        g.push_self
        if has_args or splat
          g.push_local 0
          g.push_proc
          g.send_with_splat :call_under, 3, true
        elsif block
          g.push_proc
          g.send_with_block :call_under, 3, true
        else
          g.send :call_under, 3
        end
        g.goto done

        argmis.set!
        g.pop if has_args

        skip.set!
      end
    end
  end

  # build a method from the given branches and add it to
  # the target
  def self.add_method(target, name, method)
    Rubinius.add_method name, method.build, target, :public
  end

  def self.add_branch(target, name, branch)
    methods = target.atomy_methods

    if method = methods[name]
      method.add(branch)
    else
      method = Method.new(name)
      method.add(branch)
      methods[name] = method
    end

    method
  end

  # define a new method branch
  def self.define_branch(target, name, branch, scope)
    add_method(target, name, add_branch(target, name, branch)).tap do
      target.send(:module_function, name) if target.is_a?(Atomy::Module)
    end
  end

  def self.dynamic_branch(
      target, name, branch, scope = Rubinius::StaticScope.of_sender)
    define_branch(target, name, branch, scope)
  end
end

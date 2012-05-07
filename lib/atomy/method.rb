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
    attr_accessor :module, :name, :body, :receiver, :required, :defaults,
                  :splat, :block

    def initialize(mod, receiver, required = [], defaults = [],
                   splat = nil, block = nil, &body)
      @module = mod
      @body = (body && body.block) || proc { raise "branch has no body" }
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

    def new_name
      :"#{@name}:#{Macro::Environment.salt!}"
    end

    def add(branch, named = false)
      insert(branch, @branches, named)
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
      g.file = :"(wrapper: #{@name})"
      g.set_line 0

      done = g.new_label

      g.push_state Rubinius::AST::ClosedScope.new(0)

      g.state.push_name @name

      has_args = @branches.any? { |b| b.total_args > 0 || b.splat }

      always_matches =
        @branches.any? { |b|
          # receiver must always match
          b.receiver.always_matches_self? &&
            # must take no arguments (otherwise calling with invalid arg count
            # would mismatch, as branches can take different arg sizes)
            #
            # TODO?: if all branches take same arg size, check if any are
            # wildcards
            (b.total_args == 0) &&

            # and either have no splat or a wildcard splat
            (!b.splat || b.splat.wildcard?)
        }

      if has_args
        g.splat_index = 0
      end

      g.total_args = 0
      g.required_args = 0

      build_methods(g, @branches, done)

      unless always_matches
        unless @name == :initialize
          no_super = g.new_label

          g.invoke_primitive :vm_check_super_callable, 0
          g.gif no_super

          g.push_proc
          if g.state.super?
            g.zsuper g.state.super.name
          else
            g.zsuper nil
          end

          g.goto done

          no_super.set!
        end

        # no method branches matched; fail
        g.push_self
        g.push_cpath_top
        g.find_const :Atomy
        g.find_const :MethodFail
        g.push_literal @name
        if has_args
          g.push_local 0
        else
          g.push_nil
        end
        g.send :new, 2
        g.allow_private
        g.send :raise, 1
      end

      # successfully evaluated a branch
      done.set!

      g.state.pop_name

      g.ret
      g.close

      # never actually assigned as arguments but this fixes decoding
      if has_args
        g.local_names = [:arguments]
        g.local_count = 1
      end

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
    def insert(new, branches, named = false)
      branches.each_with_index do |branch, i|
        case new <=> branch
        when 1
          new.name = new_name if named
          return branches.insert(i, new)
        when 0
          if new =~ branch
            new.name = branch.name if named
            branches[i] = new
            return branches
          end
        end
      end

      new.name = new_name if named

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

        if meth.name
          g.push_self
          if has_args or splat
            g.push_local 0
            g.push_proc
            g.send_with_splat meth.name, 0, true
          elsif block
            g.push_proc
            g.send_with_block meth.name, 0, true
          else
            g.send_vcall meth.name
          end
        else
          g.push_literal body
          g.push_self
          g.push_literal body.static_scope
          if has_args or splat
            g.push_local 0
            g.push_proc
            g.send_with_splat :call_under, 2, true
          elsif block
            g.push_proc
            g.send_with_block :call_under, 2, true
          else
            g.send :call_under, 2
          end
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

  def self.add_branch(target, name, branch, named = false)
    methods = target.atomy_methods

    if method = methods[name]
      method.add(branch, named)
    else
      method = Method.new(name)
      method.add(branch, named)
      methods[name] = method
    end

    method
  end

  # define a new method branch
  def self.define_branch(target, name, branch, scope)
    add_method(target, name, add_branch(target, name, branch, true)).tap do
      Rubinius.add_method(
        branch.name,
        Rubinius::BlockEnvironment::AsMethod.new(branch.body),
        target, :private)

      if target.is_a?(Atomy::Module)
        target.send(:module_function, branch.name)
        target.send(:module_function, name)
      end
    end
  end

  def self.dynamic_branch(
      target, name, branch, scope = Rubinius::StaticScope.of_sender)
    define_branch(target, name, branch, scope)
  end
end

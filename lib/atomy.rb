require "atomy/method"

class Object
  attr_reader :atomy_methods

  def atomy_methods
    @atomy_methods ||= {}
  end
end

module Atomy
  module_function

  def define_branch(binding, name, pattern, body, mod)
    target =
      if pattern.receiver
        pattern.receiver.target
      else
        binding.constant_scope.for_method_definition
      end

    matcher = build_matcher(binding, name, pattern)
    body_blk = build_body(binding, name, pattern, body, mod)

    methods = target.atomy_methods
    method = methods[name] ||= Atomy::Method.new(name)

    branch = method.add_branch(pattern, matcher, body_blk)

    Rubinius.add_method(
      branch.name,
      Rubinius::BlockEnvironment::AsMethod.new(branch.body),
      target,
      :private)

    Rubinius.add_method(
      branch.matcher_name,
      Rubinius::BlockEnvironment::AsMethod.new(branch.matcher),
      target,
      :private)

    Rubinius.add_method(name, method.build, target, :public)
  end

  def build_body(binding, name, pattern, body, mod)
    code = Atomy::Compiler.package(binding.compiled_code.file) do |blk|
      blk.name = :"#{name}-branch"
      blk.required_args = blk.total_args = pattern.arguments.size

      pattern.arguments.each.with_index do |a, i|
        blk.state.scope.new_local(:"arg:#{i}")
      end

      pattern.locals.each do |n|
        blk.state.scope.new_local(n)
      end

      blk.push_literal(pattern)
      blk.push_variables # context to assign into
      blk.dup # value to assign from (happens to be the same)
      blk.send(:assign, 2)
      blk.pop

      mod.compile(blk, body)
    end

    Atomy::Compiler.construct_block(code, binding)
  end

  def build_matcher(binding, name, pattern)
    code = Atomy::Compiler.package(binding.compiled_code.file) do |blk|
      blk.name = :"##{name}-matcher"
      blk.required_args = blk.total_args = pattern.arguments.size

      pattern.arguments.each.with_index do |a, i|
        blk.state.scope.new_local(:"arg:#{i}")
      end

      blk.push_literal(pattern)
      blk.push_variables
      blk.send(:matches?, 1)
    end

    Atomy::Compiler.construct_block(code, binding)
  end
end

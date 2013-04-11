require "atomy/method"

class Object
  attr_reader :atomy_methods

  def atomy_methods
    @atomy_methods ||= {}
  end
end

module Atomy
  module_function

  def define_branch(target, name, pattern, &body)
    matcher = build_matcher(name, pattern, body)

    methods = target.atomy_methods
    method = methods[name] ||= Atomy::Method.new(name)

    branch = method.add_branch(pattern, matcher, body.block)

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

  def build_matcher(name, pattern, body)
    code = Atomy::Compiler.package(body.block.compiled_code.file) do |blk|
      blk.name = :"##{name}-matcher"
      blk.splat_index = 0
      blk.total_args = 0
      blk.required_args = 0

      blk.push_local(0)
      blk.state.scope.new_local(:__arguments__)
      pattern.matches?(blk)
    end

    Atomy::Compiler.construct_block(code, body.binding)
  end
end

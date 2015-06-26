require "atomy/method"

class Object
  attr_reader :atomy_methods

  def atomy_methods
    @atomy_methods ||= {}
  end
end

module Atomy
  module_function

  def register_branch(target, name, branch)
    methods = target.atomy_methods
    method = methods[name] ||= Atomy::Method.new(name)
    branch = method.add_branch(branch)
    [method, branch]
  end

  def define_branch(binding, name, branch)
    target =
      if branch.receiver
        branch.receiver.target
      else
        binding.constant_scope.for_method_definition
      end

    method, branch = register_branch(target, name, branch)

    if branch.name
      Rubinius.add_method(branch.name, branch.as_method, target, :public)
    end

    Rubinius.add_method(name, method.build, target, :public)
  end
end

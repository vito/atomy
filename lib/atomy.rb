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
    method.add_branch(branch)
    method
  end

  def define_branch(binding, name, branch)
    target =
      if branch.receiver
        branch.receiver.target
      else
        binding.constant_scope.for_method_definition
      end

    method = register_branch(target, name, branch)

    Rubinius.add_method(name, method.build, target, :public)
  end
end

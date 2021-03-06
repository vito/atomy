require File.expand_path('../lib/atomy/version', __FILE__)

Gem::Specification.new do |s|
  s.name = "atomy"

  s.version = Atomy::VERSION

  s.authors = ["Alex Suraci"]
  s.email = "suraci.alex@gmail.com"

  s.license = "Apache-2.0"
  s.homepage = "https://vito.github.io/atomy"

  s.summary = "the Atomy programming language"

  s.description = %q{
    A dynamic language targeting the Rubinius VM, focusing on extensibility
    and expressiveness through macros and pattern-matching.
  }

  s.add_runtime_dependency "kpeg", "~> 1.0"

  # don't pull these in - depend on the version provided by the Rubinius
  # installation instead, otherwise this could generate instructions for the
  # wrong version of Rubinius
  # s.add_runtime_dependency "rubinius-compiler", "~> 3.0"
  # s.add_runtime_dependency "rubinius-ast", "~> 3.0"

  s.add_development_dependency "rake", "~> 10.4"
  s.add_development_dependency "rspec-its", "~> 1.2"

  s.files = %w{LICENSE.md Gemfile} + Dir["{lib,kernel,bin}/**/*"]

  s.executables = ["atomy"]

  s.require_paths = ["lib"]
end

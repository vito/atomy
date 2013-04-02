require File.expand_path('../lib/atomy/version', __FILE__)

Gem::Specification.new do |s|
  s.name = "atomy"

  s.version = Atomy::VERSION

  s.authors = ["Alex Suraci"]
  s.email = "suraci.alex@gmail.com"

  s.license = "BSD"
  s.homepage = "http://atomy-lang.org"
  s.summary = "the Atomy programming language"
  s.description = s.summary

  # TODO: make a development dependency
  s.add_runtime_dependency "kpeg", "~> 0.10.0"

  s.add_development_dependency "rake"

  s.files = %w{LICENSE Gemfile} + Dir["{lib,kernel,bin}/**/*"]

  s.executables = ["atomy"]

  s.require_paths = ["lib"]
end

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
  s.has_rdoc = false

  s.add_dependency "kpeg", "~> 0.8.4"

  s.add_development_dependency "rake"

  ignores = File.readlines(".gitignore").grep(/\S+/).map(&:chomp)

  s.files = %w{LICENSE Gemfile} + Dir["{lib,kernel,bin}/**/*"]

  s.executables = ["atomy"]

  s.require_paths = ["lib"]
end

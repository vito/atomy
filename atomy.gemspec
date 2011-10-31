Gem::Specification.new do |s|
  s.name = "atomy"
  s.version = "0.1.1"

  s.authors = ["Alex Suraci"]
  s.date = "2011-02-26"
  s.email = "i.am@toogeneric.com"

  files =
    ["README.md", "COPYING", "bin/atomy"] +
    Dir.glob("lib/ast/**/*.rb") +
    Dir.glob("lib/patterns/**/*.rb") +
    Dir.glob("lib/compiler/**/*.rb") +
    Dir.glob("lib/*.rb") +
    Dir.glob("kernel/**/*.ay")

  files = files.reject{ |f| f =~ /\.(ayc|rbc)$/ }

  s.files = files

  s.executables = ["atomy"]

  s.license = "BSD"

  s.has_rdoc = false
  s.homepage = "http://www.atomy-lang.org"
  s.rubyforge_project = "atomy"
  s.summary = "the Atomy programming language"
  s.description = s.summary

  s.add_dependency "hamster", "~> 0.4.2"

  s.add_development_dependency "rake"
end

Gem::Specification.new do |s|
  s.name = "atomy"
  s.version = "0.0.1"

  s.authors = ["Alex Suraci"]
  s.date = "2011-02-26"
  s.email = "i.am@toogeneric.com"

  files =
    ["README.md", "COPYING", "bin/atomy"] +
    Dir.glob("lib/ast/**/*.rb") +
    Dir.glob("lib/patterns/**/*.rb") +
    Dir.glob("lib/compiler/**/*.rb") +
    Dir.glob("lib/*.rb") +
    Dir.glob("kernel/**/*.atomy")

  files = files.reject{ |f| f =~ /\.(atomyc|rbc)$/ }

  s.files = files

  s.executables = ["atomy"]

  s.license = "BSD"

  s.has_rdoc = false
  s.homepage = "http://www.atomy-lang.org"
  s.rubyforge_project = "atomy"
  s.summary = "atomy programming language"
  s.description = <<EOD
atomy is a small, simple, insanely flexible and expressive programming
language. its design is inspired by Scheme (small, simple core), Slate
(multiple dispatch, keywords), Ruby (very DSL-friendly), and Erlang
(message-passing concurrency).
EOD
end

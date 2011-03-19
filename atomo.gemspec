Gem::Specification.new do |s|
  s.name = "atomo"
  s.version = "0.0.1"

  s.authors = ["Alex Suraci"]
  s.date = "2011-02-26"
  s.email = "i.am@toogeneric.com"

  files =
    ["README.md", "COPYING", "bin/quanto"] +
    Dir.glob("lib/atomo/ast/**/*.rb") +
    Dir.glob("lib/atomo/patterns/**/*.rb") +
    Dir.glob("lib/atomo/compiler/**/*.rb") +
    Dir.glob("lib/atomo/*.rb") +
    Dir.glob("kernel/**/*.atomo")

  files = files.reject{ |f| f =~ /\.(atomoc|rbc)$/ }

  s.files = files

  s.executables = ["quanto"]

  s.license = "BSD"

  s.has_rdoc = false
  s.homepage = "http://www.atomo-lang.org"
  s.rubyforge_project = "atomo"
  s.summary = "atomo programming language"
  s.description = <<EOD
atomo is a small, simple, insanely flexible and expressive programming
language. its design is inspired by Scheme (small, simple core), Slate
(multiple dispatch, keywords), Ruby (very DSL-friendly), and Erlang
(message-passing concurrency).
EOD
end

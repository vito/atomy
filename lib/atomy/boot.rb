base = File.expand_path "../", __FILE__
kernel = File.expand_path "../../../kernel/", __FILE__

$LOAD_PATH.unshift kernel


module Atomy
  def self.load(*as)
    CodeLoader.load_file *as
  end
end

require "rubygems"
require "set"

require base + "/version"
require base + "/module"
require base + "/macros"
require base + "/method"
require base + "/exceptions"
require base + "/util"
require base + "/copy"
require base + "/compiler/compiler"
require base + "/compiler/stages"
require base + "/parser"
require base + "/patterns"
require base + "/precision"
require base + "/code_loader"
require base + "/rubygems"

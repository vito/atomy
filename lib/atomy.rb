base = File.expand_path "../atomy", __FILE__

module Atomy
  def self.load(*as)
    CodeLoader.load_file *as
  end

  def self.load_kernel
    require(File.expand_path("../../kernel/boot", __FILE__))
  end
end

require "rubygems"

require base + "/version"
require base + "/macros"
require base + "/method"
require base + "/exceptions"
require base + "/util"
require base + "/compiler/compiler"
require base + "/compiler/stages"
require base + "/parser"
require base + "/patterns"
require base + "/precision"
require base + "/code_loader"
require base + "/rubygems"

base = File.expand_path "../", __FILE__
kernel = File.expand_path "../../../kernel/", __FILE__

$LOAD_PATH.unshift kernel


module Rubinius
  class Location
    attr_writer :name
    attr_accessor :flags
  end
end

module Atomy
  def self.load(file, debug = false)
    CodeLoader.load_file file, debug
  end

  def self.run(file, debug = false)
    load(file, debug)
  rescue SystemExit => e
    Kernel.exit(e.status)
  rescue Object => e
    e.render "An exception occurred running #{file}"
    Kernel.exit(1)
  end
end

require "rubygems"
require "set"

require "rubinius/compiler"
require "rubinius/ast"

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
require base + "/rubygems/custom_require"
require base + "/backtrace"

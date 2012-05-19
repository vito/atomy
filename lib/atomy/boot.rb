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
  def self.load(*as)
    CodeLoader.load_file *as
  rescue => e
    trim_backtrace!(e.locations)
    raise
  end

  # clean up internal plumbing from backtraces
  def self.trim_backtrace!(bt)
    bt.reject! do |l|
      if l.file == "__wrapper__"
        true
      elsif l.is_block && l.name == :__module_init__ && l.method.name != :__block__
        l.name = nil
        l.flags ^= 1

        false
      end
    end
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

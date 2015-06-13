# Patch up RubyGems/require (indirectly) to support loading
# Atomy gems

require "atomy"
require "atomy/codeloader"
require "atomy/module"

Gem.suffixes << ".ay"

module Kernel
  alias atomy_original_gem_original_require gem_original_require
  alias atomy_original_require require

  def require(name)
    if file = Atomy::CodeLoader.find_source(name)
      Atomy::CodeLoader.require(file)
    else
      atomy_original_require(name)
    end
  end

  def gem_original_require(name)
    if file = Atomy::CodeLoader.find_source(name)
      Atomy::CodeLoader.require(file)
    else
      atomy_original_gem_original_require(name)
    end
  end

  module_function :require
  module_function :gem_original_require

  private :atomy_original_gem_original_require
  private :atomy_original_require
end

# this is here so it's more likely to be filtered out of caller checks
#
# (e.g. sinatra/base)
class Atomy::Module
  def require(path)
    if path.start_with? "./"
      Kernel.require(File.expand_path("../" + path, @file.to_s))
    else
      Kernel.require(path)
    end
  end
end

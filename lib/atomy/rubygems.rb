# Patch up RubyGems/require (indirectly) to support loading
# Atomy gems

Gem.suffixes << ".ay"

module Kernel
  alias atomy_original_require gem_original_require

  def gem_original_require(name)
    if file = Atomy::CodeLoader.find_atomy(name)
      Atomy::CodeLoader.load_file(file)
    else
      atomy_original_require(name)
    end
  end

  private :atomy_original_require
end

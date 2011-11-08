# Patch up RubyGems/require (indirectly) to support loading
# Atomy gems

Gem.suffixes << ".ay"

module Kernel
  # rubygems has patched things up already; sneak in there after it does
  # its work by overriding what it thinks is the original #require
  if defined? gem_original_require
    alias atomy_original_require gem_original_require

    def gem_original_require(name)
      if file = Atomy::CodeLoader.find_atomy(name)
        Atomy::CodeLoader.load_file(file)
      else
        atomy_original_require(name)
      end
    end

  # simpler route; just override the core #require to handle Atomy code
  else
    alias atomy_original_require require

    def require(name)
      if file = Atomy::CodeLoader.find_atomy(name)
        Atomy::CodeLoader.load_file(file)
      else
        atomy_original_require(name)
      end
    end
  end

  private :atomy_original_require
end

require "atomy/bootstrap"
require "atomy/compiler"
require "atomy/parser"
require "atomy/module"

module Atomy
  module CodeLoader
    extend self

    def run_script(path)
      file = find_source(path)

      raise LoadError, "no such file to load -- #{path}" unless file

      mod = Atomy::Module.new { use(Atomy::Bootstrap) }
      mod.file = file.to_sym

      node = Atomy::Parser.parse_file(file)

      code = Atomy::Compiler.compile(node, mod)

      code.scope = Rubinius::ConstantScope.new(mod, code.scope)

      Rubinius.attach_method(:__script__, code, code.scope, mod)

      [mod.__script__, mod]
    end

    def find_source(path, search_in = $LOAD_PATH)
      if qualified?(path)
        expanded = File.expand_path(path)
        return expanded if File.exists?(expanded)

        expanded = "#{expanded}#{source_extension}"
        return expanded if File.exists?(expanded)
      else
        search_path(path, search_in)
      end
    end

    private

    def source_extension
      ".ay"
    end

    def search_path(path, load_paths)
      load_paths.each do |load_path|
        if found = find_source("#{load_path}/#{path}")
          return found
        end
      end

      nil
    end

    # something that doesn't look like it should be grabbed from the load
    # path
    def qualified?(path)
      path =~ /^([~\/]|\.\.?\/)/
    end
  end
end

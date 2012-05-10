require("stringio")

module Atomy
  class CodeLoader
    # TODO: make thread-safe
    LOADED = {}

    class << self
      def compiled_name(fn)
        Atomy::Compiler.compiled_name(fn)
      end

      def source_name(fn)
        if fn.suffix? ".compiled.ayc"
          fn[0..-(".compiled.ayc".size)]
        elsif fn.suffix? ".ayc"
          fn[0..-2]
        end
      end

      def find_file(fn)
        if fn.suffix? ".ay" and loadable? fn
          fn
        elsif loadable?(fn + ".ay")
          fn + ".ay"
        end
      end

      def find_any_file(fn)
        if loadable? fn
          fn
        elsif loadable?(fn + ".ay")
          fn + ".ay"
        end
      end

      def loadable?(fn)
        return false unless File.exists? fn

        stat = File.stat fn
        stat.file? && stat.readable?
      end

      def search_path(fn)
        $LOAD_PATH.each do |dir|
          path = find_file("#{dir}/#{fn}")
          return path if path
        end

        nil
      end

      def find_atomy(fn)
        if qualified_path?(fn)
          find_file(fn)
        else
          search_path(fn)
        end
      end

      def qualified_path?(path)
        path[0] == ?/ or path.prefix?("./") or path.prefix?("../")
      end

      def require(fn)
        unless file = find_atomy(fn)
          raise LoadError, "no such file to load -- #{fn}"
        end

        load_file(file)
      end

      def compilation_needed?(fn)
        compiled = compiled_name(fn)

        !loadable?(compiled) ||
          File.stat(compiled).mtime < File.stat(fn).mtime
      end

      def load_file(fn, debug = false)
        unless found = find_any_file(fn)
          raise LoadError, "no such file to load -- #{fn}"
        end

        file = found.to_sym
        loaded = LOADED[file]
        needs_loading = compilation_needed?(found)
        return loaded if loaded and not needs_loading

        mod = Atomy::Module.new(file)

        begin
          LOADED[file] = mod

          if needs_loading
            Compiler.compile mod, nil, debug
          else
            cfn = compiled_name(fn)
            cl = Rubinius::CodeLoader.new(cfn)
            cm = cl.load_compiled_file(cfn, 0, 0)

            Rubinius.attach_method(:__module_init__, cm, mod.compile_context.static_scope, mod)
            mod.__module_init__
          end

          mod
        rescue
          if loaded
            LOADED[file] = loaded
          else
            LOADED.delete file
          end

          puts "when loading #{file}..."
          raise
        end
      end
    end
  end
end

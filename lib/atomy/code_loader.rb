require("stringio")

module Atomy
  class CodeLoader
    # TODO: make thread-safe
    LOADED = {}

    class << self
      # TODO: compiling -> loaded
      attr_accessor :module, :context, :compiling

      def reason
        @reason ||= :run
      end

      def reason=(x)
        @reason = x
      end

      # TODO: make sure this works as expected with multiple loadings
      def compiled?
        @compiled ||= false
      end

      def compiled!(x = false)
        @compiled = x
      end

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

      def load_file(fn, r = :load, debug = false)
        unless found = find_any_file(fn)
          raise LoadError, "no such file to load -- #{fn}"
        end

        file = found.to_sym
        loaded = LOADED[file]
        needs_loading = compilation_needed?(found)
        return loaded if loaded and not needs_loading

        old_reason = CodeLoader.reason
        old_compiled = CodeLoader.compiled?
        old_compiling = CodeLoader.compiling
        old_context = CodeLoader.context
        old_module = CodeLoader.module

        mod, bnd = Atomy.make_wrapper_module(file)

        begin
          LOADED[file] = mod

          CodeLoader.reason = r
          CodeLoader.compiled! false
          CodeLoader.compiling = file
          CodeLoader.context = bnd
          CodeLoader.module = mod

          if needs_loading
            CodeLoader.compiled! true
            Compiler.compile fn, nil, debug
          else
            cfn = compiled_name(fn)
            cl = Rubinius::CodeLoader.new(cfn)
            cm = cl.load_compiled_file(cfn, 0, 0)

            script = Rubinius::CompiledMethod::Script.new(cm)
            script.file_path = file.to_s

            bnd.static_scope.script = script

            Rubinius.attach_method(:__module_init__, cm, bnd.static_scope, mod)
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
        ensure
          CodeLoader.reason = old_context
          CodeLoader.compiled! old_compiled
          CodeLoader.compiling = old_compiling
          CodeLoader.context = old_context
          CodeLoader.module = old_module
        end
      end
    end
  end
end

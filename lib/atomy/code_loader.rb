require("stringio")

module Atomy
  class CodeLoader
    class << self
      def reason
        @reason ||= :run
      end

      def reason=(x)
        @reason = x
      end

      def when_load
        @when_load ||= []
      end

      def when_load=(x)
        @when_load = x
      end

      def compiling
        @compiling ||= :macro
      end

      def compiling=(x)
        @compiling = x
      end

      def when_run
        @when_run ||= []
      end

      def when_run=(x)
        @when_run = x
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

      def compile_if_needed(fn, debug = false)
        compiled = compiled_name(fn)

        if !loadable?(compiled) ||
            File.stat(compiled).mtime < File.stat(fn).mtime
          CodeLoader.compiled! true
          Compiler.compile fn, nil, debug
        end

        compiled
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

      def load_file(fn, r = :load, debug = false)
        unless file = find_any_file(fn)
          raise LoadError, "no such file to load -- #{fn}"
        end

        CodeLoader.when_load = []
        CodeLoader.when_run = []
        CodeLoader.reason = r
        CodeLoader.compiled! false
        CodeLoader.compiling = file

        cfn = compile_if_needed(file, debug)
        cl = Rubinius::CodeLoader.new(cfn)
        cm = cl.load_compiled_file(cfn, 0, 0)
        script = cm.create_script(false)
        script.file_path = file

        CodeLoader.compiling = nil

        MAIN.__send__ :__script__
      end
    end
  end
end

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

      def compiled?
        @compiled ||= false
      end

      def compiled!(x = false)
        @compiled = x
      end

      def documentation
        @documentation ||= false
      end

      def documentation=(x)
        @documentation = x
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

      def docs_name(fn)
        CodeLoader.documentation + "/" + File.basename(fn, ".ay") + ".ddl"
      end

      def compile_if_needed(fn, debug = false, docs = false)
        source = source_name(fn)
        compiled = compiled_name(fn)

        if !File.exists?(compiled) ||
            File.stat(compiled).mtime < File.stat(fn).mtime ||
            CodeLoader.documentation
          if CodeLoader.documentation
            Thread.current[:atomy_documentation] = docs = StringIO.new
            docs << "\\style{Atomy}\n\n"
            before = docs.size
          end

          CodeLoader.compiled! true
          Compiler.compile fn, nil, debug

          if CodeLoader.documentation && docs.size > before
            File.open(docs_name(fn), "w") do |f|
              f.write(Thread.current[:atomy_documentation].string)
            end
          end
        end

        compiled
      end

      def find_file(fn)
        if fn.suffix?(".ay") || fn.suffix?(".rb")
          fn
        elsif File.exists?(fn + ".ay")
          fn + ".ay"
        elsif File.exists?(fn + ".rb")
          fn + ".rb"
        else
          fn
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
          return path if loadable? path
        end

        nil
      end

      def qualified_path?(path)
        path[0] == ?/ or path.prefix?("./") or path.prefix?("../")
      end

      def load_file(fn, r = :run, debug = false)
        if qualified_path?(fn)
          file = find_file(fn)
        else
          file = search_path(fn)
        end

        raise("cannot find file to load for #{fn}") unless file

        return require(file) unless file.suffix?(".ay")

        CodeLoader.when_load = []
        CodeLoader.reason = r
        CodeLoader.compiled! false

        cfn = compile_if_needed(file, debug)
        cl = Rubinius::CodeLoader.new(cfn)
        cm = cl.load_compiled_file(cfn, 0)
        script = cm.create_script(false)
        script.file_path = fn

        MAIN.__send__ :__script__
      end
    end
  end
end

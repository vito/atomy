module Atomy
  class CodeLoader
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

      def compile_if_needed(fn)
        source = source_name(fn)
        compiled = compiled_name(fn)

        if !File.exists?(compiled) ||
            File.stat(compiled).mtime < File.stat(fn).mtime
          Compiler.compile fn
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

      def load_file(fn)
        if qualified_path?(fn)
          file = find_file(fn)
        else
          file = search_path(fn)
        end

        raise("cannot find file to load for #{fn}") unless file

        return require(file) unless file.suffix?(".ay")

        before = Atomy::NAMESPACES.dup

        cfn = compile_if_needed(file)
        cl = Rubinius::CodeLoader.new(cfn)
        cm = cl.load_compiled_file(cfn, 0)
        script = cm.create_script(false)
        script.file_path = fn

        Atomy::NAMESPACES.clear.merge!(before)

        MAIN.__send__ :__script__
      end
    end
  end
end

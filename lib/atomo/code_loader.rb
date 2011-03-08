module Atomo
  class CodeLoader
    class << self
      def compiled_name(fn)
        Atomo::Compiler.compiled_name(fn)
      end

      def source_name(fn)
        if fn.suffix? ".compiled.atomoc"
          fn[0..-(".compiled.atomoc".size)]
        elsif fn.suffix? ".atomoc"
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

      def load_file(fn)
        cfn = compile_if_needed(fn)
        cl = Rubinius::CodeLoader.new(cfn)
        cm = cl.load_compiled_file(cfn, 0)
        script = cm.create_script(false)
        script.file_path = fn
        MAIN.__send__ :__script__
      end
    end
  end
end

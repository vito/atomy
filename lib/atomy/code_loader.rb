require("stringio")

module Atomy
  class CodeLoader
    # TODO: make thread-safe
    LOADED = {}

    class << self
      def reason
        @reason ||= :run
      end

      def reason=(x)
        @reason = x
      end

      def module
        @module
      end

      def module=(x)
        @module = x
      end

      def context
        @context
      end

      def context=(x)
        @context = x
      end

      def compiling
        @compiling
      end

      def compiling=(x)
        @compiling = x
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
        unless file = find_any_file(fn)
          raise LoadError, "no such file to load -- #{fn}"
        end

        loaded = LOADED[file]
        return loaded if loaded

        old_reason = CodeLoader.reason
        old_compiled = CodeLoader.compiled?
        old_compiling = CodeLoader.compiling
        old_context = CodeLoader.context
        old_module = CodeLoader.module

        mod = Module.new
        mod.private_module_function
        mod.const_set(:Self, mod)

        mod.singleton_class.dynamic_method(:__module_init__, file) do |g|
          g.push_self
          g.add_scope

          g.push_self
          g.send :private_module_function, 0
          g.pop

          g.push_variables
          g.push_scope
          g.make_array 2
          g.ret
        end

        LOADED[file] = mod

        vs, ss = mod.__module_init__
        bnd = Binding.setup(
          vs,
          vs.method,
          ss,
          mod
        )

        begin
          CodeLoader.reason = r
          CodeLoader.compiled! false
          CodeLoader.compiling = file.to_sym
          CodeLoader.context = bnd
          CodeLoader.module = mod

          LOADED[file.to_sym] = mod

          if compilation_needed?(fn)
            CodeLoader.compiled! true
            Compiler.compile fn, nil, debug
          else
            cfn = compiled_name(fn)
            cl = Rubinius::CodeLoader.new(cfn)
            cm = cl.load_compiled_file(cfn, 0, 0)

            script = Rubinius::CompiledMethod::Script.new(cm)
            script.file_path = file

            ss.script = script

            Rubinius.attach_method(:__module_init__, cm, ss, mod)
            mod.__module_init__
          end

          mod
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

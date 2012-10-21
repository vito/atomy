require("stringio")

module Atomy
  class CodeLoader
    LOADED_MODULES = {}

    Lock = Object.new

    class RequireRequest
      def initialize(map, key)
        @map = map
        @key = key
        @for = nil
        @module = nil
        @loaded = false
        @remove = true
      end

      attr_accessor :module

      def take!
        lock
        @for = Thread.current
      end

      def current_thread?
        @for == Thread.current
      end

      def lock
        Rubinius.lock(self)
      end

      def unlock
        Rubinius.unlock(self)
      end

      def wait
        Rubinius.synchronize(Lock) do
          @remove = false
        end

        take!

        Rubinius.synchronize(Lock) do
          if @loaded
            @map.delete @key
          end
        end

        return @loaded
      end

      def passed!
        @loaded = true
      end

      def remove!
        Rubinius.synchronize(Lock) do
          if @loaded or @remove
            @map.delete @key
          end
        end

        unlock
      end
    end

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

        require(found, debug)
      end

      def require(file, debug = false)
        wait = false
        req = nil

        reqs = load_map

        Rubinius.synchronize(Lock) do
          if req = reqs[file]
            return req.module if req.current_thread?
            wait = true
          else
            req = RequireRequest.new(reqs, file)
            reqs[file] = req
            req.take!
          end
        end

        if wait
          if req.wait
            # While waiting the code was loaded by another thread.
            # We need to release the lock so other threads can continue too.
            req.unlock
            return req.module
          end

          # The other thread doing the lock raised an exception
          # through the require, so we try and load it again here.
        end

        begin
          mod = load_atomy(req, file, debug)
        else
          req.passed!
        ensure
          req.remove!
        end

        mod
      end

      private

      def load_map
        @load_map ||= {}
      end

      def load_atomy(req, filename, debug = false)
        file = filename.to_sym
        loaded = LOADED_MODULES[file]
        needs_loading = compilation_needed?(filename)
        return loaded if loaded and not needs_loading

        mod = Atomy::Module.new(file)
        req.module = mod

        begin
          LOADED_MODULES[file] = mod

          if needs_loading
            Compiler.compile mod, nil, debug
          else
            cfn = compiled_name(filename)
            cl = Rubinius::CodeLoader.new(cfn)
            cm = cl.load_compiled_file(cfn, 0, 0)

            Rubinius.attach_method(
              :__script__,
              cm,
              mod.compile_context.constant_scope,
              mod)

            mod.__script__
          end

          mod
        rescue
          if loaded
            LOADED_MODULES[file] = loaded
          else
            LOADED_MODULES.delete file
          end

          raise
        end
      end
    end
  end
end

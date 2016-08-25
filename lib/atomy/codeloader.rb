require "fileutils"

require "atomy/bootstrap"
require "atomy/compiler"
require "atomy/parser"
require "atomy/module"

require "rubinius/code/compiler"
require "rubinius/code/compiler/compiled_file"

module Atomy
  module CodeLoader
    LOADED_MODULES = {}

    extend self

    def load_map
      @load_map ||= {}
    end

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

        @loaded
      end

      def passed!
        @loaded = true
      end

      def remove!
        Rubinius.synchronize(Lock) do
          if @loaded || @remove
            @map.delete(@key)
          end
        end

        unlock
      end
    end

    def require(path)
      file = find_source(path)

      return super unless file

      synchronized_load(file, false)
    end

    def load(path)
      file = find_source(path)
      unless file
        raise LoadError, "atomy source not found: #{path}"
      end

      synchronized_load(file, true)
    end

    def synchronized_load(file, check_up_to_date)
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
        mod = load_atomy(file, check_up_to_date)
      else
        req.module = mod
        req.passed!
      ensure
        req.remove!
      end

      mod
    end

    def register_feature(file, mod)
      LOADED_MODULES[file] = {
        module: mod,
        time: Time.now
      }

      $LOADED_FEATURES << file
    end

    def load_atomy(file, check_up_to_date)
      if loaded?(file, check_up_to_date)
        LOADED_MODULES[file][:module]
      else
        _, mod = run_script(file)
        register_feature(file, mod)
        mod
      end
    end

    def run_script(path)
      file = find_source(path)

      raise LoadError, "no such file to load -- #{path}" unless file

      mod = Atomy::Module.new { use(Atomy::Bootstrap) }
      mod.file = file.to_sym

      compiled_file_name = CodeTools::Compiler.compiled_name(file)
      if compiled_file_up_to_date(compiled_file_name, file)
        code_loader = Rubinius::CodeLoader.new(compiled_file_name)
        code = code_loader.load_compiled_file(compiled_file_name, 0, 0)

        Rubinius.attach_method(
          :__script__,
          code,
          mod.compile_context.lexical_scope,
          mod)

        res = mod.__script__

        return [res, mod]
      end

      node = Atomy::Parser.parse_file(file)

      res = nil
      code =
        Atomy::Compiler.package(mod.file) do |gen|
          res = evaluate_sequences(gen, node, mod)
        end

      if ENV["DEBUG"]
        printer = CodeTools::Compiler::MethodPrinter.new
        printer.bytecode = true
        printer.print_method(code)
      end

      write_compiled_file(compiled_file_name, mod, code) if compiled_file_name

      [res, mod]
    end

    def evaluate_sequences(gen, n, mod)
      if n.is_a?(Atomy::Grammar::AST::Sequence)
        res = nil

        n.nodes.each.with_index do |sub, i|
          gen.pop unless i == 0
          res = evaluate_sequences(gen, sub, mod)
        end

        res
      else
        res = mod.evaluate(n, mod.compile_context)
        mod.compile(gen, n)
        res
      end
    end

    def find_source(path, search_in = $LOAD_PATH)
      if qualified?(path)
        expanded = File.expand_path(path)
        return expanded if File.file?(expanded)

        expanded = "#{expanded}#{source_extension}"
        return expanded if File.file?(expanded)
      else
        search_path(path, search_in)
      end
    end

    def find_atomy_source(path, search_in = $LOAD_PATH)
      path += source_extension unless path.end_with?(source_extension)
      find_source(path)
    end

    private

    def loaded?(file, check_up_to_date)
      loaded = LOADED_MODULES[file]
      return false unless loaded

      if check_up_to_date
        return false if File.mtime(file) > loaded[:time]

        compiled_file = CodeTools::Compiler.compiled_name(file)
        return false unless compiled_file_up_to_date(compiled_file, file)
      end

      true
    end

    def source_extension
      ".ay"
    end

    def compiled_file_up_to_date(compiled_file, source_file)
      return false unless compiled_file
      return false unless File.exists?(compiled_file)

      compiled_mtime = File.mtime(compiled_file)
      return false if File.mtime(source_file) > compiled_mtime

      module_list_file_name = compiled_file + ".modules"
      if File.exists?(module_list_file_name)
        File.open(module_list_file_name, "r") do |io|
          io.each_line do |line|
            mod_file = line.rstrip
            return false if File.mtime(mod_file) > compiled_mtime
          end
        end
      end

      true
    end

    def write_compiled_file(compiled_file_name, mod, code)
      FileUtils.mkdir_p(File.expand_path("../", compiled_file_name))
      CodeTools::CompiledFile.dump(code, compiled_file_name, Rubinius::Signature, 0)

      module_list_file_name = compiled_file_name + ".modules"
      File.open(module_list_file_name, "w") do |io|
        mod.singleton_class.included_modules.each do |used_module|
          next if used_module == mod
          next unless used_module.is_a?(Atomy::Module) && used_module.file
          io.puts(used_module.file.to_s)
        end
      end
    end

    def search_path(path, load_paths)
      load_paths.each do |load_path|
        if found = find_source("#{load_path}/#{path}")
          return found
        end
      end

      if found = find_source("#{kernel_path}/#{path}")
        return found
      end

      nil
    end

    def kernel_path
      @kernel_path ||= File.expand_path("../../../kernel", __FILE__)
    end

    # something that doesn't look like it should be grabbed from the load
    # path
    def qualified?(path)
      path =~ /^([~\/]|\.\.?\/)/
    end
  end
end

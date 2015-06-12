require "spec_helper"

require "pathname"

require "atomy/codeloader"

describe Atomy::CodeLoader do
  describe ".run_script" do
    context "when the file exists" do
    end

    it "raises a LoadError if the file does not exist" do
      expect {
        Atomy::CodeLoader.run_script("some/bogus/file")
      }.to raise_error(LoadError, %r(some/bogus/file))
    end
  end

  describe ".find_source" do
    context "when the path is not qualified" do
      let(:load_path) { [fixture("codeloader/find_source")] }

      it "searches in the given load path" do
        expect(Atomy::CodeLoader.find_source("file-a", load_path)).to eq(
          fixture("codeloader/find_source/file-a.ay"))
      end

      it "finds files without an extension" do
        expect(Atomy::CodeLoader.find_source("file-b", load_path)).to eq(
          fixture("codeloader/find_source/file-b"))
      end

      it "finds modules in the kernel" do
        expect(Atomy::CodeLoader.find_source("core", load_path)).to eq(
          File.expand_path("../../../kernel/core.ay", __FILE__))
      end

      context "and .ay is given" do
        it "finds files with .ay at the end" do
          expect(Atomy::CodeLoader.find_source("file-a.ay", load_path)).to eq(
            fixture("codeloader/find_source/file-a.ay"))
        end

        it "does not find files without .ay at the end" do
          expect(
            Atomy::CodeLoader.find_source("file-b.ay", load_path)).to be_nil
        end
      end

      context "when the path refers to a directory" do
        it "does not mistakenly find the directory" do
          expect(
            Atomy::CodeLoader.find_source("some-dir", load_path)).to be_nil
        end
      end
    end

    context "when the path is relative from the home directory" do
      it "expands the path and looks there directly" do
        path = Pathname.new(fixture("codeloader/find_source/file-a.ay"))
        from_home = path.relative_path_from(Pathname.new(Dir.home))

        expect(Atomy::CodeLoader.find_source("~/#{from_home}")).to eq(
          fixture("codeloader/find_source/file-a.ay"))
      end
    end

    context "when the path is absolute" do
      it "expands the path and looks there directly" do
        abs_path = fixture("codeloader/find_source/file-a.ay")
        expect(Atomy::CodeLoader.find_source(abs_path)).to eq(
          fixture("codeloader/find_source/file-a.ay"))
      end
    end

    context "when given a relative path" do
      it "looks relative to the working directory" do
        path = Pathname.new(fixture("codeloader/find_source/file-a.ay"))
        relative = path.relative_path_from(Pathname.pwd)

        expect(Atomy::CodeLoader.find_source("./#{relative}")).to eq(
          fixture("codeloader/find_source/file-a.ay"))
      end

      it "can look up the path" do
        path = Pathname.new(fixture("codeloader/find_source/file-a.ay"))
        relative = path.relative_path_from(Pathname.pwd)

        up_path = "../#{Pathname.pwd.basename}/#{relative}"

        expect(Atomy::CodeLoader.find_source(up_path)).to eq(
          fixture("codeloader/find_source/file-a.ay"))
      end
    end
  end

  describe ".run_script" do
    before do
      Atomy::CodeLoader::LOADED_MODULES.clear
    end

    it "returns the result of the execution" do
      res, _ = Atomy::CodeLoader.run_script(
        fixture("codeloader/run_script/basic.ay"))

      expect(res).to eq("foo")
    end

    it "returns the module representing the file" do
      file = fixture("codeloader/run_script/basic.ay")
      _, mod = Atomy::CodeLoader.run_script(file)
      expect(mod).to be_a(Atomy::Module)
      expect(mod.file).to eq(file.to_sym)
    end

    it "runs the script with its module as self" do
      res, mod = Atomy::CodeLoader.run_script(
        fixture("codeloader/run_script/self.ay"))

      expect(res).to eq(mod)
    end
  end

  describe ".require" do
    context "when no other threads are loading the same file" do
      context "and the load succeeds" do
        it "returns the loaded module" do
          file = fixture("codeloader/require/basic.ay")
          mod = Atomy::CodeLoader.require(file)
          expect(mod).to be_a(Atomy::Module)
          expect(mod.file).to eq(file.to_sym)
        end
      end

      context "and the loading fails" do
        it "propagates the exception upward" do
          expect {
            Atomy::CodeLoader.require(fixture("codeloader/require/fail.ay"))
          }.to raise_error(/hell/)
        end
      end
    end

    context "when an Atomy file can not be found for the given path" do
      it "delegates to Ruby's #require" do
        expect { Atomy::CodeLoader.require("stringio") }.to_not raise_error
      end
    end

    context "when the file has already been loaded" do
      it "returns the loaded module" do
        mod = Atomy::CodeLoader.require(fixture("codeloader/require/basic"))
        mod2 = Atomy::CodeLoader.require(fixture("codeloader/require/basic"))
        expect(mod2).to eq(mod)
      end

      describe "requiring the same file again" do
        it "does not execute the file twice" do
          $foo = 0

          Atomy::CodeLoader.require(fixture("codeloader/require/global"))
          expect($foo).to eq(1)

          Atomy::CodeLoader.require(fixture("codeloader/require/global"))
          expect($foo).to eq(1)
        end
      end
    end

    context "when another thread is loading the same file", :slow => true do
      it "waits for the other thread to finish" do
        $foo = 0

        thd =
          Thread.new do
            Atomy::CodeLoader.require(
              fixture("codeloader/require/slow-global"))
          end

        Atomy::CodeLoader.require(fixture("codeloader/require/slow-global"))

        thd.join

        expect($foo).to eq(1)
      end

      context "and the require succeeds in the other thread" do
        it "returns the loaded module" do
          mod = nil

          thd =
            Thread.new do
              mod = Atomy::CodeLoader.require(
                fixture("codeloader/require/slow-global"))
            end

          mod2 = Atomy::CodeLoader.require(
            fixture("codeloader/require/slow-global"))

          thd.join

          expect(mod2).to eq(mod)
        end
      end

      context "and the require fails in the other thread" do
        it "retries loading it in the current thread" do
          $foo = 0

          thd =
            Thread.new do
              Atomy::CodeLoader.require(
                fixture("codeloader/require/slow-global-fail"))
            end

          expect {
            Atomy::CodeLoader.require(
              fixture("codeloader/require/slow-global-fail"))
          }.to raise_error("hell")

          expect { thd.join }.to raise_error("hell")

          expect($foo).to eq(2)
        end
      end
    end
  end
end

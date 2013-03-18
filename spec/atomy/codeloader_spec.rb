require "spec_helper"

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
    it "returns the result of the execution" do
      res, _ = Atomy::CodeLoader.run_script(fixture("codeloader/run_script/basic.ay"))
      expect(res).to eq("foo")
    end

    it "returns the module representing the file" do
      file = fixture("codeloader/run_script/basic.ay")
      _, mod = Atomy::CodeLoader.run_script(file)
      expect(mod).to be_a(Atomy::Module)
      expect(mod.file).to eq(file.to_sym)
    end

    it "runs the script with its module as self" do
      res, mod = Atomy::CodeLoader.run_script(fixture("codeloader/run_script/self.ay"))
      expect(res).to eq(mod)
    end
  end
end

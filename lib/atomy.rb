base = File.expand_path "../", __FILE__

require base + "/macros"
require base + "/method"
require base + "/exceptions"
require base + "/util"
require base + "/namespace"
require base + "/compiler/compiler"
require base + "/compiler/stages"
require base + "/parser"
require base + "/patterns"
require base + "/code_loader"

def Atomy.import(*as)
  before = Atomy::Namespace.get
  begin
    Atomy::CodeLoader.load_file *as
  ensure
    Atomy::Namespace.set(before)
  end
end

def Atomy.import_kernel
  Atomy.import(File.expand_path("../../kernel/boot", __FILE__))
end

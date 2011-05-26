base = File.expand_path "../", __FILE__

module Atomy
  def self.import(*as)
    before = Namespace.get
    begin
      CodeLoader.load_file *as
    ensure
      Namespace.set(before)
    end
  end

  def self.import_kernel
    import(File.expand_path("../../kernel/boot", __FILE__))
  end
end

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

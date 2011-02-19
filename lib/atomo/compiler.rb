base = File.expand_path "../", __FILE__

require base + "/compiler/compiler"
require base + "/compiler/stages"
require base + '/parser'

cm = Atomo::Compiler.compile_string ARGV[0]

cm.create_script(false)

begin
  MAIN.__send__ :__script__
rescue Exception => e
  puts "ERROR!"
  puts e
end

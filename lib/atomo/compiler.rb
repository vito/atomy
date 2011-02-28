base = File.expand_path "../", __FILE__
kernel = File.expand_path "../../../kernel/", __FILE__

require base + "/compiler/compiler"
require base + "/compiler/stages"
require base + '/parser'
require base + '/macros'

Kernel.send(:define_method, :"load:") do |a|
  cm = Atomo::Compiler.compile_file a

  cm.create_script(false)

  MAIN.__send__ :__script__
end

send(:"load:", kernel + "/core.atomo")
send(:"load:", kernel + "/therie.atomo")

cm = Atomo::Compiler.compile_string ARGV[0]

cm.create_script(false)

begin
  MAIN.__send__ :__script__
rescue Exception => e
  puts "ERROR!"
  puts e
end

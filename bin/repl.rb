base = File.expand_path "../../lib/atomo/", __FILE__

require 'readline'

require base + '/macros'
require base + "/compiler/compiler"
require base + "/compiler/stages"
require base + '/parser'

bnd = binding()

while str = Readline.readline("> ")
  continue if str.empty?

  begin
    res = Atomo::Compiler.evaluate str, bnd
    puts "=> #{res.inspect}"
  rescue Exception => e
    puts "ERROR!"
    puts "#{e}:\n  #{e.message}"
    puts e.backtrace
  end
end

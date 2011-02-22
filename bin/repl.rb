base = File.expand_path "../../lib/atomo/", __FILE__

require 'readline'

require base + "/compiler/compiler"
require base + "/compiler/stages"
require base + '/parser'

bnd = binding()

begin
  while str = Readline.readline("> ")
    continue if str.empty?

    res = Atomo::Compiler.evaluate str, bnd
    puts "=> #{res}"
  end
rescue Exception => e
  puts "ERROR!"
  puts "#{e}: #{e.message}"
  puts e.backtrace
end
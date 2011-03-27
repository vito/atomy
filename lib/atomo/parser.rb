base = File.expand_path "../", __FILE__

require base + "/atomo.kpeg.rb"

module Atomo
  class Parser
    def self.parse_string(source)
      p = new(source)
      p.raise_error unless p.parse
      AST::Tree.new(p.result)
    end

    def self.parse_file(name)
      p = new(File.open(name, "rb").read)
      p.raise_error unless p.parse
      AST::Tree.new(p.result)
    end
  end

  path = File.expand_path("../ast", __FILE__)

  require path + "/node"

  Dir["#{path}/**/*.rb"].sort.each do |f|
    require f
  end
end


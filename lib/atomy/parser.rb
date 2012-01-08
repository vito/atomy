base = File.expand_path "../", __FILE__

require base + "/atomy.kpeg.rb"

module Atomy
  class Parser
    def self.parse_node(source)
      p = new(source)
      p.raise_error unless p.parse("one_expression")
      p.result
    end

    def self.parse_string(source, &callback)
      p = new(source)
      p.callback = callback
      p.raise_error unless p.parse
      AST::Tree.new(0, p.result)
    end

    def self.parse_file(name, &callback)
      parse_string(File.open(name, "rb", &:read), &callback)
    end
  end

  path = File.expand_path("../ast", __FILE__)

  require path + "/node"

  Dir["#{path}/**/*.rb"].sort.each do |f|
    require f
  end
end


project = "Atomo"

name = ARGV.shift

path = "lib/ast/#{name.downcase}.rb"
test_path = "test/ast/test_#{name.downcase}.rb"

class_name = name.capitalize

class_name.gsub!(/_(.)/) { $1.upcase }

if File.exists?(path) or File.exists?(test_path)
  STDERR.puts "File for '#{name}' already exists, not overwriting"
  exit 1
end

code = <<-CODE
module #{project}
  module AST
    class #{class_name} < AST::Node
      #{project}::Parser.register self

      def self.rule_name
        "#{name}"
      end

      def initialize
        # Write me
      end

      def self.grammar(g)
        # Add grammar for node here
      end
    end
  end
end
CODE

File.open path, "w" do |t|
  t << code
end

puts "Wrote #{path}"

code = <<-CODE
require 'test/unit'
require 'atomo/parser'

class Test#{class_name} < Test::Unit::TestCase
  def test_parse
    str = "" # Change to string to parse
    parser = #{project}::Parser.new(str)
    node = parser.parse :#{name}

    assert_kind_of #{project}::AST::#{class_name}, node
    # Add assertions for initialized node
  end
end
CODE

File.open test_path, "w" do |t|
  t << code
end

puts "Wrote #{test_path}"

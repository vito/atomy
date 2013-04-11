require "spec_helper"

require "atomy/bootstrap"
require "atomy/code/list"

describe Atomy::Code::List do
  let(:compile_module) { Atomy::Module.new { use Atomy::Bootstrap } }

  subject { described_class.new([ast("1"), ast("2")]) }

  it_compiles_as do |gen|
    gen.push_int(1)
    gen.push_int(2)
    gen.make_array(2)
  end
end

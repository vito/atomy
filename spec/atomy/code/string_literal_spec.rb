require "spec_helper"

require "atomy/code/string_literal"

describe Atomy::StringLiteral do
  let(:compile_module) { nil }

  subject { described_class.new("foo") }

  it_compiles_as do |gen|
    gen.push_literal "foo"
    gen.string_dup
  end
end

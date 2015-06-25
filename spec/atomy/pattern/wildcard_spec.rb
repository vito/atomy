require "spec_helper"

require "atomy/module"
require "atomy/pattern/wildcard"

describe Atomy::Pattern::Wildcard do
  describe "#matches?" do
    it { should === nil }
    it { should === Object.new }
  end
end

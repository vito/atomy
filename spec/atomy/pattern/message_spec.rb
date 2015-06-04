require "spec_helper"

require "atomy/bootstrap"
require "atomy/module"
require "atomy/node/equality"
require "atomy/pattern/equality"
require "atomy/pattern/message"
require "atomy/pattern/wildcard"

describe Atomy::Pattern::Message do
  def wildcard(name = nil)
    Atomy::Pattern::Wildcard.new(name)
  end

  let(:receiver) { wildcard }
  let(:arguments) { [wildcard, wildcard] }

  subject { described_class.new(receiver, arguments) }

  its(:receiver) { should == receiver }
  its(:arguments) { should == arguments }
  its(:total_arguments) { should == 2 }
  its(:required_arguments) { should == 2 }
end

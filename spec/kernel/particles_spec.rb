require "spec_helper"

require "atomy/codeloader"

describe "particles kernel" do
  let(:particles) { Atomy::Module.new { use(require_kernel("particles")) } }

  it "defines literal syntax for .[a, b]" do
    expect(particles.evaluate(ast(".[1, _]"), particles.compile_context)).to eq(particles::Particle.new(undefined, :[], [1, undefined]))
  end

  it "does not clobber syntax for .[]" do
    expect(particles.evaluate(ast(".[]"))).to eq(:[])
  end

  it "defines literal syntax for .foo(a, b)" do
    expect(particles.evaluate(ast(".foo(1, _)"), particles.compile_context)).to eq(particles::Particle.new(undefined, :foo, [1, undefined]))
  end

  it "defines literal syntax for .foo?(a, b)" do
    expect(particles.evaluate(ast(".foo?(1, _)"), particles.compile_context)).to eq(particles::Particle.new(undefined, :foo?, [1, undefined]))
  end

  it "defines literal syntax for .foo!(a, b)" do
    expect(particles.evaluate(ast(".foo!(1, _)"), particles.compile_context)).to eq(particles::Particle.new(undefined, :foo!, [1, undefined]))
  end

  it "defines literal syntax for .(bar foo(a, b))" do
    expect(particles.evaluate(ast(".(42 foo(1, _))"), particles.compile_context)).to eq(particles::Particle.new(42, :foo, [1, undefined]))
  end

  it "defines literal syntax for .(bar foo?(a, b))" do
    expect(particles.evaluate(ast(".(42 foo?(1, _))"), particles.compile_context)).to eq(particles::Particle.new(42, :foo?, [1, undefined]))
  end

  it "defines literal syntax for .(bar foo!(a, b))" do
    expect(particles.evaluate(ast(".(42 foo!(1, _))"), particles.compile_context)).to eq(particles::Particle.new(42, :foo!, [1, undefined]))
  end

  it "defines literal syntax for .(bar [a, b])" do
    expect(particles.evaluate(ast(".(42 [1, _])"), particles.compile_context)).to eq(particles::Particle.new(42, :[], [1, undefined]))
  end

  it "defines literal syntax for .(+ a)" do
    expect(particles.evaluate(ast(".(+ 1)"), particles.compile_context)).to eq(particles::Particle.new(undefined, :+, [1]))
  end

  it "defines literal syntax for .(bar + a)" do
    expect(particles.evaluate(ast(".(42 + _)"), particles.compile_context)).to eq(particles::Particle.new(42, :+, [undefined]))
  end

  describe "Particle" do
    let(:receiver) { undefined }
    let(:message) { :some_message }
    let(:arguments) { [] }

    subject { particles::Particle.new(receiver, message, arguments) }

    describe "#arity" do
      context "when a receiver is missing" do
        its(:arity) { should == 1 }
      end

      context "when arguments are missing" do
        let(:arguments) { [undefined, 2, undefined] }
        its(:arity) { should == 3 }
      end

      context "when a receiver is present" do
        let(:receiver) { Object.new }
        its(:arity) { should == 0 }

        context "when arguments are missing" do
          let(:arguments) { [undefined, 2, undefined] }
          its(:arity) { should == 2 }
        end
      end
    end

    describe "#to_proc" do
      it "returns a Proc" do
        expect(subject.to_proc).to be_a(Proc)
      end

      describe "calling the proc" do
        context "with a receiver with no arguments" do
          let(:receiver) { Object.new }
          
          context "when called with no arguments" do
            it "sends the message to the receiver" do
              expect(receiver).to receive(:some_message).with(no_args)
              subject.to_proc.call
            end
          end
        end

        context "with an undefined receiver" do
          let(:receiver) { undefined }

          it "uses the first argument to populate the receiver, and then sends the message to it" do
            bound_receiver = Object.new
            expect(bound_receiver).to receive(:some_message).with(no_args)
            subject.to_proc.call(bound_receiver)
          end

          context "when called with no arguments" do
            it "raises ArgumentError" do
              expect { subject.to_proc.call }.to raise_error(ArgumentError)
            end
          end

          context "with arguments missing" do
            let(:arguments) { [undefined, 2, undefined] }
            let(:bound_receiver) { Object.new }

            it "fills in the receiver, followed by the arguments, and sends the message" do
              expect(bound_receiver).to receive(:some_message).with(1, 2, 3) do |*args|
                args
              end

              expect(subject.to_proc.call(bound_receiver, 1, 3)).to eq([1, 2, 3])
            end

            context "when called with too few arguments" do
              it "raises ArgumentError" do
                expect { subject.to_proc.call(bound_receiver, 1) }.to raise_error(ArgumentError)
              end
            end
          end
        end
      end
    end
  end
  
  describe "Symbol" do
    subject { :inject }

    # one required arg, the rest are splat
    its(:arity) { should == -2 }

    describe "#call" do
      it "sends the message to the receiverwith the given arguments and block" do
        expect(subject.call([1, 2, 3], 3) { |x, y| x + y }).to eq(9)
      end
    end
  end
end

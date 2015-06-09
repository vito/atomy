require "spec_helper"

require "atomy/codeloader"

describe "particles kernel" do
  let!(:particles) { Atomy::Module.new { use(require_kernel("particles")) } }

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
    subject { :size }

    its(:arity) { should == 1 }

    describe "#call" do
      it "sends the message to the receiverwith the given arguments and block" do
        expect(subject.call([1, 2, 3])).to eq(3)
      end
    end
  end

  describe "Atomy::Pattern::Particle" do
    let(:receiver) { wildcard }
    let(:message) { :some_message }
    let(:arguments) { particles.evaluate(particles.pattern(ast("[_]"))) }

    subject { Atomy::Pattern::Particle.new(receiver, message, arguments) }

    its(:target) { should == particles::Particle }

    describe "#matches?" do
      it { should === particles::Particle.new(undefined, :some_message, [undefined]) }
      it { should === particles::Particle.new(undefined, :some_message, [42]) }
      it { should === particles::Particle.new(42, :some_message, [undefined]) }
      it { should === particles::Particle.new(42, :some_message, [42]) }
      it { should_not === particles::Particle.new(undefined, :some_message, [undefined, undefined]) }
      it { should_not === particles::Particle.new(undefined, :some_message, [undefined, 42]) }
      it { should_not === particles::Particle.new(undefined, :some_other_message, [undefined]) }
      it { should_not === Object.new }

      context "with a receiver pattern" do
        let(:receiver) { equality(42) }

        it { should === particles::Particle.new(42, :some_message, [undefined]) }
        it { should_not === particles::Particle.new(43, :some_message, [undefined]) }
        it { should_not === particles::Particle.new(undefined, :some_message, [undefined]) }
        it { should_not === Object.new }
      end

      context "with argument patterns" do
        let(:arguments) { particles.evaluate(particles.pattern(ast("[42]"))) }

        it { should === particles::Particle.new(undefined, :some_message, [42]) }
        it { should_not === particles::Particle.new(undefined, :some_message, [43]) }
        it { should_not === particles::Particle.new(undefined, :some_message, [undefined]) }
        it { should_not === Object.new }

        context "with splats" do
          let(:arguments) { particles.evaluate(particles.pattern(ast("[42, *as]"))) }

          it { should === particles::Particle.new(undefined, :some_message, [42]) }
          it { should === particles::Particle.new(undefined, :some_message, [42, 43, 44]) }
          it { should_not === particles::Particle.new(undefined, :some_message, [43]) }
          it { should_not === particles::Particle.new(undefined, :some_message, [undefined]) }
          it { should_not === Object.new }
        end
      end
    end
  end

  it "defines pattern notation for particles, that bind" do
    expect(particles.evaluate(seq(".[] = .[]"), particles.compile_context)).to eq(:[])
    expect(particles.evaluate(seq(".[a] = .[1], a"), particles.compile_context)).to eq(1)
    expect(particles.evaluate(seq(".[*as] = .[], as"), particles.compile_context)).to eq([])
    expect(particles.evaluate(seq(".[a, *bs] = .[1, 2, 3], [a, bs]"), particles.compile_context)).to eq([1, [2, 3]])
    expect(particles.evaluate(seq(".[a, *bs] = .[1], [a, bs]"), particles.compile_context)).to eq([1, []])
    expect(particles.evaluate(seq(".(+ a) = .(+ 1), a"), particles.compile_context)).to eq(1)
    expect(particles.evaluate(seq(".(a + b) = .(+ 1), [a, b]"), particles.compile_context)).to eq([undefined, 1])
    expect(particles.evaluate(seq(".(1 + a) = .(1 + 2), a"), particles.compile_context)).to eq(2)
    expect(particles.evaluate(seq(".foo(a) = .foo(1), a"), particles.compile_context)).to eq(1)
    expect(particles.evaluate(seq(".foo() = .foo"), particles.compile_context)).to eq(:foo)
    expect(particles.evaluate(seq(".foo(*as) = .foo(1), as"), particles.compile_context)).to eq([1])
    expect(particles.evaluate(seq(".foo(a, *bs) = .foo(1), [a, bs]"), particles.compile_context)).to eq([1, []])
    expect(particles.evaluate(seq(".foo(a) = .(42 foo(1)), a"), particles.compile_context)).to eq(1)
    expect(particles.evaluate(seq(".(42 foo(a)) = .(42 foo(1)), a"), particles.compile_context)).to eq(1)
    expect(particles.evaluate(seq(".(a foo(b)) = .(42 foo(1)), [a, b]"), particles.compile_context)).to eq([42, 1])
    expect(particles.evaluate(seq(".(a foo(b)) = .(_ foo(1)), [a, b]"), particles.compile_context)).to eq([undefined, 1])
    expect(particles.evaluate(seq(".(a foo(b)) = .foo(1), [a, b]"), particles.compile_context)).to eq([undefined, 1])

    expect { particles.evaluate(seq(".[] = .nope"), particles.compile_context) }.to raise_error(Atomy::PatternMismatch)
    expect { particles.evaluate(seq(".[a] = .[1, 2]"), particles.compile_context) }.to raise_error(Atomy::PatternMismatch)
    expect { particles.evaluate(seq(".[a, *as] = .[]"), particles.compile_context) }.to raise_error(Atomy::PatternMismatch)
    expect { particles.evaluate(seq(".foo(a) = .foo"), particles.compile_context) }.to raise_error(Atomy::PatternMismatch)
    expect { particles.evaluate(seq(".(a foo(b)) = .bar(1)"), particles.compile_context) }.to raise_error(Atomy::PatternMismatch)
    expect { particles.evaluate(seq(".(a foo(2)) = .foo(1)"), particles.compile_context) }.to raise_error(Atomy::PatternMismatch)
    expect { particles.evaluate(seq(".(2 foo(_)) = .foo(1)"), particles.compile_context) }.to raise_error(Atomy::PatternMismatch)
    expect { particles.evaluate(seq(".(2 foo(_)) = .(3 foo(1))"), particles.compile_context) }.to raise_error(Atomy::PatternMismatch)
  end
end

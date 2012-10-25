require("rubygems")
require("benchmark/ips")

class Fixnum
  def fib_cond
    if self == 0
      1
    elsif self == 1
      1
    else
      (self - 2).fib_cond + (self - 1).fib_cond
    end
  end
end

class Fixnum
  def fib_atomy_method_1; 1; end
  def fib_atomy_method_2; 1; end
  def fib_atomy_method_3
    (self - 2).fib_atomy_methods + (self - 1).fib_atomy_methods
  end

  def fib_atomy_methods
    if self == 0
      fib_atomy_method_1
    elsif self == 1
      fib_atomy_method_2
    else
      fib_atomy_method_3
    end
  end
end

class Fixnum
  define_method(:fib_closure_1) { 1 }
  define_method(:fib_closure_2) { 1 }
  define_method(:fib_closure_3) {
    (self - 2).fib_atomy_closure + (self - 1).fib_atomy_closure
  }

  def fib_atomy_closure
    if self == 0
      fib_closure_1
    elsif self == 1
      fib_closure_2
    else
      fib_closure_3
    end
  end
end

#profiler = Rubinius::Profiler::Instrumenter.new
#profiler.start

Benchmark.ips do |x|
  x.report("20.fib_cond") do
    20.fib_cond
  end

  x.report("20.fib_atomy_methods") do
    20.fib_atomy_methods
  end

  x.report("20.fib_atomy_closure") do
    20.fib_atomy_closure
  end
end

#profiler.stop
#profiler.show

#puts ""
#puts "fib_atomy_closure"
#puts 20.method(:fib_atomy_closure).executable.decode

#[:fib_closure_1, :fib_closure_2, :fib_closure_3].each do |m|
  #puts ""
  #puts m
  #puts 20.method(m).executable.block_env.compiled_code.decode
#end

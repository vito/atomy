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
  def fib_atomy_1; 1; end
  def fib_atomy_2; 1; end
  def fib_atomy_3; (self - 2).fib_atomy + (self - 1).fib_atomy; end

  def fib_atomy
    if self == 0
      fib_atomy_1
    elsif self == 1
      fib_atomy_2
    else
      fib_atomy_3
    end
  end
end

Benchmark.ips do |x|
  x.report("20.fib_cond") do
    20.fib_cond
  end

  x.report("20.fib_atomy") do
    20.fib_atomy
  end
end

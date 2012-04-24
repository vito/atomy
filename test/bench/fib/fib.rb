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
  def fib_atomy_sub_1; 1; end
  def fib_atomy_sub_2; 1; end
  def fib_atomy_sub_3; (self - 2).fib_atomy + (self - 1).fib_atomy; end

  def fib_atomy
    if self == 0
      fib_atomy_sub_1
    elsif self == 1
      fib_atomy_sub_2
    else
      fib_atomy_sub_3
    end
  end

  def fib_atomy_2
    if self == 0
      proc { 1 }.call(self)
    elsif self == 1
      proc { 1 }.call(self)
    else
      proc { (self - 2).fib_atomy_2 + (self - 1).fib_atomy_2 }.call(self)
    end
  end

  def fib_atomy_3
    a = proc { 1 }.block
    b = proc { 1 }.block
    c = proc { (self - 2).fib_atomy_3 + (self - 1).fib_atomy_3 }.block

    if self == 0
      a.call(self)
    elsif self == 1
      b.call(self)
    else
      c.call(self)
    end
  end

  def fib_atomy_4
    a = proc { 1 }.block
    b = proc { 1 }.block
    c = proc { (self - 2).fib_atomy_4 + (self - 1).fib_atomy_4 }.block

    if self == 0
      a.call_under(self, a.static_scope, self)
    elsif self == 1
      b.call_under(self, b.static_scope, self)
    else
      c.call_under(self, c.static_scope, self)
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

  x.report("20.fib_atomy_2") do
    20.fib_atomy_2
  end

  x.report("20.fib_atomy_3") do
    20.fib_atomy_3
  end

  x.report("20.fib_atomy_4") do
    20.fib_atomy_4
  end
end

def fib(n)
  if n == 0
    0
  elsif n == 1
    1
  else
    fib(n - 2) + fib(n - 1)
  end
end

20.times do
  a = Time.now
  p(fib(20))
  p(Time.now - a)
end

def strat_a_branch(a, b)
  a + b
end

def strat_a(x)
  strat_a_branch(*bindings(x))
end

def bindings(x)
  x = []
  x.concat(wild_bindings(x))
  x
end

def strat_b_branch(a, b)
  a + b
end

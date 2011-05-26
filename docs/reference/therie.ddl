\style{Atomy}

\title{Testing with Therie}


Therie is a small and simple behavioral-style testing suite that comes with \
Atomy. To use it, you should use the \hl{therie} namespace, which provides \
the following methods.

\atomy{
  use(therie)
}


\define{
  Stats
  > Class
}{
  A trivial container of \hl{passed} and \hl{failed} counts, with accessors \
  for both.
}

\section{Structure}{
\style{Atomy}

\evaluate{use(therie)}

\define{
  theorize(&tests)
  > Stats
}{
    Run \hl{tests} and keep track of how many passed and how many failed, \
    printing the stats at the end and returning them.
  
  \examples{
    theorize: describe("foo"): it("does x") \{ true should-be(false) \}, it("does x"): true should-be(true)
  }
}

\define{
  describe(what, &body)
}{
    Logically group together a set of behavior.

    Prints out \hl{what}, with each test in \hl{body} indented afterward.
  
  \examples{
    describe("foo"): it("does x") \{ true should-be(false) \}, it("does x"): true should-be(true)
  }
}

\define{
  it(description, &tests)
}{
    Describe some behavior that the tests in \hl{body} will demonstrate.
  
  \examples{
    it("adds correctly"): (2 + 2) should-be(4)
    it("adds correctly"): (1 + 2) should-be(4)
  }
}

}\section{Tests}{
\style{Atomy}

\evaluate{use(therie)}

\define{
  o should(&check)
}{
    Test that \hl{predicate} is satisified by \hl{o} by evaluating it with \
    \hl{o} as \hl{self}.
  
  \examples{
    (2 + 2) should: even?
    (2 + 2) should: odd?
  }
}

\define{
  x should-be(y)
}{
    Test for \hl{x == y}.
  
  \examples{
    (2 + 2) should-be(4)
    (1 + 2) should-be(4)
  }
}

\define{
  x should-raise(y)
  | x respond-to?(#call)
  | y is-a?(Class)
}{
    Test that executing \hl{x} will raise an exception of class \hl{y}.
  
  \examples{
    \{ abc \} should-raise(NoMethodError)
    \{ #ok \} should-raise(NoMethodError)
  }
}

\define{
  x should-error(y)
  | x respond-to?(#call)
  | y is-a?(Class)
}{
    Test that executing \hl{x} will signal an error of class \hl{y}.
  
  \examples{
    \{ error(#foo) \} should-error(SimpleError)
    \{ #ok \} should-error(SimpleError)
  }
}

}
\style{Atomy}

\title{Condition System}


  Rather than traditional exceptions, Atomy sports a condition/restart \
  system modeled on Common Lisp's design. The native Ruby exception handling \
  is available, but conditions and restarts are much more flexible.


\section{Conditions}{
\style{Atomy}

\define{
  Condition:
    Error(@backtrace):
      SimpleError(@value)
      ExceptionError(@exception)
      NoRestartError(@name)
      PortError(@port):
        EndOfFile
    Warning(@backtrace):
      SimpleWarning(@value)
}{
    Condition system hierarchy. You should subclass one of these to create \
    your own conditions.
  }

\define{
  Condition name
}{
    Get the name of a condition. By default, this will be the class name, \
    but you may override this for your own behaviour.
  }

\define{
  Condition message
}{
    A human-friendly message displayed for the condition. Override this.
  }

}\section{Handling}{
\style{Atomy}

\define{
  restart(name, *args)
  | name is-a?(Symbol)
  > any
}{
    Invoke the \hl{name} restart, passing \hl{args} along to its callback.

    See \hl{with-restarts}.
  
  \examples{
    \{ with-restarts(foo -> 42) \{ signal(#bar) \} \} bind: #bar -> restart(#foo)
  }
}

\define{
  body bind(&y)
  | y contents all? [x]: x match \{ `(~_ -> ~_) -> true, _ -> false \}
  > any
}{
    Register handlers for various signals for the duration of \hl{x}'s \
    execution.

    The body of \hl{y} is similar to \hl{match}; \hl{\italic{pattern} -> \
    \italic{body}}.

    The result is the result of \hl{body}.
  
  \examples{
    \{ signal(#a) \} bind: #a -> "got A!" print
    \{ signal(#b) \} bind: #a -> "got A!" print
    \{ \{ signal(#a) \} bind \{ #a -> "inner" print \} \} bind: #a -> "outer" print
  }
}

\define{
  with-restarts(*restarts, &block)
  > any
}{
    Register restarts available for the duration of \hl{body}'s execution.

    The \hl{restarts} should be in the form of \
    \hl{\italic{name}(*\italic{args}) -> \italic{body}}.

    The result is the result of \hl{body}.
  
  \examples{
    \{ with-restarts(x -> 1, y -> 2) \{ signal(#a) \} \} bind: #a -> restart(#x)
    \{ with-restarts(x -> 1, y -> 2) \{ signal(#a) \} \} bind: #a -> restart(#y)
    \{ with-restarts(x(a) -> (a * 7)) \{ signal(#a) \} \} bind: #a -> restart(#x, 6)
  }
}

}\section{Signalling}{
\style{Atomy}

\define{
  signal(c)
  > nil
}{
    Signal a value through all bound handlers, nearest-first, stopping when \
    a restart is invoked.
  
  \examples{
    signal(#foo)
    \{ signal(#foo) \} bind: #foo -> "got foo" print
  }
}

\define{
  error(x)
  > _
}{
    Like \hl{signal}, except that if no restart is invoked, the current \
    \hl{^debugger} is started.

    If the given value is not an \hl{Error}, it is wrapped in a \
    \hl{SimpleError}. If the value is a Ruby \hl{Exception}, it is wrapped \
    in an \hl{ExceptionError}.
  
  \examples{
    error("Oh no!")
    \{ error("Oh no!") \} bind: Error -> "INCOMING" print
  }
}

\define{
  warning(x)
  > nil
}{
    Like \hl{signal}, except that if no restart is invoked, the warning is \
    printed to \hl{^error-port}.

    If the given value is not a \hl{Warning}, it is wrapped in a \
    \hl{SimpleWarning}. Warning messages can be muffled by binding for \
    \hl{Warning} and invoking the \hl{#muffle-warning} restart.
  
  \examples{
    warning("Suspicious!")
    \{ warning("Quiet, you!") \} bind: Warning -> restart(#muffle-warning)
  }
}

}\section{Debuggers}{
\style{Atomy}

\define{
  DefaultDebugger
  > Class
}{
    The default debugger. This will show the condition name, its message, \
    and let the user pick from the available restarts.
  }

\define{
  ^debugger
  > DefaultDebugger
  | respond-to?(#run)
}{
    The current debugger. \hl{run} will be called with the condition as an \
    argument.
  }

}
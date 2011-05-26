\style{Atomy}

\title{Concurrency}

\define{
  me
  > Actor
}{
  Get the current actor.
}

\section{Sending & Receiving}{
\style{Atomy}

\define{
  Actor <- v
  > Actor
}{
    Send message \code{v} to the actor.
  
  \examples{
    a = spawn \{ receive \{ 42 -> #ok \} write \}
    a <- 42
  }
}

\define{
  receive(&body)
  | body contents all? [x]: x match: `(~_ -> ~_) -> true, _ -> false
  > any
}{
    Receive a message sent to the current actor that matches any of the \
    patterns listed in \hl{body}. Blocks until a matching message is \
    received. Non-matching messages are consumed and ignored.
  
  \examples{
    a = spawn \{ receive \{ 1 -> #got-1 \} write \}
    a <- 0
    a <- 2
    a <- 1
  }
}

\define{
  receive(&body) after(timeout)
  | body contents all? [x]: x match: `(~_ -> ~_) -> true, _ -> false
  | timeout match: `(~_ -> ~_) -> true, _ -> false
  > any
}{
    Similar to \code{receive}, but with a timeout and an action to \
    perform if it times out.
  
  \examples{
    receive \{ 1 -> #ok \} after(1 -> #too-slow)
  }
}

}\section{Spawning}{
\style{Atomy}

\define{
  spawn(&action)
  > Actor
}{
    Spawn a new actor, performing \code{action}.
  
  \examples{
    spawn: (2 + 2) write
  }
}

\define{
  spawn-link(&action)
  > Actor
}{
    Spawn a new actor, performing \code{action}, linked to the current \
    actor.
  
  \examples{
    spawn-link: (2 + 2) write
  }
}

}
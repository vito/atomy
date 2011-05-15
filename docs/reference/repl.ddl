\style{Atomy}

\title{The REPL}

\define{
  basic-repl(bnd = TOPLEVEL_BINDING)
  | bnd is-a?(Binding)
}{
  The basics of a REPL - reading, evaluating, and printing in a loop. More \
  flexibility is provided by various signals. See \hl{repl} for a fancier \
  REPL, which builds upon this, and \hl{ReplDebugger}.

  When showing the prompt, \hl{#prompt} is signaled with a \hl{#use-prompt} \
  restart available. Invoke this restart and pass along a string to \
  override the prompt, which defaults to \code{>>}.

  Input preceded by a colon (\code{:}) and followed by an alphanumeric \
  character is assumed to be a \italic{special command}. These are not \
  evaluated, and are signaled as \hl{#special(\italic{text})}.

  When the user sends \code{EOF} (Ctrl+D) or an interrupt (Ctrl+C), \
  \hl{#quit} is signaled.

  When the user enters code, \hl{#input(\italic{text})} is signaled. The code\
  is evaluated with two restarts registered: \code{#retry} for re-attempting \
  evaluation, and \code{#abort}, for canceling the evaluation. After the code\
  is evaluated, \hl{#evaluated(\italic{result})} is signaled.

  \hl{#loop} is signaled before the loop starts over again (i.e., after the \
  input is handled).
}

\define{
  ReplDebugger
  > Class
}{
  An interactive debugger REPL for handling errors. This will list the \
  results along with a number, allow the user to continue evaluating code, \
  and once they enter a \italic{special command} in the form of \
  \code{:\italic{number}}, the specified restart will be invoked.
}

\define{
  repl(history = nil, bnd = TOPLEVEL_BINDING)
  | history is-a?(String)
  | bnd is-a?(Binding)
}{
  A more feature-filled REPL, providing persistent history and setting \
  \hl{^debugger} to \hl{ReplDebugger}.

  History will be managed and appended to a file specified by \hl{history} \
  upon termination.
}


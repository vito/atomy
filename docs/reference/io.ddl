\style{Atomy}

\title{Input & Output}

\define{
  ^output-port
  > $stdout
}{Where to write normal output.}

\define{
  ^input-port
  > $stdin
}{Where to read input from.}

\define{
  ^error-port
  > $stderr
}{Where to write error/warning output.}

\section{Output}{
\style{Atomy}

\define{
  x print
  > x
}{
    Write \hl{x to-s} to \hl{^output-port}, followed by a linebreak.
  
  \examples{
    1 print
    "hello" print
  }
}

\define{
  x display
  > x
}{
    Write \hl{x to-s} to \hl{^output-port}.
  
  \examples{
    1 display
    "hello" display
  }
}

\define{
  x write
  > x
}{
    Write \hl{x show} to \hl{^output-port}.
  
  \examples{
    1 write
    "hello" write
  }
}

\define{
  with-output-to(filename \{ String \}, mode = "w", &action)
  | filename is-a?(String)
  | mode is-a?(String)
  > any
}{
    Set \hl{^output-port} to write output to \hl{filename} for the duration \
    of \hl{action}, ensuring that the file is closed.

    Returns the result of \hl{action}.
  
  \examples{
    with-output-to("foo"): 42 print
    with-output-to("foo", "a"): "hello" print
    File open("foo", &#read)
  }
}

\define{
  with-output-to(io, &action)
  > any
}{
    Set \hl{^output-port} to write to \hl{io} for the duration of \hl{action}.

    Returns the result of \hl{action}.
  
  \examples{
    require("stringio")
    x = StringIO new
    with-output-to(x): "hello!" write
    x string
  }
}

\define{
  with-error-to(filename \{ String \}, mode = "w", &action)
  | filename is-a?(String)
  | mode is-a?(String)
  > any
}{
    Set \hl{^error-port} to write error output to \hl{filename} for the \
    duration of \hl{action}, ensuring that the file is closed.

    Returns the result of \hl{action}.
  
  \examples{
    with-error-to("foo", "a"): warning(#some-warning)
    File open("foo", &#read)
  }
}

\define{
  with-error-to(io, &action)
  > any
}{
    Set \hl{^error-port} to write to \hl{io} for the duration of \hl{action}.

    Returns the result of \hl{action}.
  
  \examples{
    require("stringio")
    x = StringIO new
    with-error-to(x): warning(#foo)
    x string
  }
}

}\section{Input}{
\style{Atomy}

\define{
  read-line(sep = $separator)
  > String
}{
    Read a line of text from \hl{^input-port}, signalling \hl{EndOfFile} on \
    end of file. Lines are separated by \hl{sep}. A separator of \hl{nil} \
    reads the entire contents, and a zero-length separator reads the input \
    one paragraph at a time (separated by two linebreaks).
  
  \examples{
    with-input-from("foo"): read-line
  }
}

\define{
  read-lines(sep = $separator)
  > String
}{
    Read all lines of text from \hl{^input-port}. Lines are separated by \
    \hl{sep}. A separator of \hl{nil} reads the entire contents as one \
    segment, and a zero-length separator reads the input one paragraph at a \
    time (separated by two linebreaks).
  
  \examples{
    with-input-from("foo"): read-lines
  }
}

\define{
  read-byte
  > Integer
}{
    Read a single byte from \hl{^input-port}, signalling \hl{EndOfFile} on \
    end of file.
  
  \examples{
    with-input-from("foo"): read-byte
  }
}

\define{
  read-char
  > String
}{
    Same as \hl{read-byte chr}.
  
  \examples{
    with-input-from("foo"): read-char
  }
}

\define{
  read(length = nil, buffer = nil)
  | length nil? || (length >= 0)
  | buffer nil? || buffer is-a?(String)
  > (String || buffer) || nil
}{
    Read at most \hl{length} bytes from \hl{^input-port}, or to the end of \
    file if \hl{length} is \hl{nil}. If \hl{buffer} is given, the data read \
    will be written to it.
  
  \examples{
    x = ""
    with-input-from("foo"): read(10)
    with-input-from("foo"): read(10, x)
    x
  }
}

\define{
  with-input-from(filename \{ String \}, mode = "r", &action)
  | filename is-a?(String)
  | mode is-a?(String)
  > any
}{
    Set \hl{^input-port} to read input from \hl{filename} for the duration \
    of \hl{action}, ensuring that the file is closed.

    Returns the result of \hl{action}.
  
  \examples{
    with-input-from("foo"): read-line
  }
}

\define{
  with-input-from(io, &action)
  > any
}{
    Set \hl{^input-port} to write to \hl{io} for the duration of \hl{action}.

    Returns the result of \hl{action}.
  
  \examples{
    require("stringio")
    x = StringIO new("hello\\ngoodbye\\n")
    with-input-from(x): read-line
  }
}

}
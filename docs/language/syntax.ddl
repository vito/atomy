\style{Atomy}

\title{Syntax}{syntax}

\section{General Rules}{
  Atomy is whitespace-sensitive. Operators must be surrounded by whitespace, \
  and indentation provides hints to the parser when you don't want to use    \
  commas. For example, \hl{foo-bar} is an identifier, while \hl{foo - bar} is\
  subtraction.

  Requiring whitespace around operators enables the use of more symbols in   \
  identifier names, allowing pleasant conventions like question-marks (e.g.  \
  \hl{empty?}) and exclamation points (e.g. \hl{do-something-destructive!})  \
  for indicating the behaviour of a method or variable.

  Atomy's whitespace indentation rules are similar to Haskell's - they are   \
  not as strict as Python's, you just increase the spacing amount to indicate\
  continuing the previous line, and continue that indentation amount to      \
  indicate continuing the current "block" of code.

  Using significant whitespace, this code:

  \atomy{
    \{ "hi" print
      goodbye
      2 + 2
    \} call
  }

  is equivalent to:

  \atomy{
    \{ "hi" print, goodbye, 2 + 2 \} call
  }

  With these simple line-continuing rules in place, you can spread a single  \
  chain of messages across multiple lines:

  \atomy{
    something
      foo
      sqrt
  }

  Which is parsed as:

  \atomy{something foo sqrt}

  The same rules apply to operators, which will skip any whitespace to get to\
  the right-hand side of the expression.

  \atomy{
    foo =
      1 +
        2 *
          3
  }

  Which is parsed as:

  \atomy{foo = 1 + 2 * 3}

  Two spaces for indentation is recommended.
}

\section{Comments}{
  Atomy borrows its comment syntax from Haskell: \code{--} for line comments,\
  and \code{\{- -\}} for block comments (which can be nested).

  \atomy{
    1 -- The number, "one."
    (\{- Blah blah blah, \{- yo dawg -\}, fizz buzz! -\} "foo") print
  }
}

\section{Literals}{literals-syntax}{
  \definitions{
    \item{integers}{
      \hl{1}, \hl{-1}, \hl{0xdeadbeef}, \hl{0o644}, \hl{-0x10}, \hl{-0o10} ...
    }

    \item{doubles}{
      \hl{1.0}, \hl{-1.5}, \hl{1.5e10}, \hl{1.4e-3}, \hl{-1.4e4}...
    }

    \item{strings}{
      \hl{""}, \hl{"foo"}, \hl{"fizz \\"buzz\\""}

      Escape codes supported (in addition to numeric escapes):

      \verbatim{
        ascii-2:
          \\b \\t \\n \\v \\f \\r \\SO \\SI \\EM \\FS \\GS \\RS \\US ␣ (space)
          \\BS \\HT \\LF \\VT \\FF \\CR \\SO \\SI \\EM \\BS \\GS \\RS \\US \\SP

        ascii-3:
          \\NUL \\SOH \\STX \\ETX \\EOT \\ENQ \\ACK \\a \\DLE \\DC1 \\DC2
          \\DC3 \\DC4 \\NAK \\SYN \\ETB \\CAN \\SUB \\ESC \\DEL
      }

      When a string is used as a message, you get a "macro-quote." The       \
      receiver should be a variable, which names the macro-quoter. Arguments \
      used in the send should be variables, whose names will be used as flags.

      \example{
        r"foo"
        r"\\p\{Hiragana\}"(u)
      }
    }

    \item{pseudo variables}{\hl{self}, \hl{nil}, \hl{true}, and \hl{false}}

    \item{arrays}{\hl{[]}, \hl{[1]}, \hl{[1, 2]}, \hl{[1, #two, "three"]}, ...}

    \item{expressions}{
      \definitions{
        \item{quoted}{
          An apostrophe (\code{'}) before an expression "quotes" it, turning \
          it into an expression literal:

          \example-segment{
            '1
            'a
            '(1 + 1)
            ''(1 + b)
            '\{ a = 1, a + 1 \}
          }
        }

        \item{quasiquoted}{
          Atomy supports quasiquotation as seen in most Lisps, most similarly\
          Clojure. A backquote (\code{`}) begins a quasiquote, inside of     \
          which you can use tilde (\code{~}) to "unquote."

          These can be nested infinitely; unquoting works inside of aggregate\
          expressions such as lists, blocks, and definitions.

          \example{
            `1
            `(1 + ~(2 + 2))
            ``(1 + ~~(2 + 2))
            `\{ a = ~(2 + 2) \}
            `[1, 2, ~(1 + 2)]
          }

          Note that unquoting too far signals an \hl{@out-of-quote:} error.

          \example{
            `~~(2 + 2)
          }
        }
      }
    }

    \item{blocks}{
      Blocks come in two forms. One is a simple comma-delimited list of      \
      expressions wrapped in curly braces (\code{\{ \}}), and another form   \
      begins with a colon (\code{:}) and optionally ends with a semicolon    \
      (\code{;}).

      Block parsing is whitespace-aware; see {- \reference{General Rules}. -}
    }
  }
}

\section{Dispatch}{dispatch-syntax}{
  Atomy's dispatch is considerably simple: one expression followed by \
  another, optionally including arguments.

  Most of the time, you'll be using a variable as the method name:

  \example-segment{
    1 foo
    \{ 1 sqrt \} call
  }

  However, you can actually use anything there, as long as it knows how to be used as a message. This is done by defining \hl{as-message(send)} for the node, where \hl{send} the \hl{Send} it's being used in. This method should return a \hl{Send} node.

  There are currently three other things you can use as a message: a \hl{List}, a \hl{Block}, and a \hl{UnarySend} of \code{$}. But feel free to define your own.

  When a \hl{List} is used as a message, it sends \code{[]} with its contents\
  as the arguments, as in Ruby. Note that this will also give you \code{[]=} \
  for free.

  \example{
    a = [1, 2, 3]
    a [1]
    a [1] = 4
    a
  }

  When a \hl{Block} is used as a message, it attaches itself as a Ruby-style \
  proc-arg. When a \hl{List} and a \hl{Block} are used in combination, the \
  \hl{List} instead acts as the block's arguments.

  \example{
    2 times: "hi" print
    [1, 2, 3] collect [x]: x * 2
  }

  You can also include arguments with the message by following the expression\
  with parentheses and listing them separated by commas (as in most other \
  languages).

  \example-segment{
    1 foo(2, 3)
    [a] \{ a + 1 \} call(2)
  }

  A \hl{UnarySend} of \code{$} sent to a \hl{Block} can be used as syntactic sugar for avoiding parentheses around argument lists; when used as a message, it simply appends the block's contents to the send's arguments.

  \example-segment{
    1 foo $: 2, 3
  }

  If there is no "target" for the message, it is a private message sent to \
  \hl{self}.
}

\section{\hl{macro}}{macro-syntax}{
  The \hl{macro} keyword is used to define macros; the format is as follows:

  {- See \reference{defining-macros}. -}

  \verbatim{
    macro(pattern): [expressions ...]
      where
        pattern = a message pattern
        expressions = the macro's body
  }
}

\section{\hl{operator}}{operator-syntax}{
  You can control how Atomy parses binary operators like \hl{+} and \hl{->} via the \hl{operator} keyword. The syntax is as follows:

  \verbatim{
    operator [associativity] [precedence] operators
      where
        associativity = "right" | "left"
        precedence = integer
        operators = operator +
  }

  An omitted associativity implies left, and an omitted precedence implies 5 (the default). One of the two must be provided.

  \example-segment{
    operator right 0 ->
    operator right 8 ^
    operator 7 % * /
    operator 6 + -
  }

  Operator expressions, when evaluated, just return \hl{@ok}.
}

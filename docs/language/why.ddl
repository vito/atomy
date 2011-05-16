\style{Atomy}

\title{What & Why}

\section{Philosophy}{
  Atomy is a language designed to grow. It achieves this goal by having a very simple grammar, much like Lisp. Rather than statements, everyting in Atomy is an expression. These expressions are not merely written, they are \italic{designed}. Readability, concision, and flow are the primary goal, and this goal is most easily achieved by keeping the grammar small, and building everything up from there with macros and metaprogramming.

  Time after time new languages are introduced, which are often snapshots of what we needed when it was designed. These languages have so many features built-in as syntax that countless libraries and applications hinge on version numbers solely to get past the parsing stage. Ruby and Python are examples of these.

  Atomy instead hopes to introduce these features as libraries. The grammar in 1.0 should either be "the end" of its progression, or later generalized in a way that is backward-compatble.
}

\section{Idioms & Freebies}{
  \section{Platform}{
    Atomy's platform of choice is the Rubinius VM. Its syntax already scales upward to encompass every common Ruby construct (with its own flavor), and Ruby libraries can be used transparently, as long as they run on Rubinius.
  }

  \section{It's Algebraic!}{
    An integral part of Atomy's core is pattern-matching dispatch. This gives you immense expressive power, with a form of multiple dispatch. Atomy's style favors declaring your data structures first and defining methods in a functional style in terms of all of their "roles" (the receiver and the message's arguments).

    To show this, I'll go through part of the the \hl{Doc} system, used for pretty-printing, which exemplifies this beautifully.

    Here we define each type of \hl{Doc} there is, structurally. This creates classes and subclasses recursively, as well as constructors and accessors for the data they specify:

    \atomy{
      data(Doc):
        Empty
        Beside(@left, @right, @space?)
        Above(@above, @below, @overlap?)
        Text(@value)
    }

    One thing we'll want to do with a document is compute its width. This is trivial; just a single message sent to the \hl{Doc} with no arguments. Note that we're defining each method alongside one another; not inside of a class body. This allows us to group related methods by meaning, not by their receiver. This better shows the relationships between each method:

    \atomy{
      Empty width := 0
      Text width := @value size
      Beside width :=
        if(@space?)
          then: 1 + @left width + @right width
          else: @left width + @right width
      Above width := [@above width, @below width] max
    }

    A great example of pattern-matching and multiple dispatch comes into play when composing two documents with the \code{<+>} operator. This positions two \hl{Doc}s beside each other, separated by a space, unless either are \hl{Empty}:

    \atomy{
      (l: Doc) <+> (r: Doc) := Beside new(l, r, true)
      (d: Doc) <+> Empty := d
      Empty    <+> (d: Doc) := d
      (l: Doc) <+> (a: Above) := do:
        first = l <+> a above
        rest = a below nest(l width + 1)
        Above new(first, rest, a overlap?)
    }

    This is opposed to Ruby-style, where you open classes to add methods to them, and then handle the arguments from within the single method definition, often with the \code{case} statement. This form is also supported, but it is much more verbose.
  }

  \section{Go ahead, be a monkey.}{
    Atomy also attempts to solve the monkey-patching problem via selector namespaces. This is still in flux, but is a high priority.
  }

  \section{A Handful of Shiny Toys}{
    \definitions{
      \item{macro-quotes}{
        Generalized string quotation. Examples include regular expressions, raw strings, and word-lists. It's easy to create new quoters for things other languages would have as literals.

        \example{
          r"[a-z][\\p\{L\}]*"(u)
          raw"s\\up?"
          w"foo bar baz"
        }
      }

      \item{explicit mutation}{
        Atomy has two "assignment"-ish operators; \hl{=} and \hl{=!}. The former will always pattern-match and introduce locals to the current immediate scope. The latter will also pattern-match, but it will only \italic{mutate} existing locals, never introducing them.

        This keeps your locals local and makes it clear when you really want to mutate something in-place.

        \example{
          a = 0
          do: a = 1, a
          a
          do: a =! 1, a
          a
        }
      }

      \item{syntax as macros}{
        Where Ruby has global, instance, and class variable syntax, Atomy actually implements these as unary send macros. Same for symbols (\hl{#to-a}), particles (\hl{#foo(1, _)}, splats (\hl{*args}), block-passing (\hl{&foo}). If something can be a macro or regular method, it will be. This has been applied very broadly.

        There are currently four "types" of macros: variable, unary, binary, and regular message sends. Variable macros are used for things like \hl{_FILE} and \hl{_LINE}.
      }

      \item{extensible pattern-matching}{
        If you don't mind digging down into Rubinius bytecode, you can define your own pattern-matchers. It's very easy to do, and there is a very broad spectrum of pattern-matchers built-in because of this. See \reference{pattern-matching}.
      }

      \item{semantic in-code documentation}{
        Rather than scanning code for comments, Atomy implements in-code documentation semantically via macros.

        \example-segment{
          doc"
            A description of what \\hl\{times\} does.
          " spec \{
            a is-a?(Integer)
            b is-a?(String)
            => String
          \} for \{
            a times(b: String) := b * a
          \} examples:
            10 times("foo")
        }

        When this code is run with the \code{-d} flag passed, it will generate a Doodle file for the script's documentation.
      }
    }
  }
}

\section{Influences & Thanks}{
  \definitions{
    \item{Common Lisp & Clojure}{
      extensive macro system, gensyms (via \hl{names}), powerful string formatting system, conditions & restarts, thread-local dynamic environment (via \hl{dynamic}), controlled evaluation (via \hl{evaluate-when} and \hl{for-macro}), \hl{let-macro}, dynamic variable -based \reference{Input & Output}, Clojure-style namespaces
    }

    \item{Haskell}{
      pattern-matching, algebraic data definition (via \hl{data}), functional-style method defining, pretty-printing system, parens slaying with \hl{$}, list comprehension macros
    }

    \item{Ruby}{
      functionality baseline, with desired improvements (selector namespacing, safer alternatives to \code{instance_eval} for DSLs, like \hl{onto})
    }

    \item{Slate & Atomo}{
      multiple dispatch (via pattern-matching, like Atomo; Slate doesn't work that way), particles, pseudo-keyword-messages via macros and pattern-matching
    }

    \item{Potion & Poison}{
      colon block syntax + commas
    }

    \item{Erlang}{
      message-sending concurrency
    }
  }
}
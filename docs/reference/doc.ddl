\style{Atomy}

\title{Pretty-Printing}

\section{Documents}{
\style{Atomy}


    A document is a structural collection of text. The following are the \
    various types of documents, usually created with various combinators \
    provided below.
  

\define{
Empty
  > Class
}{
    The empty document, with a height and width of \hl{0}.
  }

\define{
Beside(@left, @right, @space?)
  > Class
}{
    A document comprised of two documents positioned beside each other, with \
    an optional space in-between.
  }

\define{
Above(@above, @below, @overlap?)
  > Class
}{
    A document comprised of two documents positioned above and below each \
    other, optionally overlapping if possible.
  }

\define{
Nest(@body, @depth)
  > Class
}{
    A document indented to a given depth.
  }

\define{
Text(@value)
  > Class
}{
    A document containing arbitrary text, with a height of \hl{1}.
  }

\define{
Doc empty?
  > Boolean
}{
    Trivial emptiness check. \hl{true} for \hl{Empty}, \hl{false} for \
    everything else.
  
  \examples{
    doc \{ empty \} empty?
    doc \{ text("abc") \} empty?
    doc \{ text("") \} empty?
  }
}

\define{
Doc width
  > Integer
}{
    Calculate the width of the document, in characters.
  
  \examples{
    doc \{ empty \} width
    doc \{ text("abc") \} width
  }
}

\define{
Doc height
  > Integer
}{
    Calculate the height of the document, in lines.

    Note that an empty document has a height of 0.
  
  \examples{
    doc \{ empty \} height
    doc \{ text("abc") \} height
  }
}

\define{
Doc render
  > String
}{
    Render the document as a \hl{String}.
  
  \examples{
    doc \{ empty \} render
    doc \{ text("abc") \} render
    '(1 + 1) pretty render
  }
}

}\section{Constructing}{
\style{Atomy}

\define{
(left: Doc) <+> (right: Doc)
  > Doc
}{
    Position one document beside another, separated by a space, unless either\
    side is empty.
  
  \examples{
    doc \{ text("x") <+> value(42) \}
    doc \{ empty <+> value(42) \}
  }
}

\define{
(left: Doc) <> (right: Doc)
  > Doc
}{
    Position one document beside another unless either side is empty.
  
  \examples{
    doc \{ text("x") <> value(42) \}
    doc \{ empty <> value(42) \}
  }
}

\define{
(above: Doc) // (below: Doc)
  > Doc
}{
    Position one document above another, unless either are empty.

    If the last line of the first argument stops at least one position before\
    the first line of the second begins, these two lines are overlapped.
  
  \examples{
    doc \{ text("hi") // text("there") nest(1) \}
    doc \{ text("hi") // text("there") nest(5) \}
  }
}

\define{
(above: Doc) /+/ (below: Doc)
  > Doc
}{
    Position one document above another, without overlapping, unless either \
    are empty.
  
  \examples{
    doc \{ text("hi") /+/ text("there") nest(1) \}
    doc \{ text("hi") /+/ text("there") nest(5) \}
  }
}

\define{
Doc nest(depth)
  | depth is-a?(Integer)
  > Doc
}{
    Indent the document to the given \hl{depth}. For \hl{Nest}, this just \
    increases its indentation level.
  
  \examples{
    doc \{ text("hi") nest(5) \}
    doc \{ text("hi") nest(5) nest(6) \}
  }
}

\define{
(delimiter: Doc) punctuate(documents: List)
  | documents all?(&#is-a?(Doc))
  > List
}{
    Intersperse \hl{delimiter} document through \hl{documents}.
  
  \examples{
    doc \{ semi punctuate([value(1), value(2), value(3)]) \}
    doc \{ hsep(semi punctuate([value(1), value(2), value(3)])) \}
  }
}

}\section{Helpers}{
\style{Atomy}

\define{
doc(&body)
}{
    Shortcut for \hl{Doc onto(&body)}. This provides the various helper \
    methods below, which are also available in the \hl{Pretty} module.
  }

\section{Shortcuts}{
\style{Atomy}


        These shortcuts are primarily for quickly creating \hl{Text} \
        documents, especially for things commonly found in syntax.
      

\define{
text(s)
  | s is-a?(String)
  > Doc
}{
        Create a \hl{Text} document with the given contents.
      }

\define{
value(x)
  > Doc
}{
        Create a \hl{Text} document with \hl{x inspect}.
      }

\define{
semi
  > Doc
}{
        Shortcut for \hl{text(";")}.
      }

\define{
comma
  > Doc
}{
        Shortcut for \hl{text(",")}.
      }

\define{
colon
  > Doc
}{
        Shortcut for \hl{text(":")}.
      }

\define{
space
  > Doc
}{
        Shortcut for \hl{text(" ")}.
      }

\define{
equals
  > Doc
}{
        Shortcut for \hl{text("=")}.
      }

\define{
lparen
  > Doc
}{
        Shortcut for \hl{text("(")}.
      }

\define{
rparen
  > Doc
}{
        Shortcut for \hl{text(")")}.
      }

\define{
lbrack
  > Doc
}{
        Shortcut for \hl{text("[")}.
      }

\define{
rbrack
  > Doc
}{
        Shortcut for \hl{text("]")}.
      }

\define{
lbrace
  > Doc
}{
        Shortcut for \hl{text("\{")}.
      }

\define{
rbrace
  > Doc
}{
        Shortcut for \hl{text("\}")}.
      }

}\section{Wrapping}{
\style{Atomy}


        More shortcuts for common cases in pretty-printing, dealing with \
        wrapping a document in delimiters.
      

\define{
parens(d)
  > Doc
}{
        Wrap a document in parentheses.
      }

\define{
brackets(d: Doc)
  > Doc
}{
        Wrap a document in brackets (\code{[]}).
      }

\define{
braces(d: Doc)
  > Doc
}{
        Wrap a document in braces (\code{\{\}}).
      }

\define{
quotes(d: Doc)
  > Doc
}{
        Wrap a document in single-quotes.
      }

\define{
double-quotes(d: Doc)
  > Doc
}{
        Wrap a document in double-quotes.
      }

}\section{Combining}{
\style{Atomy}


        Helpers for creating a single document from many.
      

\define{
empty
  > Doc
}{
        An empty document. The identity for \hl{<>}, \hl{<+>}, \hl{//}, \
        \hl{/+/}, and anywhere in the following methods.
      }

\define{
hcat(ds)
  | ds all?(&#is-a?(Doc))
  > Doc
}{
        Reduce a list of documents with \hl{<>}.
      }

\define{
hsep(ds)
  | ds all?(&#is-a?(Doc))
  > Doc
}{
        Reduce a list of documents with \hl{<+>}.
      }

\define{
vcat(ds)
  | ds all?(&#is-a?(Doc))
  > Doc
}{
        Reduce a list of documents with \hl{//}.
      }

}}
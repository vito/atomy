# Atomy

A DSL-oriented programming language targeting the Rubinius VM.

IRC: [#atomo on freenode](irc://chat.freenode.net/atomy)

Atomy provides the foundation for a language that grows with its users.

Many languages end up being snapshots of their initial design goals. The
designers bake features right into the language's core, rather than
implementing them as libraries. Eventually, this language may start to feel
stale, and either mediocre or backwards-incompatible changes are introduced to
breathe new life into it. This often occurs at the syntax level.

Not only does this lead to long transition periods, but it fragments the
language and your projects. The move towards a backwards-incompatible version
can be painfully slow. Hell, Ubuntu 12.04 still ships with Ruby 1.8, years
after 1.9 came around.

Atomy avoids this by saying very little about language semantics at its core,
instead providing a system that you can use to build the language you want.
The core components are detailed below.


## Simple Grammar

Reaching Atomy's goals requires a stable, deceptively simple grammar. It says
nothing about language semantics, instead defining primitive "building blocks"
which, when composed together, form the notation of the language.

The various forms are as follows:

* `Word`: `a`, `foo-bar`
* `Constant`: `Foo`, `FooBar123`
* `Primitive`: `1`, `200`
* `Literal`: `2.0`, `"foo"`
* `List`: `[1, 2, 3]`
* `Block`: `{ a, b }`, `: a, b`. The second notation is whitespace-aware.
* `Infix`: `1 + 1`
* `Postfix`: `no!`
* `Prefix`: `@foo`
* `Call`: `foo(bar, baz)`
* `Compose`: `1 inspect`
* `Quote`: `'foo`
* `QuasiQuote`: <code>\`foo</code>
* `Unquote`: `~foo`

Note that these say nothing about variables, messages, methods, or functions.
Blocks also don't have arguments; the notation for this is actually built up
by composing simpler forms together:

    [a, b]: a + b

This parses as a `List` composed with a `Block`. The AST looks like this:

    Compose
      List
        Word (a)
        Word (b)
      Block
        Infix
          Word (a)
          Word (b)

On its own, this means nothing. If you try to compile this, you'll get an
error - things like `Compose` and `Call` have no meaning on their own. This is
where macros come in.


### Macros!

If Atomy's AST is a bunch of Lego bricks pieced together, the macro system is
the imagination that gives it meaning.

Macros are defined using patterns that match arbitrary expressions. This is in
contrast to most macro systems, which either use named macros (i.e. Lisps) or
raw text substitution (C). Atomy's macros are nameless, and match on the AST
itself, rather than source code.

For example, when a `List` is composed with a `Block`, we get a `Block` with
arguments:

    macro([~*args]: ~*body):
      Block new(node line, body, args)

Here we're using splice unquotes (`~*foo`) to match the contents of the list
and block, and creating a new block with the original's contents and the given
arguments. This macro is defined in the "core" Atomy library.

Note that we're creating the `Block` manually; macros can return any object as
long as it knows how to compile itself. After expansion, nodes are sent
`bytecode(g, mod)`, where `g` is the code-generator and `mod` is the module
being compiled. Users are free to define arbitrary nodes that do whatever they
need to at the bytecode level. This is how things like if-then-else are
implemented without being a primitive:

    my-if-then-else = class:
      def(initialize(@if, @then, @else)) {}

      def(bytecode(gen, mod)):
        else = gen new-label
        done = gen new-label

        mod compile(gen, @if)
        gen gif(else)

        mod compile(gen, @then)
        gen goto(done)

        else set!
        mod compile(gen, @else)

        done set!

    macro(my-if(~x) then: ~*y; else: ~*z):
      my-if-then-else new(x, `(do: ~*y), `(do: ~*z))

    my-if(true)
      then: puts("1")
      else: puts("0")

For more information on the Rubinius VM bytecode, see the [instruction
set](http://rubini.us/doc/en/virtual-machine/instructions/).

Normally though you probably won't be digging into bytecode to write macros.
For most cases you'll probably just use Lisp-style quasiquotation:

    macro(~x for(~*args) in(~c) when(~t)):
      names [tmp]:
        `(do:
            ~tmp = []
            ~c collect [~*args]:
              when(~t):
                ~tmp << ~x

            ~tmp)

    (v * 3) for(v) in(0 .. 10) when(v even?)

Here we're implementing Python-style list comprehensions. We use `names` to
generate temporary variable names to avoid collision.


## Closures Everywhere

Everything in Atomy is a closure. This differs from Ruby, where methods and
class/module bodies do not capture local variables.

There are many places this comes in useful, but in terms of other Atomy
features, it's good for assigning modules to variables at the top of a file,
and defining helper functions for use in your exposed methods (see the
following section for more info there).


## Code Isolation

### Files are Modules

Vaguely similar to CommonJS-style modules, `require` will result in a module
object, rather than evaluating the file in some global scope.

Methods defined at the toplevel are defined on the file's module, and can be
called by anyone `require`ing the file.

Macros defined in a file are local to its module. For another module to use
them, they must call `use` rather than `require`. `use` will also bring the
module's methods into the user.

For example, if we have a file `a.ay`:

    use("atomy")
    macro(bar): 42
    def(foo(a)): a + bar

We can do this to invoke the `foo` method:

    require("a") foo(2) -- => 44

Or we can `use` it to bring in its macros and methods:

    use("a")
    bar    -- => 42
    foo(2) -- => 44


### Methods and Functions

Methods are always public, and should be used only for things you want exposed
as your API.

Functions replace private/helper methods. They are simply locals bound to
a block that gets called with `self` as the `self` of its caller. They can do
everything a method can, except they are not bound to a class or a module. To
define a function, use `fn(x): ...` instead of `def(x): ...`.

This may seem a little odd coming from Ruby, but in practice it simplifies
your decision process when writing code. When defining something, it comes
down to one question: should this be part of my public API? If not, define it
as a function. It doesn't matter where you put it, as long as it's in scope,
and there's no concern of others using it in production.

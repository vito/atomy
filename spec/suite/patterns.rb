def match(pat, val)
  Atomy::Compiler.eval(
    Atomy::AST::Set.new(
      0,
      Atomy::AST::Pattern.new(
        0,
        pat
      ),
      Atomy::AST::Literal.new(0, val)
    ),
    Binding.setup(
      Rubinius::VariableScope.of_sender,
      Rubinius::CompiledMethod.of_sender,
      Rubinius::StaticScope.of_sender
    )
  )
end

def expr(str)
  Atomy::Parser.parse_node(str)
end

def pat(str)
  expr(str).to_pattern
end

module Atomy::Patterns
  describe(Pattern) do
    describe(:local_names) do
      it("is a set of local names provided by the pattern") do
        pat = Named.new(Any.new, :foo)
        pat.local_names.must_equal Set[:foo]

        pat = Named.new(Named.new(Any.new, :bar), :foo)
        pat.local_names.must_equal Set[:foo, :bar]

        pat = List.new([
          Named.new(Any.new, :foo),
          Named.new(Any.new, :bar),
          Named.new(Any.new, :foo),
          List.new([Named.new(Any.new, :bar), Named.new(Any.new, :baz)])
        ])

        pat.local_names.must_equal Set[:foo, :bar, :baz]
      end

      it("does not include instance/global/class variables") do
        NamedInstance.new(:foo).local_names.must_be_empty
        NamedGlobal.new(:foo).local_names.must_be_empty
        NamedClass.new(:foo).local_names.must_be_empty
      end
    end

    describe(Any) do
      it("is a wildcard") do
        assert Any.new.wildcard?
      end

      it("does not perform binding") do
        refute Any.new.binds?
      end

      it("matches anything") do
        Any.new.must_be :===, Object.new
      end

      it("targets Object for definition") do
        Any.new.definition_target.must_equal Object
      end
    end

    describe(Attribute) do
      it("is a wildcard") do
        assert Attribute.new(nil, nil, nil).wildcard?
      end

      it("performs binding") do
        assert Attribute.new(nil, nil, nil).binds?
      end

      it("matches anything") do
        Attribute.new(nil, nil, nil).must_be :===, Object.new
      end

      it("has no definition target") do
        Attribute.new(nil, nil, nil).definition_target.must_equal Object
      end
    end

    describe(BlockPass) do
      it("is a wildcard iff its pattern is a wildcard") do
        assert BlockPass.new(Any.new).wildcard?
        refute BlockPass.new(Match.new(1)).wildcard?
      end

      it("performs binding iff its pattern performs binding") do
        refute BlockPass.new(Any.new).binds?
        assert BlockPass.new(Named.new(Any.new, :foo)).binds?
      end

      it("matches anything") do
        BlockPass.new(Any.new).must_be :===, Object.new
      end

      it("assigns as nil if the block is nil") do
        blk = :unassigned
        match(BlockPass.new(Named.new(Any.new, :blk)), nil)
        blk.must_be_nil
      end

      it("assigns non-nil values by converting them to a Proc") do
        blk = :unassigned
        x = proc {}
        match(BlockPass.new(Named.new(Any.new, :blk)), x)
        assert_equal blk, x

        match(BlockPass.new(Named.new(Any.new, :blk)), proc {}.block)
        assert_kind_of Proc, blk

        match(BlockPass.new(Named.new(Any.new, :blk)), :foo)
        assert_kind_of Proc, blk

        proc {
          match(BlockPass.new(Named.new(Any.new, :blk)), Object.new)
        }.must_raise ArgumentError
      end

      it("targets Object for definition") do
        BlockPass.new(Any.new).definition_target.must_equal Object
      end
    end

    describe(Constant) do
      it("is not a wildcard") do
        refute pat("Array").wildcard?
      end

      it("does not perform binding") do
        refute pat("Array").binds?
      end

      it("matches anything that is kind_of? the constant's value") do
        pat("Array").must_be :===, []
        pat("Array").wont_be :===, 1
        pat("Object").must_be :===, 1
      end

      it("targets the constant's value for definition") do
        pat("Array").definition_target.must_equal Array
        pat("::String").definition_target.must_equal ::String
        pat("Atomy::Patterns").definition_target.must_equal Atomy::Patterns
      end
    end

    describe(Default) do
      it("is a wildcard iff its pattern is a wildcard") do
        assert Default.new(Any.new, 42).wildcard?
        refute Default.new(Match.new(1), 42).wildcard?
      end

      it("performs binding iff its pattern performs binding") do
        refute Default.new(Any.new, 42).binds?
        assert Default.new(Named.new(Any.new, :foo), 42).binds?
      end

      it("matches anything its pattern matches") do
        Default.new(Any.new, 42).must_be :===, Object.new
        Default.new(Match.new(1), 42).must_be :===, 1
        Default.new(Match.new(1), 42).wont_be :===, 2
      end

      it("targets its pattern's target for definition") do
        Default.new(Any.new, nil).definition_target.must_equal Object
        Default.new(List.new([]), nil).definition_target.must_equal Array
      end
    end

    describe(HeadTail) do
      it("is not a wildcard") do
        refute pat("_ . _").wildcard?
      end

      it("performs binding iff either pattern performs binding") do
        refute pat("_ . _").binds?
        assert pat("x . _").binds?
        assert pat("_ . y").binds?
        assert pat("x . y").binds?
      end

      it("fails for zero-length arrays") do
        pat("_ . _").wont_be :===, []
      end

      it("matches the first elemnent as the head, and the rest as the tail") do
        pat("_ . _").must_be :===, [1]
        pat("1 . _").must_be :===, [1]
        pat("_ . []").must_be :===, [1]
        pat("1 . []").must_be :===, [1]

        pat("1 . (2 . [3])").must_be :===, [1, 2, 3]
        pat("1 . [2, 3]").must_be :===, [1, 2, 3]
      end

      it("targets Array for definition") do
        HeadTail.new(Any.new, Any.new).definition_target.must_equal Array
      end
    end

    describe(List) do
      it("is not a wildcard") do
        refute pat("[]").wildcard?
      end

      it("performs binding iff any of its patterns perform binding") do
        refute pat("[]").wildcard?
        refute pat("[_]").wildcard?
        refute pat("[a]").wildcard?
      end

      it("matches arrays of fixed length") do
        pat("[]").must_be :===, []
        pat("[]").must_be :===, []
        pat("[]").wont_be :===, [1]
        pat("[1]").must_be :===, [1]
      end

      it("allows interspersed splats") do
        pat("[1, *[2], 2]").must_be :===, [1, 2]
        pat("[1, *[2, 3], 2]").wont_be :===, [1, 2, 3]
        pat("[1, *[2, 3], 2, 3]").must_be :===, [1, 2, 3]
        pat("[1, *[2, 3], 2, *[3], 3]").must_be :===, [1, 2, 3]
      end

      it("matches arrays longer than required if finished with a splat") do
        pat("[*_]").must_be :===, []
        pat("[*[]]").must_be :===, []
        pat("[*_]").must_be :===, [1]
        pat("[*[1]]").must_be :===, [1]
        pat("[*_]").must_be :===, [1, 2]
        pat("[*[1, 2]]").must_be :===, [1, 2]
        pat("[1, *_]").must_be :===, [1, 2, 3]
        pat("[1, *[2, 3]]").must_be :===, [1, 2, 3]
      end

      it("targets Array for definition") do
        List.new([]).definition_target.must_equal Array
      end
    end

    describe(Literal) do
      it("is not a wildcard") do
        refute Literal.new(1).wildcard?
      end

      it("does not perform binding") do
        refute Literal.new(1).binds?
      end

      it("matches anything that is == to its value") do
        Literal.new(1).must_be :===, 1
        Literal.new(1).wont_be :===, 2
      end

      it("can match arbitrary objects") do
        x = Object.new
        Literal.new(x).must_be :===, x
        Literal.new(x).wont_be :===, Object.new
      end

      it("targets its value's class for definition") do
        [1, true, false, nil, "foo", :bar, Object.new, Class].each do |x|
          Literal.new(x).definition_target.must_equal x.class
        end
      end
    end

    describe(Match) do
      it("is not a wildcard") do
        refute Match.new(1).wildcard?
      end

      it("does not perform binding") do
        refute Match.new(1).binds?
      end

      it("matches anything that is == to its value") do
        Match.new(1).must_be :===, 1
        Match.new(1).wont_be :===, 2
      end

      it("targets Fixnum and Bignum for Integers") do
        Match.new(1).definition_target.must_equal Fixnum
        Match.new(10 ** 100).definition_target.must_equal Bignum
      end

      it("targets the appropriate class for :true, :false, and :nil") do
        Match.new(:true).definition_target.must_equal TrueClass
        Match.new(:false).definition_target.must_equal FalseClass
        Match.new(:nil).definition_target.must_equal NilClass
      end

      it("targets the static scope's definition target for :self") do
        # this test is a quirk of definition_target atm
        x = Match.new(:self)
        x.definition_target.must_equal x.singleton_class
      end
    end

    describe(Named) do
      it("is a wildcard iff its pattern is a wildcard") do
        assert Named.new(Any.new, :foo).wildcard?
        refute Named.new(Match.new(1), :foo).wildcard?
      end

      it("performs binding") do
        assert Named.new(Any.new, :foo).binds?
      end

      it("matches anything its pattern matches") do
        Named.new(Any.new, :foo).must_be :===, Object.new
        Named.new(Match.new(1), :foo).must_be :===, 1
        Named.new(Match.new(1), :foo).wont_be :===, 2
      end

      it("assigns locals") do
        x = :unassigned
        match(Named.new(Any.new, :x), 1)
        x.must_equal 1

        match(Named.new(Any.new, :x), 2)
        x.must_equal 2
      end

      it("targets its pattern's target for definition") do
        Named.new(Any.new, :foo).definition_target.must_equal Object
        Named.new(List.new([]), :foo).definition_target.must_equal Array
      end
    end

    describe(NamedClass) do
      it("is a wildcard") do
        assert NamedClass.new(:foo).wildcard?
      end

      it("performs binding") do
        assert NamedClass.new(:foo).binds?
      end

      it("matches anything") do
        NamedClass.new(:foo).must_be :===, Object.new
      end

      it("assigns class variables") do
        @@x = :unassigned
        match(NamedClass.new(:x), 1)
        @@x.must_equal 1

        match(NamedClass.new(:x), 2)
        @@x.must_equal 2
      end

      it("targets Object for definition") do
        NamedClass.new(:foo).definition_target.must_equal Object
      end
    end

    describe(NamedGlobal) do
      it("is a wildcard") do
        assert NamedGlobal.new(:foo).wildcard?
      end

      it("performs binding") do
        assert NamedGlobal.new(:foo).binds?
      end

      it("matches anything") do
        NamedGlobal.new(:foo).must_be :===, Object.new
      end

      it("assigns global variables") do
        $x = :unassigned
        match(NamedGlobal.new(:x), 1)
        $x.must_equal 1

        match(NamedGlobal.new(:x), 2)
        $x.must_equal 2
      end

      it("targets Object for definition") do
        NamedGlobal.new(:foo).definition_target.must_equal Object
      end
    end

    describe(NamedInstance) do
      it("is a wildcard") do
        assert NamedInstance.new(:foo).wildcard?
      end

      it("performs binding") do
        assert NamedInstance.new(:foo).binds?
      end

      it("matches anything") do
        NamedInstance.new(:foo).must_be :===, Object.new
      end

      it("assigns instance variables") do
        @x = :unassigned
        match(NamedInstance.new(:x), 1)
        @x.must_equal 1

        match(NamedInstance.new(:x), 2)
        @x.must_equal 2
      end

      it("targets Object for definition") do
        NamedInstance.new(:foo).definition_target.must_equal Object
      end
    end

    describe(QuasiQuote) do
      it("is not a wildcard") do
        refute pat("`_").wildcard?
        refute pat("`~_").wildcard?
      end

      it("performs binding if any unquotes perform binding") do
        refute pat("`_").binds?
        refute pat("`a").binds?
        refute pat("`~_").binds?
        assert pat("`~a").binds?
      end

      it("matches expressions, using unquotes as nested patterns") do
        pat("`a").must_be :===, expr("a")
        pat("`a").wont_be :===, expr("b")
        pat("`~_").must_be :===, expr("a")
        pat("`~_").must_be :===, expr("b")
        pat("`[1, 2]").must_be :===, expr("[1, 2]")
        pat("`[1, 2]").wont_be :===, expr("[1, 3]")
        pat("`[1, ~_]").must_be :===, expr("[1, 2]")
        pat("`[1, ~_]").must_be :===, expr("[1, 3]")
        pat("`[1, ~_]").wont_be :===, expr("[1, 2, 3]")
      end

      it("matches expressions, using splices as nested splat patterns") do
        pat("`[1, ~*_]").must_be :===, expr("[1]")
        pat("`[1, ~*_]").must_be :===, expr("[1, 2]")
        pat("`[1, ~*_]").must_be :===, expr("[1, 2, 3]")
        pat("`[1, ~*_]").wont_be :===, expr("[2, 2, 3]")

        pat("`[1, ~*[]]").must_be :===, expr("[1]")
        pat("`[1, ~*['2]]").must_be :===, expr("[1, 2]")
        pat("`[1, ~*['2, '3]]").must_be :===, expr("[1, 2, 3]")
        pat("`[1, ~*['2, _]]").must_be :===, expr("[1, 2, 4]")
        pat("`[1, ~*_]").wont_be :===, expr("[2, 2, 3]")
      end

      it("allows additional patterns following a splice") do
        pat("`[1, ~*_, 2]").wont_be :===, expr("[1]")
        pat("`[1, ~*_, 2]").must_be :===, expr("[1, 2]")
        pat("`[1, ~*_, 2, 3]").must_be :===, expr("[1, 2, 3]")
        pat("`[1, ~*_, 2, 3]").wont_be :===, expr("[2, 2, 3]")

        pat("`[1, ~*['2], 2]").wont_be :===, expr("[1]")
        pat("`[1, ~*['2], 2]").must_be :===, expr("[1, 2]")
        pat("`[1, ~*['2, '3], 2, 3]").must_be :===, expr("[1, 2, 3]")
        pat("`[1, ~*['2, '3], 2, 3]").wont_be :===, expr("[2, 2, 3]")

        pat("`[1, ~*_, 2, ~*_, 3]").must_be :===, expr("[1, 2, 3]")
      end

      it("targets its expression's class for definition") do
        pat("`[]").definition_target.must_equal Atomy::AST::List
        pat("`a").definition_target.must_equal Atomy::AST::Word
        pat("``a").definition_target.must_equal Atomy::AST::QuasiQuote
        pat("`'a").definition_target.must_equal Atomy::AST::Quote
      end
    end

    describe(Quote) do
      it("is not a wildcard") do
        refute pat("'_").wildcard?
      end

      it("does not perform binding") do
        refute pat("'_").binds?
      end

      it("matches an expression that is == to its value") do
        pat("'_").must_be :===, expr("_")
        pat("'[1, 2, 3]").must_be :===, expr("[1, 2, 3]")
        pat("'[1, 2, 3]").wont_be :===, expr("[1, 2]")
      end

      it("targets its expression's class for definition") do
        pat("'[]").definition_target.must_equal Atomy::AST::List
        pat("'a").definition_target.must_equal Atomy::AST::Word
        pat("'`a").definition_target.must_equal Atomy::AST::QuasiQuote
        pat("''a").definition_target.must_equal Atomy::AST::Quote
      end
    end

    describe(SingletonClass) do
      it("is a wildcard") do
        assert SingletonClass.new(nil).wildcard?
      end

      it("does not perform binding") do
        refute SingletonClass.new(nil).binds?
      end

      it("matches anything") do
        SingletonClass.new(nil).must_be :===, Object.new
      end

      it("targets the singleton class of its body for definition") do
        x = Object.new
        p = SingletonClass.new(Atomy::AST::Literal.new(0, x))
        p.definition_target.must_equal x.singleton_class
      end
    end

    describe(Splat) do
      it("is a wildcard iff its pattern is a wildcard") do
        assert Splat.new(Any.new).wildcard?
        refute Splat.new(List.new([])).wildcard?
      end

      it("performs binding iff its pattern performs binding") do
        refute Splat.new(Any.new).binds?
        assert Splat.new(Named.new(Any.new, :foo)).binds?
      end

      it("matches anything that can be casted to an array") do
        pat("*a").must_be :===, nil
        pat("*a").must_be :===, 1
        pat("*a").must_be :===, [1, 2]

        pat("*[]").must_be :===, nil
        pat("*[1]").must_be :===, 1
        pat("*[1, 2]").must_be :===, [1, 2]
      end

      it("targets Object for definition") do
        Splat.new(Any.new).definition_target.must_equal Object
      end
    end

    describe(:<=>) do
    end

    describe(:=~) do
    end
  end
end

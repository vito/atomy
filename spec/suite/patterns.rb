require_relative("patterns_helper")

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

      it("is never more precise than another pattern") do
        for_every_pattern do |p|
          (Any.new <=> p).wont_equal 1
        end
      end
    end

    describe(Attribute) do
      it("is a wildcard") do
        assert Attribute.arbitrary.wildcard?
      end

      it("performs binding") do
        assert Attribute.arbitrary.binds?
      end

      it("matches anything") do
        Attribute.arbitrary.must_be :===, Object.new
      end

      it("has no definition target") do
        Attribute.arbitrary.definition_target.must_equal Object
      end

      it("is never more precise than another pattern") do
        for_every_pattern do |p|
          (Attribute.arbitrary <=> p).wont_equal 1
        end
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
        pat("//String").definition_target.must_equal ::String
        pat("Atomy Patterns").definition_target.must_equal Atomy::Patterns
      end

      it("uses class/module hierarchy to determine precision") do
        foo = Class.new
        bar = Class.new(foo)

        (Constant.new(nil, Object) <=> Constant.new(nil, Object)).must_equal 0
        (Constant.new(nil, Object) <=> Constant.new(nil, foo)).must_equal -1
        (Constant.new(nil, foo) <=> Constant.new(nil, Object)).must_equal 1
        (Constant.new(nil, foo) <=> Constant.new(nil, foo)).must_equal 0
        (Constant.new(nil, Object) <=> Constant.new(nil, bar)).must_equal -1
        (Constant.new(nil, bar) <=> Constant.new(nil, Object)).must_equal 1
        (Constant.new(nil, bar) <=> Constant.new(nil, bar)).must_equal 0
        (Constant.new(nil, foo) <=> Constant.new(nil, bar)).must_equal -1
        (Constant.new(nil, bar) <=> Constant.new(nil, foo)).must_equal 1
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

      it("compares with HeadTail by comparing both heads and tails") do
        prec_00 = HeadTail.new(Any.new, Any.new)
        prec_01 = HeadTail.new(Any.new, List.new([]))
        prec_10 = HeadTail.new(Match.arbitrary, Any.new)
        prec_11 = HeadTail.new(Match.arbitrary, List.new([]))

        (prec_00 <=> prec_00).must_equal 0
        (prec_00 <=> prec_01).must_equal -1
        (prec_00 <=> prec_10).must_equal -1
        (prec_00 <=> prec_11).must_equal -1
        (prec_01 <=> prec_00).must_equal 1
        (prec_01 <=> prec_01).must_equal 0
        (prec_01 <=> prec_10).must_equal 0
        (prec_01 <=> prec_11).must_equal -1
        (prec_10 <=> prec_00).must_equal 1
        (prec_10 <=> prec_01).must_equal 0
        (prec_10 <=> prec_10).must_equal 0
        (prec_10 <=> prec_11).must_equal -1
        (prec_11 <=> prec_00).must_equal 1
        (prec_11 <=> prec_01).must_equal 1
        (prec_11 <=> prec_10).must_equal 1
        (prec_11 <=> prec_11).must_equal 0
      end

      it("is more precise than Constant") do
        (HeadTail.arbitrary <=> Constant.arbitrary).must_equal 1
        (HeadTail.arbitrary <=> SingletonClass.arbitrary).must_equal 1
      end

      it("is less precise than List") do
        (HeadTail.arbitrary <=> List.arbitrary).must_equal -1
        (HeadTail.arbitrary <=> QuasiQuote.arbitrary).must_equal -1
      end
    end

    describe(List) do
      it("is not a wildcard") do
        refute pat("[]").wildcard?
      end

      it("performs binding iff any of its patterns perform binding") do
        refute pat("[]").binds?
        refute pat("[_]").binds?
        assert pat("[a]").binds?
      end

      it("matches arrays of fixed length") do
        pat("[]").must_be :===, []
        pat("[]").must_be :===, []
        pat("[]").wont_be :===, [1]
        pat("[1]").must_be :===, [1]
      end

      # TODO: test for not allowing a splat to match shorter than required
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

      it("compares with Lists by comparing their patterns") do
        prec_00 = List.new([Any.new, Any.new])
        prec_01 = List.new([Any.new, List.new([])])
        prec_10 = List.new([Match.arbitrary, Any.new])
        prec_11 = List.new([Match.arbitrary, Match.arbitrary])

        (prec_00 <=> prec_00).must_equal 0
        (prec_00 <=> prec_01).must_equal -1
        (prec_00 <=> prec_10).must_equal -1
        (prec_00 <=> prec_11).must_equal -1
        (prec_01 <=> prec_00).must_equal 1
        (prec_01 <=> prec_01).must_equal 0
        (prec_01 <=> prec_10).must_equal 0
        (prec_01 <=> prec_11).must_equal -1
        (prec_10 <=> prec_00).must_equal 1
        (prec_10 <=> prec_01).must_equal 0
        (prec_10 <=> prec_10).must_equal 0
        (prec_10 <=> prec_11).must_equal -1
        (prec_11 <=> prec_00).must_equal 1
        (prec_11 <=> prec_01).must_equal 1
        (prec_11 <=> prec_10).must_equal 1
        (prec_11 <=> prec_11).must_equal 0
      end

      it("is higher precision if ends with a splat and has <= required") do
        (pat("[*_]") <=> pat("[]")).must_equal -1
        (pat("[1, *_]") <=> pat("[]")).must_equal 1
        (pat("[*_]") <=> pat("[1]")).must_equal -1
        (pat("[*_]") <=> pat("[*_]")).must_equal 0
        (pat("[1, *_]") <=> pat("[1, *_]")).must_equal 0
        (pat("[1, *_]") <=> pat("[a, *_]")).must_equal 1
        (pat("[a, *_]") <=> pat("[1, *_]")).must_equal -1
      end

      it("is more precise than HeadTail") do
        (List.arbitrary <=> HeadTail.arbitrary).must_equal 1
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

      it("is never less precise than any other pattern") do
        for_every_pattern do |p|
          (Literal.arbitrary <=> p).wont_equal -1
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

      it("is never less precise than any other pattern") do
        for_every_pattern do |p|
          (Match.arbitrary <=> p).wont_equal -1
        end
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

      it("is never more precise than another pattern") do
        for_every_pattern do |p|
          (NamedClass.arbitrary <=> p).wont_equal 1
        end
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

      it("is never more precise than another pattern") do
        for_every_pattern do |p|
          (NamedGlobal.arbitrary <=> p).wont_equal 1
        end
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

      it("is never more precise than another pattern") do
        for_every_pattern do |p|
          (NamedInstance.arbitrary <=> p).wont_equal 1
        end
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

      # TODO: no exceptions if matching different types
      # TODO: defaults in lists/etc.
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

      it("matches nested quasiquotes/unquotes correctly") do
        pat("`[1, `~_]").must_be :===, expr("[1, `~_]")
        pat("`[1, `~_]").wont_be :===, expr("[1, `~3]")
        pat("`[1, `~_, 3]").must_be :===, expr("[1, `~_, 3]")
        pat("`[1, `~_, 3]").wont_be :===, expr("[1, `~3, 3]")
        pat("`[1, `~~'2, 3]").must_be :===, expr("[1, `~2, 3]")
        pat("`[1, `~~'2, 3]").wont_be :===, expr("[1, `~3, 3]")
        pat("`[1, `~~'2, 3, ~_]").must_be :===, expr("[1, `~2, 3, 4]")
        pat("`[1, `~~'2, 3, ~'4]").must_be :===, expr("[1, `~2, 3, 4]")
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

      it("targets its expression's class for definition") do
        pat("`[]").definition_target.must_equal Atomy::AST::List
        pat("`a").definition_target.must_equal Atomy::AST::Word
        pat("``a").definition_target.must_equal Atomy::AST::QuasiQuote
        pat("`'a").definition_target.must_equal Atomy::AST::Quote
      end

      it("compares precision to other QuasiQuotes by going through quotes") do
        (pat("`~_") <=> pat("`~_")).must_equal 0
        (pat("`~_") <=> pat("`a")).must_equal -1
        (pat("`a") <=> pat("`~_")).must_equal 1
        (pat("`a") <=> pat("`a")).must_equal 0

        (pat("``~~_") <=> pat("``~~_")).must_equal 0
        (pat("``~~_") <=> pat("``~a")).must_equal -1
        (pat("``~a") <=> pat("``~~_")).must_equal 1
        (pat("``~a") <=> pat("``~a")).must_equal 0
      end

      it("yields a precision comparison of 0 if they can't be equivalent") do
        (pat("`!a") <=> pat("`!~_")).must_equal 1
        (pat("`!a") <=> pat("`#~_")).must_equal 0

        (pat("`[~_, !a]") <=> pat("`[1, !~_]")).must_equal 0
        (pat("`[1, !a]") <=> pat("`[~_, `#~_]")).must_equal 0
      end

      it("is less precise if it has a splice where the other has a match") do
        (pat("`foo(1, 2, ~*_)") <=> pat("`foo(1, 2, 3)")).must_equal -1
        (pat("`foo(1, 2, 3)") <=> pat("`foo(1, 2, ~*_)")).must_equal 1
      end

      it("doesn't count a wildcard splice's precision if the other doesn't have it") do
        (pat("`foo(1, ~*_)") <=> pat("`foo(1)")).must_equal 0
        (pat("`foo(1)") <=> pat("`foo(1, ~*_)")).must_equal 0

        (pat("`foo(1, ~*[2])") <=> pat("`foo(1)")).must_equal 1
        (pat("`foo(1)") <=> pat("`foo(1, ~*[2])")).must_equal -1
      end

      it("compares splice patterns if both exist") do
        (pat("`foo(1, 2, ~*_)") <=> pat("`foo(1, 2, ~*[])")).must_equal -1
        (pat("`foo(1, 2, ~*_)") <=> pat("`foo(1, 2, ~*_)")).must_equal 0
        (pat("`foo(1, 2, ~*[])") <=> pat("`foo(1, 2, ~*_)")).must_equal 1
      end

      it("is less precise than Quote") do
        (QuasiQuote.arbitrary <=> Quote.arbitrary).must_equal -1
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

      it("is never less precise than any other pattern") do
        for_every_pattern do |p|
          (Quote.arbitrary <=> p).wont_equal -1
        end
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
        mod = Atomy::Module.new
        p.in_context(mod)
        p.definition_target.must_equal x.singleton_class
      end

      it("is the same precision as Constant") do
        (SingletonClass.arbitrary <=> Constant.arbitrary).must_equal 0
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

    # TODO: note that =~ implies <=> is 0
    describe(:=~) do
    end
  end
end

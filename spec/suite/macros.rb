$LOAD_PATH.unshift File.expand_path("../../../kernel", __FILE__)
$LOAD_PATH.unshift File.expand_path("../", __FILE__)

describe("expressions") do
  it("can expand via macros defined in the same module") do
    require("macros/same-module/module").res.must_equal "same-module"
  end

  it("can expand via macros defined in used modules") do
    require("macros/same-module/user").res.must_equal "same-module"
  end

  it("can not expand via macros defined in modules used by used modules") do
    proc { require("macros/same-module/user-user").res }.must_raise NameError
  end

  describe("macros") do
    it("can expand to expressions that expand via macros provided by a used module") do
      require("macros/context/user").res.must_equal "defined!"
    end

    describe("expansions") do
      it("can expand via macros defined within the same module") do
        require("macros/expansion-same-module/user").res.must_equal 42
      end

      it("can expand via macros defined in a used module") do
        require("macros/expansion-different-module/user").res.must_equal 42
      end
    end
  end
end

describe("let-macro") do
  it("provides macros for a chunk of code") do
    require("let-macro/basic").res.must_equal "basic"
  end

  it("shadows outer macros") do
    require("let-macro/shadowing").res.must_equal "shadowed"
  end

  it("does not leak into the outer module") do
    require("let-macro/shadowing").outer.must_equal "from-macro"
  end

  describe("nesting") do
    describe("body") do
      it("can expand via macros defined in inner let-macros") do
        require("let-macro/nested").using_inner.must_equal "inner-foo"
      end

      it("can expand via macros defined in outer let-macros") do
        require("let-macro/nested").using_outer.must_equal "outer-bar"
      end

      it("can expand via macros defined in any surrounding let-macros") do
        require("let-macro/nested").using_both.must_equal ["inner-foo", "outer-bar"]
      end

      it("can expand via macros defined in the outer module") do
        require("let-macro/nested").using_module.must_equal "module-baz"
      end
    end

    it("does not leak into outer let-macros") do
      require("let-macro/nested").outer_let.must_equal "outer-foo"
    end

    it("does not leak into the outer module") do
      require("let-macro/nested").outer.must_equal ["module-foo", "module-bar", "module-baz"]
    end

    it("can be in terms of macros defined in outer let-macros") do
      require("let-macro/nested").self_using_outer.must_equal "outer-let-bar"
    end

    it("can be in terms of macros defined in the outer module") do
      require("let-macro/nested").self_using_module.must_equal "module-baz"
    end

    describe("expansions") do
      it("can expand via macros defined in outer let-macros") do
        require("let-macro/nested").expansion_using_outer.must_equal "outer-let-bar-expansion"
      end
    end
  end

  describe("expansions") do
    it("can expand via macros defined within the same let-macro") do
      require("let-macro/expansions").expansion_using_self.must_equal 42
    end

    it("can expand via macros defined the outer module") do
      require("let-macro/expansions").expansion_using_module.must_equal "module-baz"
    end

    it("can expand via macros defined in modules used by the outer module") do
    end
  end
end

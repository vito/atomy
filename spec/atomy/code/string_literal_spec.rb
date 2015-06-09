require "spec_helper"

require "atomy/code/string_literal"

describe Atomy::Code::StringLiteral do
  let(:compile_module) { nil }
  let(:raw) { false }

  subject { described_class.new(value, raw) }

  describe "basic strings" do
    let(:value) { "foo" }

    it_compiles_as do |gen|
      gen.push_literal("foo")
      gen.string_dup
    end
  end

  context "with an unknown escape" do
    let(:value) { 'foo \\q bar' }

    it_compiles_as do |gen|
      gen.push_literal("foo \\q bar")
      gen.string_dup
    end

    context "when raw" do
      let(:raw) { true }

      it_compiles_as do |gen|
        gen.push_literal("foo \\q bar")
        gen.string_dup
      end
    end
  end

  described_class::ESCAPES.each do |esc, val|
    context "with escape code \\#{esc}" do
      let(:value) { "foo \\#{esc} bar" }

      it_compiles_as do |gen|
        gen.push_literal("foo #{val} bar")
        gen.string_dup
      end

      context "when raw" do
        let(:raw) { true }

        it_compiles_as do |gen|
          gen.push_literal(value)
          gen.string_dup
        end
      end
    end
  end

  describe "decimal escapes" do
    let(:value) { 'foo \123' }

    it_compiles_as do |gen|
      gen.push_literal("foo {")
      gen.string_dup
    end

    context "when raw" do
      let(:raw) { true }

      it_compiles_as do |gen|
        gen.push_literal(value)
        gen.string_dup
      end
    end
  end

  describe "hexadecimal escapes" do
    let(:value) { 'foo \xabcdefg' }

    it_compiles_as do |gen|
      gen.push_literal("foo \u{ABCDE}fg")
      gen.string_dup
    end

    context "when raw" do
      let(:raw) { true }

      it_compiles_as do |gen|
        gen.push_literal(value)
        gen.string_dup
      end
    end

    context "with a capital X" do
      let(:value) { 'foo \Xabcdefg' }

      it_compiles_as do |gen|
        gen.push_literal("foo \u{ABCDE}fg")
        gen.string_dup
      end

      context "when raw" do
        let(:raw) { true }

        it_compiles_as do |gen|
          gen.push_literal(value)
          gen.string_dup
        end
      end
    end
  end

  describe "octal escapes" do
    let(:value) { 'foo \o12345678' }

    it_compiles_as do |gen|
      gen.push_literal("foo \u{53977}8")
      gen.string_dup
    end

    context "when raw" do
      let(:raw) { true }

      it_compiles_as do |gen|
        gen.push_literal(value)
        gen.string_dup
      end
    end

    context "with a capital O" do
      let(:value) { 'foo \O12345678' }

      it_compiles_as do |gen|
        gen.push_literal("foo \u{53977}8")
        gen.string_dup
      end

      context "when raw" do
        let(:raw) { true }

        it_compiles_as do |gen|
          gen.push_literal(value)
          gen.string_dup
        end
      end
    end
  end

  describe "unicode escapes" do
    let(:value) { 'foo \u12AB' }

    it_compiles_as do |gen|
      gen.push_literal("foo \u12AB")
      gen.string_dup
    end

    context "when raw" do
      let(:raw) { true }

      it_compiles_as do |gen|
        gen.push_literal(value)
        gen.string_dup
      end
    end

    context "with a capital U" do
      let(:value) { 'foo \U12AB' }

      it_compiles_as do |gen|
        gen.push_literal("foo \u12AB")
        gen.string_dup
      end

      context "when raw" do
        let(:raw) { true }

        it_compiles_as do |gen|
          gen.push_literal(value)
          gen.string_dup
        end
      end
    end
  end
end

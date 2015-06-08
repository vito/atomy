require "spec_helper"

require "atomy/bootstrap"
require "atomy/module"
require "atomy/code/send"

describe Atomy::Code::Send do
  let(:receiver) { nil }
  let(:name) { :foo }
  let(:arguments) { [] }
  let(:splat_argument) { nil }
  let(:proc_argument) { nil }
  let(:block) { nil }

  let(:compile_module) do
    Atomy::Module.new do
      use Atomy::Bootstrap
    end
  end

  subject { described_class.new(receiver, name, arguments, splat_argument, proc_argument, block) }

  context "with a receiver" do
    let(:receiver) { ast('"foo"') }

    it_compiles_as do |gen|
      gen.push_literal "foo"
      gen.string_dup
      gen.send :foo, 0
    end

    context "and a splat argument" do
      let(:splat_argument) { ast("splat") }

      it_compiles_as do |gen|
        nil_proc_argument = gen.new_label

        gen.push_literal "foo"
        gen.string_dup
        gen.push_self
        gen.allow_private
        gen.send(:splat, 0)
        gen.push_nil
        gen.send_with_splat :foo, 0
      end
    end

    context "and a proc argument" do
      let(:proc_argument) { ast("abc") }

      it_compiles_as do |gen|
        nil_proc_argument = gen.new_label

        gen.push_literal "foo"
        gen.string_dup
        gen.push_self
        gen.allow_private
        gen.send(:abc, 0)
        gen.dup
        gen.is_nil
        gen.git(nil_proc_argument)
        gen.push_cpath_top
        gen.find_const(:Proc)
        gen.swap
        gen.send(:__from_block__, 1)
        nil_proc_argument.set!
        gen.send_with_block :foo, 0
      end
    end

    context "and arguments" do
      let(:arguments) { [ast('"bar"'), ast('"baz"')] }

      it_compiles_as do |gen|
        gen.push_literal "foo"
        gen.string_dup
        gen.push_literal "bar"
        gen.string_dup
        gen.push_literal "baz"
        gen.string_dup
        gen.send :foo, 2
      end

      context "and a splat argument" do
        let(:splat_argument) { ast("splat") }

        it_compiles_as do |gen|
          gen.push_literal "foo"
          gen.string_dup
          gen.push_literal "bar"
          gen.string_dup
          gen.push_literal "baz"
          gen.string_dup
          gen.push_self
          gen.allow_private
          gen.send(:splat, 0)
          gen.push_nil
          gen.send_with_splat :foo, 2
        end
      end

      context "and a proc argument" do
        let(:proc_argument) { ast("abc") }

        it_compiles_as do |gen|
          nil_proc_argument = gen.new_label

          gen.push_literal "foo"
          gen.string_dup
          gen.push_literal "bar"
          gen.string_dup
          gen.push_literal "baz"
          gen.string_dup
          gen.push_self
          gen.allow_private
          gen.send(:abc, 0)
          gen.dup
          gen.is_nil
          gen.git(nil_proc_argument)
          gen.push_cpath_top
          gen.find_const(:Proc)
          gen.swap
          gen.send(:__from_block__, 1)
          nil_proc_argument.set!
          gen.send_with_block :foo, 2
        end

        context "and a splat argument" do
          let(:splat_argument) { ast("splat") }

          it_compiles_as do |gen|
            nil_proc_argument = gen.new_label

            gen.push_literal "foo"
            gen.string_dup
            gen.push_literal "bar"
            gen.string_dup
            gen.push_literal "baz"
            gen.string_dup
            gen.push_self
            gen.allow_private
            gen.send(:splat, 0)
            gen.push_self
            gen.allow_private
            gen.send(:abc, 0)
            gen.dup
            gen.is_nil
            gen.git(nil_proc_argument)
            gen.push_cpath_top
            gen.find_const(:Proc)
            gen.swap
            gen.send(:__from_block__, 1)
            nil_proc_argument.set!
            gen.send_with_splat :foo, 2
          end
        end
      end

      context "and a block" do
        let(:block) { ast("abc") }

        it_compiles_as do |gen|
          gen.push_literal "foo"
          gen.string_dup
          gen.push_literal "bar"
          gen.string_dup
          gen.push_literal "baz"
          gen.string_dup
          gen.push_self
          gen.allow_private
          gen.send(:abc, 0)
          gen.send_with_block :foo, 2
        end

        context "and a splat argument" do
          let(:splat_argument) { ast("splat") }

          it_compiles_as do |gen|
            gen.push_literal "foo"
            gen.string_dup
            gen.push_literal "bar"
            gen.string_dup
            gen.push_literal "baz"
            gen.string_dup
            gen.push_self
            gen.allow_private
            gen.send(:splat, 0)
            gen.push_self
            gen.allow_private
            gen.send(:abc, 0)
            gen.send_with_splat :foo, 2
          end
        end
      end
    end
  end

  context "with no receiver" do
    it_compiles_as do |gen|
      gen.push_self
      gen.allow_private
      gen.send :foo, 0
    end

    context "and a splat argument" do
      let(:splat_argument) { ast("splat") }

      it_compiles_as do |gen|
        gen.push_self
        gen.push_self
        gen.allow_private
        gen.send(:splat, 0)
        gen.push_nil
        gen.allow_private
        gen.send_with_splat :foo, 0
      end
    end

    context "and a proc argument" do
      let(:proc_argument) { ast("abc") }

      it_compiles_as do |gen|
        nil_proc_argument = gen.new_label

        gen.push_self
        gen.push_self
        gen.allow_private
        gen.send(:abc, 0)
        gen.dup
        gen.is_nil
        gen.git(nil_proc_argument)
        gen.push_cpath_top
        gen.find_const(:Proc)
        gen.swap
        gen.send(:__from_block__, 1)
        nil_proc_argument.set!
        gen.allow_private
        gen.send_with_block :foo, 0
      end

      context "and a splat argument" do
        let(:splat_argument) { ast("splat") }

        it_compiles_as do |gen|
          nil_proc_argument = gen.new_label

          gen.push_self
          gen.push_self
          gen.allow_private
          gen.send(:splat, 0)
          gen.push_self
          gen.allow_private
          gen.send(:abc, 0)
          gen.dup
          gen.is_nil
          gen.git(nil_proc_argument)
          gen.push_cpath_top
          gen.find_const(:Proc)
          gen.swap
          gen.send(:__from_block__, 1)
          nil_proc_argument.set!
          gen.allow_private
          gen.send_with_splat :foo, 0
        end
      end
    end

    context "and a block" do
      let(:block) { ast("abc") }

      it_compiles_as do |gen|
        gen.push_self
        gen.push_self
        gen.allow_private
        gen.send(:abc, 0)
        gen.allow_private
        gen.send_with_block :foo, 0
      end

      context "and a splat argument" do
        let(:splat_argument) { ast("splat") }

        it_compiles_as do |gen|
          gen.push_self
          gen.push_self
          gen.allow_private
          gen.send(:splat, 0)
          gen.push_self
          gen.allow_private
          gen.send(:abc, 0)
          gen.allow_private
          gen.send_with_splat :foo, 0
        end
      end
    end

    context "with arguments" do
      let(:arguments) { [ast('"foo"'), ast('"bar"')] }

      it_compiles_as do |gen|
        gen.push_self
        gen.push_literal "foo"
        gen.string_dup
        gen.push_literal "bar"
        gen.string_dup
        gen.allow_private
        gen.send :foo, 2
      end

      context "and a splat argument" do
        let(:splat_argument) { ast("splat") }

        it_compiles_as do |gen|
          gen.push_self
          gen.push_literal "foo"
          gen.string_dup
          gen.push_literal "bar"
          gen.string_dup
          gen.push_self
          gen.allow_private
          gen.send(:splat, 0)
          gen.push_nil
          gen.allow_private
          gen.send_with_splat :foo, 2
        end
      end

      context "and a proc argument" do
        let(:proc_argument) { ast("abc") }

        it_compiles_as do |gen|
          nil_proc_argument = gen.new_label

          gen.push_self
          gen.push_literal "foo"
          gen.string_dup
          gen.push_literal "bar"
          gen.string_dup
          gen.push_self
          gen.allow_private
          gen.send(:abc, 0)
          gen.dup
          gen.is_nil
          gen.git(nil_proc_argument)
          gen.push_cpath_top
          gen.find_const(:Proc)
          gen.swap
          gen.send(:__from_block__, 1)
          nil_proc_argument.set!
          gen.allow_private
          gen.send_with_block :foo, 2
        end

        context "and a splat argument" do
          let(:splat_argument) { ast("splat") }

          it_compiles_as do |gen|
            nil_proc_argument = gen.new_label

            gen.push_self
            gen.push_literal "foo"
            gen.string_dup
            gen.push_literal "bar"
            gen.string_dup
            gen.push_self
            gen.allow_private
            gen.send(:splat, 0)
            gen.push_self
            gen.allow_private
            gen.send(:abc, 0)
            gen.dup
            gen.is_nil
            gen.git(nil_proc_argument)
            gen.push_cpath_top
            gen.find_const(:Proc)
            gen.swap
            gen.send(:__from_block__, 1)
            nil_proc_argument.set!
            gen.allow_private
            gen.send_with_splat :foo, 2
          end
        end
      end

      context "and a block" do
        let(:block) { ast("abc") }

        it_compiles_as do |gen|
          gen.push_self
          gen.push_literal "foo"
          gen.string_dup
          gen.push_literal "bar"
          gen.string_dup
          gen.push_self
          gen.allow_private
          gen.send(:abc, 0)
          gen.allow_private
          gen.send_with_block :foo, 2
        end

        context "and a splat argument" do
          let(:splat_argument) { ast("splat") }

          it_compiles_as do |gen|
            gen.push_self
            gen.push_literal "foo"
            gen.string_dup
            gen.push_literal "bar"
            gen.string_dup
            gen.push_self
            gen.allow_private
            gen.send(:splat, 0)
            gen.push_self
            gen.allow_private
            gen.send(:abc, 0)
            gen.allow_private
            gen.send_with_splat :foo, 2
          end
        end
      end
    end
  end
end

defmodule ArgParserTest do
  use ExUnit.Case
  alias Wand.CLI.ArgParser
  alias Wand.CLI.Commands.Add.{Git, Hex, Package, Path}

  describe "help" do
    test "no args are given" do
      assert ArgParser.parse([]) == {:help, nil, nil}
    end

    test "the argument of help is given" do
      assert ArgParser.parse(["help"]) == {:help, nil, nil}
    end

    test "with --? passed in" do
      assert ArgParser.parse(["--?"]) == {:help, nil, nil}
    end

    test "an unrecognized command is given" do
      assert ArgParser.parse(["wrong_command"]) == {:help, {:unrecognized, "wrong_command"}}
    end
  end

  describe "add" do
    test "returns help if no args are given" do
      assert ArgParser.parse(["add"]) == {:help, :add, :missing_package}
    end

    test "returns help if invalid flags are given" do
      assert ArgParser.parse(["add", "poison", "--wrong-flag"]) ==
               {:help, :add, {:invalid_flag, "--wrong-flag"}}
    end

    test "returns help if single-package flags are used to install multiple packages" do
      command = OptionParser.split("add poison ex_doc --sparse=foo")
      assert ArgParser.parse(command) == {:help, :add, {:invalid_flag, "--sparse"}}
    end

    test "returns help if a flag for the wrong file type is given" do
      command = OptionParser.split("add ex_doc@file:/test --hex-name=foo")
      assert ArgParser.parse(command) == {:help, :add, {:invalid_flag, "--hex-name"}}
    end

    test "a simple package" do
      assert ArgParser.parse(["add", "poison"]) == {:add, [%Package{name: "poison"}]}
    end

    test "using the shorthand a" do
      assert ArgParser.parse(["a", "poison"]) == {:add, [%Package{name: "poison"}]}
    end

    test "a package with a specific version" do
      assert ArgParser.parse(["add", "poison@3.1"]) ==
               {:add, [%Package{name: "poison", details: %Hex{version: "3.1"}}]}
    end

    test "a package only for the test environment" do
      assert ArgParser.parse(["add", "poison", "--test"]) ==
               {:add, [%Package{name: "poison", environments: [:test]}]}
    end

    test "a package for dev and test" do
      assert ArgParser.parse(["add", "poison", "--test", "--dev"]) ==
               {:add, [%Package{name: "poison", environments: [:test, :dev]}]}
    end

    test "a package for a custom env" do
      assert ArgParser.parse(["add", "ex_doc", "--env=docs"]) ==
               {:add, [%Package{name: "ex_doc", environments: [:docs]}]}
    end

    test "add multiple custom environments and prod" do
      command = OptionParser.split("add ex_doc --env=dogs --env=cat --prod")

      assert ArgParser.parse(command) ==
               {:add, [%Package{name: "ex_doc", environments: [:prod, :dogs, :cat]}]}
    end

    test "set the runtime flag to false" do
      assert ArgParser.parse(["add", "poison", "--runtime=false"]) ==
               {:add, [%Package{name: "poison", runtime: false}]}
    end

    test "set the override flag to true" do
      assert ArgParser.parse(["add", "poison", "--override"]) ==
               {:add, [%Package{name: "poison", override: true}]}
    end

    test "set the optional flag to true" do
      assert ArgParser.parse(["add", "poison", "--optional"]) ==
               {:add, [%Package{name: "poison", optional: true}]}
    end

    test "a local package" do
      expected =
        {:add,
         [
           %Package{
             name: "test",
             details: %Path{
               path: "../test"
             }
           }
         ]}

      assert ArgParser.parse(["add", "test@file:../test"]) == expected
    end

    test "a http github package" do
      expected =
        {:add,
         [
           %Package{
             name: "poison",
             details: %Git{
               uri: "https://github.com/devinus/poison.git"
             }
           }
         ]}
      assert ArgParser.parse(["add", "poison@https://github.com/devinus/poison.git"]) == expected
    end

    test "a ssh github package" do
      expected =
        {:add,
         [
           %Package{
             name: "poison",
             details: %Git{
               uri: "git@github.com:devinus/poison"
             }
           }
         ]}
      assert ArgParser.parse(["add", "poison@git@github.com:devinus/poison"]) == expected
    end

    test "a ssh github package with a ref" do
      expected =
        {:add,
         [
           %Package{
             name: "poison",
             details: %Git{
               uri: "git@github.com:devinus/poison",
               ref: "123"
             }
           }
         ]}
      assert ArgParser.parse(["add", "poison@git@github.com:devinus/poison#123"]) == expected
    end

    test "a ssh github package with a branch" do
      expected =
        {:add,
         [
           %Package{
             name: "poison",
             details: %Git{
               uri: "git@github.com:devinus/poison",
               branch: "master"
             }
           }
         ]}
      assert ArgParser.parse(["add", "poison@git@github.com:devinus/poison#master", "--branch"]) == expected
    end

    test "ssh github package with a tag, sparse, and submodules" do
      expected =
        {:add,
         [
           %Package{
             name: "poison",
             details: %Git{
               uri: "git@github.com:devinus/poison",
               tag: "123",
               sparse: "my_folder",
               submodules: true
             }
           }
         ]}
      command = OptionParser.split("add poison@git@github.com:devinus/poison#123 --tag --sparse=my_folder --submodules")
      assert ArgParser.parse(command) == expected
    end
  end
end

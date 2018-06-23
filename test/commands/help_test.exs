defmodule HelpTest do
  use ExUnit.Case, async: true
  import Mox
  alias Wand.CLI.Commands.Help

  describe "validate" do
    test "the argument of help is given" do
      assert Help.validate(["help"]) == {:error, :banner}
    end

    test "help help displays detailed help information" do
      assert Help.validate(["help", "help"]) == {:error, :verbose}
    end

    test "help --verbose displays detailed help information" do
      assert Help.validate(["help", "--verbose"]) == {:error, :verbose}
    end

    test "with --? passed in" do
      assert Help.validate(["help", "--?"]) == {:error, :verbose}
    end

    test "Handle an invalid arg" do
      assert Help.validate(["help", "--wrong-flag"]) == {:error, {:invalid_flag, "--wrong-flag"}}
    end

    test "help add" do
      assert Help.validate(["help", "add"]) == {:help, :add, :banner}
    end
  end

  describe "help" do
    setup :verify_on_exit!
    setup :stub_io
    test "invalid flag" do
      Help.help({:invalid_flag, "--wrong-flag"})
    end

    test "banner" do
      Help.help(:banner)
    end

    test "verbose" do
      Help.help(:verbose)
    end

    test "unrecognized" do
      Help.help({:unrecognized, "not_add"})
    end

    def stub_io(_) do
      expect(Wand.CLI.IOMock, :puts, fn _message -> :ok end)
      :ok
    end
  end
end

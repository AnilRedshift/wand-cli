defmodule CliTest do
  use ExUnit.Case, async: true
  alias Wand.CLI
  alias Wand.Test.Helpers
  import Mox
  import Wand.CLI.Errors, only: [code: 1]
  setup :verify_on_exit!

  test "help returns a status code of 1" do
    stub_exit(1)
    stub_io()
    CLI.main(["help"])
  end

  test "add without a json file returns a status code of 64" do
    stub_exit(code(:missing_wand_file))
    Helpers.System.stub_core_version()
    Helpers.WandFile.stub_no_file()
    Helpers.IO.stub_stderr()
    CLI.main(["add", "poison"])
  end

  defp stub_exit(status) do
    expect(Wand.SystemMock, :halt, fn ^status -> :ok end)
  end

  defp stub_io() do
    expect(Wand.IOMock, :puts, fn _message -> :ok end)
  end
end

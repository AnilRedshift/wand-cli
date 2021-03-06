defmodule Wand.CLI.Commands.Version do
  use Wand.CLI.Command
  alias Wand.CLI.Display
  @io Wand.Interfaces.IO.impl()
  @moduledoc """
  # Version
  Get the installed version of wand. To get the version of wand_core, use wand core version instead.

  ### Usage
  **wand** version
  """

  @doc false
  def help(:banner), do: Display.print(@moduledoc)
  @doc false
  def help(:verbose), do: help(:banner)

  @doc false
  def validate(_args), do: {:ok, []}

  @doc false
  def execute(_args, %{}) do
    @io.puts(Wand.version())
    {:ok, %Result{message: nil}}
  end
end

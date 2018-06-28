defmodule Wand.CLI.Commands.Remove do
  alias Wand.CLI.Display
  alias Wand.CLI.WandFileWithHelp
  @behaviour Wand.CLI.Command
  @moduledoc """
  Remove elixir packages from wand.json

  ## Usage
  **wand** remove [package] [package]
  """
  def help(:missing_package) do
    """
    wand remove must be called with at least one package name.
    For example, wand remove poison.
    See wand help remove --verbose
    """
    |> Display.print()
  end

  def help(:banner), do: Display.print(@moduledoc)
  def help(:verbose), do: help(:banner)

  def validate(args) do
    {_switches, [_ | commands], _errors} = OptionParser.parse(args)

    case commands do
      [] -> {:error, :missing_package}
      names -> {:ok, names}
    end
  end

  def execute(names) do
    with {:ok, file} <- WandFileWithHelp.load()
    do
    else
      {:error, :wand_file_load, reason} ->
        WandFileWithHelp.handle_error(:wand_file_load, reason)
      {:error, :wand_file_save, reason} ->
        WandFileWithHelp.handle_error(:wand_file_save, reason)
    end
  end
end

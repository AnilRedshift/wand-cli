defmodule Wand.CLI.Commands.Help do
  alias Wand.CLI.Display
  @behaviour Wand.CLI.Command

  @moduledoc Wand.banner()

  @doc false
  def help(:banner), do: Display.print(Wand.banner())

  @doc false
  def help(:verbose) do
    help(:banner)

    Wand.CLI.Command.routes()
    |> List.delete("help")
    |> Enum.each(fn name ->
      module = Wand.CLI.Command.get_module(name)
      module.help(:banner)
      "------------------------------------" |> Display.print()
    end)
  end

  @doc false
  def help({:invalid_flag, flag}) do
    """
    # Error
    `#{flag}` is not a valid flag for help.
    Valid flags are:
    --verbose   Detailed help for every command
    --?         Same as --verbose
    """
    |> Display.print()
  end

  @doc false
  def help({:unrecognized, command}) do
    """
    # Error
    `#{command}` is not a recognized command.
    Type **wand help --verbose** for more information.
    """
    |> Display.print()
  end

  @doc false
  def validate(args) do
    flags = [
      verbose: :boolean,
      "?": :boolean
    ]

    {switches, [_ | commands], errors} = OptionParser.parse(args, strict: flags)

    case Wand.CLI.Command.parse_errors(errors) do
      :ok -> parse(commands, verbose?(switches))
      error -> error
    end
  end

  @doc false
  def execute(_commands, _extra), do: help(:banner)

  defp parse(["help"], _verbose), do: {:error, :verbose}
  defp parse([name], _verbose = true), do: {:help, String.to_atom(name), :verbose}
  defp parse([name], _verbose = false), do: {:help, String.to_atom(name), :banner}
  defp parse(_commands, _verbose = true), do: {:error, :verbose}
  defp parse(_commands, _verbose = false), do: {:error, :banner}

  defp verbose?(switches) do
    cond do
      Keyword.get(switches, :verbose) -> true
      Keyword.get(switches, :"?") -> true
      true -> false
    end
  end
end

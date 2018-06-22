defmodule Wand.CLI.Commands.Init do
  @behaviour Wand.CLI.Command

  def validate(args) do
    flags = [
      overwrite: :boolean,
      task_only: :boolean,
      force: :boolean
    ]

    {switches, [_ | commands], errors} = OptionParser.parse(args, strict: flags)

    case parse_errors(errors) do
      :ok -> get_path(commands, switches)
      error -> error
    end
  end

  defp get_path([], switches), do: {:ok, {"./", switches}}
  defp get_path([path], switches), do: {:ok, {path, switches}}
  defp get_path(_, _), do: {:error, :wrong_command}

  defp parse_errors([]), do: :ok

  defp parse_errors([{flag, _} | _rest]) do
    {:error, {:invalid_flag, flag}}
  end
end

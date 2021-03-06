defmodule Wand.CLI.Mix do
  @moduledoc false
  @system Wand.Interfaces.System.impl()

  def update_deps() do
    mix("deps.get", print_output: true)
    |> strip_ok
  end

  def cleanup_deps() do
    mix("deps.unlock --unused")
    |> strip_ok
  end

  def get_deps(root) do
    case mix("wand_core.init", get_output: true, cd: root) do
      {:ok, message} -> WandCore.Poison.decode(message)
      error -> error
    end
  end

  def outdated() do
    mix("hex.outdated", print_output: true)
    |> strip_ok
  end

  def core_version() do
    mix("wand_core.version", get_output: true)
  end

  def install_core() do
    mix("archive.install hex wand_core --force", print_output: true)
    |> strip_ok
  end

  defp mix(command, opts \\ []) do
    args = OptionParser.split(command)

    opts =
      case Keyword.get(opts, :print_output) do
        true -> [stderr_to_stdout: true, into: IO.stream(:stdio, :line)]
        _ -> [stderr_to_stdout: true]
      end

    {message, code} = @system.cmd("mix", args, opts)

    case code do
      0 -> {:ok, message}
      code -> {:error, {code, message}}
    end
  end

  defp strip_ok({:ok, _}), do: :ok
  defp strip_ok(error), do: error
end

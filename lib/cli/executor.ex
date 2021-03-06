defmodule Wand.CLI.Executor do
  alias Wand.CLI.Executor.Result
  alias Wand.CLI.WandFileWithHelp
  alias Wand.CLI.CoreValidator
  alias Wand.CLI.Error
  alias Wand.CLI.Display
  alias Wand.CLI.DependencyDownloader

  def run(module, data) do
    options = module.options()

    with :ok <- ensure_core(options),
         {:ok, file} <- ensure_wand_file_loaded(options),
         extras <- get_extras(file),
         {:ok, %Result{} = result} <- module.execute(data, extras),
         :ok <- save_file(result),
         :ok <- after_save(result, module, data) do
      print_message(result.message)
      :ok
    else
      {:error, :require_core, reason} ->
        CoreValidator.handle_error(reason)

      {:error, :wand_file, reason} ->
        WandFileWithHelp.handle_error(reason)

      {:error, :install_deps_error, reason} ->
        DependencyDownloader.handle_error(:install_deps_error, reason)
        |> Display.error()

        Error.get(:install_deps_error)

      {:error, error_key, data} ->
        module.handle_error(error_key, data)
        |> Display.error()

        Error.get(error_key)
    end
  end

  defp get_extras(file) do
    [
      wand_file: file
    ]
    |> Enum.reject(&(&1 |> elem(1) == nil))
    |> Enum.into(%{})
  end

  defp save_file(%Result{wand_file: nil}), do: :ok

  defp save_file(%Result{wand_file: wand_file, wand_path: wand_path}) do
    case wand_path do
      nil -> WandFileWithHelp.save(wand_file)
      wand_path -> WandFileWithHelp.save(wand_file, wand_path)
    end
  end

  defp after_save(%Result{wand_file: nil}, _module, _data), do: :ok
  defp after_save(_result, module, data), do: module.after_save(data)

  defp ensure_core(options) do
    case options[:require_core] do
      true -> CoreValidator.require_core()
      _ -> :ok
    end
  end

  defp ensure_wand_file_loaded(options) do
    case options[:load_wand_file] do
      true -> WandFileWithHelp.load()
      _ -> {:ok, nil}
    end
  end

  defp print_message(nil), do: nil
  defp print_message(message), do: Display.success(message)
end

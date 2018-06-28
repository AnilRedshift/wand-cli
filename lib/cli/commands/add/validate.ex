defmodule Wand.CLI.Commands.Add.Validate do
  alias Wand.CLI.Commands.Add.{Git, Hex, Package, Path}

  def validate(args) do
    flags = allowed_flags(args)
    {switches, [_ | commands], errors} = OptionParser.parse(args, strict: flags)

    case Wand.CLI.Command.parse_errors(errors) do
      :ok ->
        requirements = get_requirements(commands, switches)
        get_packages(commands, switches, requirements)

      error ->
        error
    end
  end

  defp get_packages([], _switches, _requirements), do: {:error, :missing_package}

  defp get_packages(_names, _switches, {:error, _} = error), do: error

  defp get_packages(names, switches, {:ok, requirements}) do
    base_package = get_base_package(switches)

    packages =
      Enum.zip(names, requirements)
      |> Enum.map(fn {name, requirement} ->
        {name, _} = split_name(name)
        type = package_type(switches)

        %Package{
          base_package
          | name: name,
            requirement: requirement
        }
        |> add_details(type, switches)
      end)

    {:ok, packages}
  end

  defp get_base_package(switches) do
    download = get_flag(switches, :download)
    compile = download and get_flag(switches, :compile)

    %Package{
      compile: compile,
      compile_env: get_flag(switches, :compile_env),
      download: download,
      environments: get_environments(switches),
      optional: get_flag(switches, :optional),
      override: get_flag(switches, :override),
      read_app_file: get_flag(switches, :read_app_file),
      runtime: get_flag(switches, :runtime)
    }
  end

  defp split_name(package) do
    case String.split(package, "@", parts: 2) do
      [package, version] -> {package, version}
      [package] -> {package, :latest}
    end
  end

  defp add_details(package, :path, switches) do
    details = %Path{
      path: Keyword.fetch!(switches, :path),
      in_umbrella: get_flag(switches, :in_umbrella, %Path{})
    }

    %Package{package | details: details}
  end

  defp add_details(package, :git, switches) do
    {uri, ref} =
      case String.split(Keyword.fetch!(switches, :git), "#", parts: 2) do
        [uri] -> {uri, nil}
        [uri, ref] -> {uri, ref}
      end

    details = %Git{
      uri: uri,
      sparse: get_flag(switches, :sparse, %Git{}),
      submodules: get_flag(switches, :submodules, %Git{}),
      ref: ref
    }

    %Package{package | details: details}
  end

  defp add_details(package, :hex, switches) do
    details = %Hex{
      organization: get_flag(switches, :organization, %Hex{}),
      repo: get_flag(switches, :repo, %Hex{})
    }

    %Package{package | details: details}
  end

  defp add_details(package, :umbrella, _switches) do
    %Package{package | details: %Path{in_umbrella: true}}
  end

  defp add_predefined_environments(environments, switches) do
    [:dev, :test, :prod]
    |> Enum.reduce(environments, fn name, environments ->
      if Keyword.has_key?(switches, name) do
        [name | environments]
      else
        environments
      end
    end)
  end

  defp add_custom_environments(environments, switches) do
    environments ++
      (Keyword.get_values(switches, :env)
       |> Enum.map(&String.to_atom/1))
  end

  defp get_environments(switches) do
    environments =
      add_predefined_environments([], switches)
      |> add_custom_environments(switches)

    case environments do
      [] -> [:all]
      environments -> environments
    end
  end

  defp get_mode(switches) do
    exact = Keyword.get(switches, :exact, false)
    tilde = Keyword.get(switches, :tilde, false)

    cond do
      exact -> :exact
      tilde -> :tilde
      true -> :caret
    end
  end

  defp get_requirements(names, switches) do
    requirements =
      Enum.map(names, fn name ->
        version =
          split_name(name)
          |> elem(1)

        {name, Wand.Mode.get_requirement(get_mode(switches), version)}
      end)

    case Enum.find(requirements, &(&1 |> elem(1) |> elem(0) == :error)) do
      nil ->
        requirements =
          Enum.unzip(requirements)
          |> elem(1)
          |> Enum.unzip()
          |> elem(1)

        {:ok, requirements}

      {name, {:error, reason}} ->
        {:error, {reason, name}}
    end
  end

  defp package_type(switches) do
    cond do
      Keyword.has_key?(switches, :git) -> :git
      Keyword.has_key?(switches, :path) -> :path
      Keyword.has_key?(switches, :in_umbrella) -> :umbrella
      true -> :hex
    end
  end

  defp get_flag(switches, key, struct \\ %Package{}) do
    Keyword.get(switches, key, Map.fetch!(struct, key))
  end

  defp allowed_flags(args) do
    all_flags = %{
      hex: [
        hex_name: :string
      ],
      path: [
        path: :string,
        in_umbrella: :boolean
      ],
      git: [
        git: :string,
        sparse: :string,
        submodules: :boolean
      ],
      umbrella: [
        in_umbrella: :boolean
      ],
      single_package: [
        compile_env: :string,
        read_app_file: :boolean
      ],
      multi_package: [
        compile: :boolean,
        dev: :boolean,
        download: :boolean,
        env: :keep,
        exact: :boolean,
        optional: :boolean,
        organization: :string,
        override: :boolean,
        prod: :boolean,
        repo: :string,
        runtime: :boolean,
        test: :boolean,
        tilde: :boolean
      ]
    }

    {switches, [_ | commands], _errors} = OptionParser.parse(args)

    case length(commands) do
      1 -> [:single_package, :multi_package, package_type(switches)]
      _ -> [:multi_package]
    end
    |> Enum.flat_map(&Map.fetch!(all_flags, &1))
  end
end

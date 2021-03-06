defmodule Wand.Interfaces.IO do
  @moduledoc false
  @callback puts(message :: String.t()) :: :ok
  @callback puts(device :: IO.device(), message :: String.t()) :: :ok

  def impl() do
    Application.get_env(:wand, :io, IO)
  end
end

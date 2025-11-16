defmodule ProyectoFinalPrg3.Adapters.CLI.CommandRegistryBehaviour do
  @moduledoc """
  Behaviour del registro de comandos del CLI.

  Obs: la implementación actual de CommandRegistry devuelve tuplas
  `{:ok, map()}` o `{:error, :comando_no_encontrado}` — por eso el callback
  corresponde a ese tipo.
  """

  @callback all() :: map()
  @callback get(String.t()) :: {:ok, map()} | {:error, :comando_no_encontrado}
end

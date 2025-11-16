defmodule ProyectoFinalPrg3.Adapters.CLI.CommandRegistryBehaviour do
  @moduledoc """
  Define el comportamiento esperado del registro de comandos del CLI.
  Este behaviour permite crear mocks confiables para pruebas mediante Mox.
  """

  @callback all() :: map()
  @callback get(String.t()) :: map() | nil
end

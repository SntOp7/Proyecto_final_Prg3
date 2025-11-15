defmodule ProyectoFinalPrg3.Mocks.CommandRegistryMock do
  @moduledoc """
  Mock del Command Registry para pruebas de CommandParser.
  Implementa el behaviour oficial para permitir uso con Mox.
  """

  use Mox

  # Enlaza este mock con el behaviour correcto
  defmock(
    for: ProyectoFinalPrg3.Adapters.CLI.CommandRegistryBehaviour
  )
end

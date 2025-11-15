defmodule ProyectoFinalPrg3.Adapters.CLI.CommandRegistryBehaviour do
  @moduledoc """
  Behaviour que define la interfaz del Registro de Comandos (Command Registry).

  Esta interfaz permite que el sistema CLI consulte los comandos disponibles
  mediante una función de lookup que recibe el nombre del comando en texto y
  retorna su definición o un error si no existe.

  Este behaviour es indispensable para permitir la creación de mocks con Mox
  en las pruebas, garantizando aislamiento de efectos externos y consistencia
  en la lógica del parser.
  """

  @callback find_command(String.t()) ::
              {:ok, map()} | {:error, :not_found}
end

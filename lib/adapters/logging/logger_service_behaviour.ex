defmodule ProyectoFinalPrg3.Adapters.Logging.LoggerServiceBehaviour do
  @moduledoc """
  Behaviour para el servicio de logging del sistema.

  Se define explícitamente para permitir el uso de Mox
  en pruebas que simulan el comportamiento del LoggerService.
  """

  @callback registrar_evento(mensaje :: String.t(), data :: map()) :: :ok
end

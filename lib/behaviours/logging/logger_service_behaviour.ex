defmodule ProyectoFinalPrg3.Adapters.Logging.LoggerServiceBehaviour do
  @moduledoc "Behaviour para el servicio de logging / auditoría."

  @callback registrar_evento(String.t(), map()) :: :ok
  @callback exportar_a_json(String.t()) :: :ok | {:error, any()}
  @callback exportar_a_txt(String.t()) :: :ok | {:error, any()}
end

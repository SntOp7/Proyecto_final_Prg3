defmodule ProyectoFinalPrg3.Adapters.Persistence.ProgressStoreBehaviour do
  @moduledoc "Behaviour para persistencia de avances (progress)."

  @callback guardar_avance(map()) :: {:ok, map()} | {:error, any()}
  @callback listar_avances() :: [map()]
  @callback obtener_avance(String.t()) :: {:ok, map()} | {:error, any()}
  @callback listar_por_proyecto(String.t()) :: [map()]
  @callback eliminar_avance(String.t()) :: :ok | {:error, any()}
end

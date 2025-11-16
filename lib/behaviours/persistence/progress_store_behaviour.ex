defmodule ProyectoFinalPrg3.Adapters.Persistence.ProgressStoreBehaviour do
  @moduledoc """
  Behaviour para la persistencia de avances de proyecto (Progress).
  """

  @callback guardar_avance(map()) :: {:ok, map()} | {:error, any()}
  @callback listar_avances() :: [map()]
  @callback obtener_avance(String.t()) ::
              {:ok, map()} | {:error, :no_encontrado}
  @callback listar_por_proyecto(String.t()) :: [map()]
  @callback eliminar_avance(String.t()) :: :ok | {:error, any()}
end

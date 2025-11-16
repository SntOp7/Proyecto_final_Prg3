defmodule ProyectoFinalPrg3.Adapters.Persistence.TeamStoreBehaviour do
  @callback guardar_equipo(map()) :: {:ok, map()} | {:error, term()}
  @callback obtener_equipo(String.t()) :: map() | nil
  @callback listar_equipos() :: [map()]
  @callback eliminar_equipo(String.t()) :: :ok | {:error, term()}
end

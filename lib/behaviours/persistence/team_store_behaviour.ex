defmodule ProyectoFinalPrg3.Adapters.Persistence.TeamStoreBehaviour do
  @callback guardar_equipo(map()) :: :ok | {:error, term()}
  @callback obtener_equipo(String.t()) :: map() | nil
  @callback listar_equipos() :: list(map())
  @callback eliminar_equipo(String.t()) :: :ok | {:error, term()}
end

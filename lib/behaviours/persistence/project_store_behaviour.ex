defmodule ProyectoFinalPrg3.Adapters.Persistence.ProjectStoreBehaviour do
  @moduledoc "Behaviour para persistencia de proyectos."

  @callback guardar_proyecto(map()) :: {:ok, map()} | {:error, any()}
  @callback obtener_proyecto(String.t()) :: map() | nil
  @callback listar_proyectos() :: [map()]
  @callback eliminar_proyecto(String.t()) :: :ok | {:error, any()}
end

defmodule ProyectoFinalPrg3.Adapters.Persistence.CategoryStoreBehaviour do
  @moduledoc "Behaviour para persistencia de categorías."

  @callback guardar_categoria(map()) :: {:ok, map()} | {:error, any()}
  @callback obtener_categoria(any()) :: map() | nil
  @callback buscar_por_nombre(String.t()) :: map() | nil
  @callback listar_categorias() :: [map()]
  @callback eliminar_categoria(any()) :: :ok | {:error, any()}
end

defmodule ProyectoFinalPrg3.Adapters.Persistence.CategoryStoreBehaviour do
  @moduledoc """
  Behaviour para la persistencia de categorías dentro del sistema.
  """

  @callback guardar_categoria(map()) :: {:ok, map()} | {:error, any()}
  @callback obtener_categoria(String.t()) :: map() | nil
  @callback buscar_por_nombre(String.t()) :: map() | nil
  @callback listar_categorias() :: [map()]
  @callback eliminar_categoria(String.t()) :: :ok | {:error, any()}
end

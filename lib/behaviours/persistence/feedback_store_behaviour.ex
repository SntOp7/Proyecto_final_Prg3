defmodule ProyectoFinalPrg3.Adapters.Persistence.FeedbackStoreBehaviour do
  @moduledoc """
  Behaviour para la persistencia de retroalimentaciones (feedbacks).
  """

  @callback guardar_feedback(map()) :: {:ok, map()} | {:error, any()}
  @callback obtener_feedback(String.t()) ::
              {:ok, map()} | {:error, :no_encontrado}
  @callback listar_feedbacks() :: [map()]
  @callback eliminar_feedback(String.t()) :: :ok | {:error, any()}
end

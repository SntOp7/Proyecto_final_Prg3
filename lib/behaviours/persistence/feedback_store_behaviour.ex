defmodule ProyectoFinalPrg3.Adapters.Persistence.FeedbackStoreBehaviour do
  @moduledoc "Behaviour para persistencia de feedbacks."

  @callback guardar_feedback(map()) :: {:ok, map()} | {:error, any()}
  @callback obtener_feedback(String.t()) :: {:ok, map()} | {:error, any()}
  @callback listar_feedbacks() :: [map()]
  @callback eliminar_feedback(String.t()) :: :ok | {:error, any()}
end

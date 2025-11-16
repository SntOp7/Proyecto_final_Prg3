defmodule ProyectoFinalPrg3.Services.BroadcastServiceBehaviour do
  @moduledoc "Behaviour para difusión / broadcast de eventos."

  @callback notificar(atom(), any()) :: {:ok, any()} | {:error, any()}
  @callback enviar_directo(String.t(), any()) :: {:ok, any()} | {:error, any()}
  @callback notificar_grupo(atom(), [String.t()], any()) :: :ok | {:error, any()}
end

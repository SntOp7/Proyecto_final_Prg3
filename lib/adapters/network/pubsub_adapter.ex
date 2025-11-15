defmodule ProyectoFinalPrg3.Adapters.Network.PubSubAdapter do
  @moduledoc """
  Adaptador PubSub (envoltorio) usado por BroadcastService.

  - Si `Phoenix.PubSub` está disponible, delega en él usando el nombre
    `ProyectoFinalPrg3.PubSub`.
  - Si no está disponible, realiza operaciones seguras (no-op) para evitar
    errores durante compilación/ejecución en entornos donde no se dispone de Phoenix.
  """

  require Logger

  @pubsub_name ProyectoFinalPrg3.PubSub

  @doc """
  Publica `mensaje` en el tópico derivado de `evento` (atom o string).
  """
  @spec publicar(atom() | String.t(), any()) :: :ok | {:error, any()}
  def publicar(evento, mensaje) do
    topic = topic_for(evento)

    cond do
      Code.ensure_loaded?(Phoenix.PubSub) ->
        try do
          Phoenix.PubSub.broadcast(@pubsub_name, topic, mensaje)
          :ok
        rescue
          err ->
            Logger.debug("PubSubAdapter publicar error: #{inspect(err)}")
            {:error, err}
        end

      true ->
        # Phoenix.PubSub no disponible: no-op pero loguea en debug para visibilidad
        Logger.debug("PubSubAdapter: Phoenix.PubSub no cargado — publicar/2 es no-op (topic: #{topic}).")
        :ok
    end
  end

  @doc """
  Suscribe `pid` al tópico del `evento`. Si no se provee pid, usa `self()`.
  """
  @spec suscribir(atom() | String.t(), pid() | nil) :: {:ok, :subscribed} | {:error, any()} | :ok
  def suscribir(evento, pid \\ self()) do
    topic = topic_for(evento)

    cond do
      Code.ensure_loaded?(Phoenix.PubSub) ->
        try do
          Phoenix.PubSub.subscribe(@pubsub_name, topic)
          Logger.debug("PubSubAdapter: suscrito a #{topic} (pid #{inspect(pid)})")
          {:ok, :subscribed}
        rescue
          err ->
            Logger.debug("PubSubAdapter suscribir error: #{inspect(err)}")
            {:error, err}
        end

      true ->
        Logger.debug("PubSubAdapter: Phoenix.PubSub no cargado — suscribir/2 es no-op (topic: #{topic}).")
        :ok
    end
  end

  @doc """
  Cancela la suscripción del `pid` al tópico del `evento`.
  """
  @spec desuscribir(atom() | String.t(), pid() | nil) :: {:ok, :unsubscribed} | {:error, any()} | :ok
  def desuscribir(evento, pid \\ self()) do
    topic = topic_for(evento)

    cond do
      Code.ensure_loaded?(Phoenix.PubSub) ->
        try do
          Phoenix.PubSub.unsubscribe(@pubsub_name, topic)
          Logger.debug("PubSubAdapter: desuscrito de #{topic} (pid #{inspect(pid)})")
          {:ok, :unsubscribed}
        rescue
          err ->
            Logger.debug("PubSubAdapter desuscribir error: #{inspect(err)}")
            {:error, err}
        end

      true ->
        Logger.debug("PubSubAdapter: Phoenix.PubSub no cargado — desuscribir/2 es no-op (topic: #{topic}).")
        :ok
    end
  end

  # ---------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------
  defp topic_for(evento) when is_atom(evento), do: Atom.to_string(evento)
  defp topic_for(evento) when is_binary(evento), do: evento
end

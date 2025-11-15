defmodule ProyectoFinalPrg3.Adapters.Network.PubSubAdapter do
  @moduledoc """
  Adaptador envoltorio para Phoenix.PubSub utilizado por BroadcastService
  y por InitialBootService durante el arranque del sistema.

  Funciones clave usadas por otros módulos:
    - inicializar/0
    - publicar/2
    - suscribir/1
    - desuscribir/1

  Este adaptador es *fail-safe*: si Phoenix.PubSub no está disponible,
  todas las operaciones se degradan a no-op seguro.
  """

  require Logger

  @pubsub_name ProyectoFinalPrg3.PubSub

  # ============================================================
  # INIT — Usado por InitialBootService
  # ============================================================
  @doc """
  Inicializa el sistema PubSub si Phoenix.PubSub está disponible.

  Es llamada desde:
    - InitialBootService
    - BroadcastService (en casos de reinicio)

  Si Phoenix no está instalado, solo registra en debug.
  """
  def inicializar do
    cond do
      Code.ensure_loaded?(Phoenix.PubSub) ->
        case start_pubsub() do
          {:ok, _pid} ->
            Logger.debug("PubSubAdapter: Phoenix.PubSub inicializado correctamente.")
            :ok

          {:error, {:already_started, _pid}} ->
            Logger.debug("PubSubAdapter: Phoenix.PubSub ya estaba inicializado.")
            :ok

          {:error, reason} ->
            Logger.error("PubSubAdapter: error inicializando PubSub: #{inspect(reason)}")
            {:error, reason}
        end

      true ->
        Logger.debug("PubSubAdapter: Phoenix.PubSub no está disponible — inicializar/0 es no-op.")
        :ok
    end
  end


  defp start_pubsub do
    Phoenix.PubSub.PG2.start_link(name: @pubsub_name)
  end

  # ============================================================
  # PUBLICAR
  # ============================================================
  @doc """
  Publica un mensaje en un tópico.

  Si Phoenix no está disponible, es un no-op seguro.
  """
  def publicar(evento, mensaje) do
    topic = topic_for(evento)

    cond do
      Code.ensure_loaded?(Phoenix.PubSub) ->
        Phoenix.PubSub.broadcast(@pubsub_name, topic, mensaje)
        :ok

      true ->
        Logger.debug("PubSubAdapter NO-OP (sin Phoenix): publicar #{inspect(topic)}.")
        :ok
    end
  end

  # ============================================================
  # SUSCRIBIR
  # ============================================================
  def suscribir(evento, _pid \\ self()) do
    topic = topic_for(evento)

    cond do
      Code.ensure_loaded?(Phoenix.PubSub) ->
        Phoenix.PubSub.subscribe(@pubsub_name, topic)
        {:ok, :subscribed}

      true ->
        Logger.debug("PubSubAdapter NO-OP: suscribir #{inspect(topic)}.")
        :ok
    end
  end

  # ============================================================
  # DESUSCRIBIR
  # ============================================================
  def desuscribir(evento, _pid \\ self()) do
    topic = topic_for(evento)

    cond do
      Code.ensure_loaded?(Phoenix.PubSub) ->
        Phoenix.PubSub.unsubscribe(@pubsub_name, topic)
        {:ok, :unsubscribed}

      true ->
        Logger.debug("PubSubAdapter NO-OP: desuscribir #{inspect(topic)}.")
        :ok
    end
  end

  # ============================================================
  # HELPERS
  # ============================================================
  defp topic_for(evento) when is_atom(evento), do: Atom.to_string(evento)
  defp topic_for(evento) when is_binary(evento), do: evento
end

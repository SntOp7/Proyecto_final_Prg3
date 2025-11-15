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

  @pubsub ProyectoFinalPrg3.PubSub

  # ============================================================
  # PUBLICAR
  # ============================================================
  @doc """
  Publica un mensaje en un tópico.

  Si Phoenix no está disponible, es un no-op seguro.
  """
  def publicar(evento, mensaje) do
    if Code.ensure_loaded?(Phoenix.PubSub) do
      Phoenix.PubSub.broadcast(@pubsub, to_topic(evento), mensaje)
    else
      Logger.debug("PubSub no disponible — mensaje no enviado")
    end

    :ok
  end

  # ============================================================
  # SUSCRIBIR
  # ============================================================
  def suscribir(evento, _pid \\ self()) do
    if Code.ensure_loaded?(Phoenix.PubSub) do
      Phoenix.PubSub.subscribe(@pubsub, to_topic(evento))
    end

    :ok
  end

  # ============================================================
  # DESUSCRIBIR
  # ============================================================
  def desuscribir(evento, _pid \\ self()) do
    if Code.ensure_loaded?(Phoenix.PubSub) do
      Phoenix.PubSub.unsubscribe(@pubsub, to_topic(evento))
    end

    :ok
  end

  defp to_topic(ev) when is_atom(ev), do: Atom.to_string(ev)
  defp to_topic(ev), do: ev
end

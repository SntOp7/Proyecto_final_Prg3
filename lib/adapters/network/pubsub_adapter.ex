defmodule ProyectoFinalPrg3.Adapters.Network.PubSubAdapter do
  @moduledoc """
  Adaptador encargado de gestionar la mensajería interna basada en `Phoenix.PubSub`.

  Este módulo proporciona una capa ligera y segura para enviar y recibir mensajes
  entre procesos dentro de un mismo nodo del sistema distribuido. No utiliza
  WebSockets ni Phoenix Channels; únicamente emplea PubSub interno del BEAM.

  Es utilizado principalmente por:

    - `ChannelManager`
    - `MessageBroadcast`
    - `AnnouncementChannel`
    - `MentorshipChannel`
    - Servicios que requieren suscripción a eventos internos

  ## Funciones principales
    - `publicar/2`: Difunde un mensaje a todos los suscriptores de un evento.
    - `suscribirse/2`: Registra un proceso como suscriptor de un canal lógico.
    - `desuscribir/2`: Elimina la suscripción de un proceso.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha: 2025-10-27
  Licencia: GNU GPLv3
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

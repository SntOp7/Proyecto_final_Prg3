defmodule ProyectoFinalPrg3.Adapters.Network.MessageBroadcast do
  @moduledoc """
  Adaptador encargado de unificar el envío de mensajes locales y distribuidos.

  Este módulo centraliza la lógica para difundir mensajes dentro del nodo actual
  (vía PubSub) y hacia otros nodos del cluster (vía RPC). Adicionalmente,
  normaliza y formatea los mensajes emitidos para mantener consistencia entre
  los distintos módulos de comunicación.

  Es utilizado principalmente por:

    - `AnnouncementChannel`
    - `MentorshipChannel`
    - `ChatService`
    - `TeamManager`
    - `MentorManager`

  ## Funciones principales
    - `emitir_local/4`: Envía un mensaje únicamente dentro del nodo actual.
    - `emitir_distribuido/4`: Difunde un mensaje hacia otros nodos conectados.
    - `emitir/5`: Realiza un broadcast combinado (local + distribuido).
    - Encapsula formateo estándar de payloads para todos los canales.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Adapters.Network.ChannelManager
  alias ProyectoFinalPrg3.Adapters.Network.NodeManager
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # -------------------------------------------------------------
  # UTILIDADES DE FORMATO
  # -------------------------------------------------------------
  def formatear(tipo, contenido, meta \\ %{}) do
    %{
      type: tipo,
      content: contenido,
      meta: meta,
      timestamp: DateTime.utc_now()
    }
  end

  # -------------------------------------------------------------
  # BROADCAST LOCAL (DENTRO DEL NODO)
  # -------------------------------------------------------------
  @doc """
  Emite un mensaje únicamente dentro del nodo actual.

  Usa ChannelManager → PubSubAdapter → Phoenix.PubSub.
  """
  def emitir_local(canal, tipo, contenido, meta \\ %{}) do
    payload = formatear(tipo, contenido, meta)

    ChannelManager.broadcast(canal, payload)

    LoggerService.registrar_evento("Broadcast local enviado", %{
      canal: canal,
      payload: payload
    })

    {:ok, :local}
  end

  # -------------------------------------------------------------
  # BROADCAST ENTRE NODOS (DISTRIBUIDO)
  # -------------------------------------------------------------
  @doc """
  Emite un mensaje a todos los nodos conectados.

  Usa NodeManager → RPC distribuido.
  """
  def emitir_distribuido(evento, tipo, contenido, meta \\ %{}) do
    payload = formatear(tipo, contenido, meta)

    NodeManager.enviar_a_nodos(evento, payload)

    LoggerService.registrar_evento("Broadcast distribuido enviado", %{
      evento: evento,
      payload: payload
    })

    {:ok, :distribuido}
  end

  # -------------------------------------------------------------
  # BROADCAST COMBINADO (LOCAL + DISTRIBUIDO)
  # -------------------------------------------------------------
  @doc """
  Emite un mensaje local + distribuido en una sola llamada.

  Es el método MÁS utilizado por:
    - AnnouncementChannel
    - MentorshipChannel
    - ChatService
  """
  def emitir(canal_local, evento_remoto, tipo, contenido, meta \\ %{}) do
    {:ok, :local} = emitir_local(canal_local, tipo, contenido, meta)
    {:ok, :distribuido} = emitir_distribuido(evento_remoto, tipo, contenido, meta)

    {:ok, :enviado}
  end
end

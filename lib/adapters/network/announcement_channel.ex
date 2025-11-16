defmodule ProyectoFinalPrg3.Channels.AnnouncementChannel do
  @moduledoc """
  Canal global utilizado para la difusión de mensajes de anuncio a todos los
  participantes del sistema.

  Este canal proporciona un mecanismo unificado para enviar anuncios generales
  desde la organización hacia todos los procesos suscritos, usando PubSub
  interno. Opera de manera local dentro del nodo, pero puede integrarse con
  mensajería distribuida mediante `MessageBroadcast`.

  Es utilizado principalmente por:

    - `BroadcastService`
    - Paneles de administración de la Hackathon
    - Componentes que deban recibir anuncios globales

  ## Funciones principales
    - `subscribe/1`: Suscribe un proceso al canal global de anuncios.
    - `announce/1`: Envía un mensaje al canal de anuncios.
    - Manejo de mensajes PubSub a través de `handle_info/2`.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha: 2025-10-27
  Licencia: GNU GPLv3
  """

  use GenServer

  alias ProyectoFinalPrg3.Adapters.Network.PubSubAdapter
  alias ProyectoFinalPrg3.Adapters.Network.ChannelManager

  @canal :announcement_channel

  # -----------------------------
  # API pública
  # -----------------------------

  @doc """
  Suscribe un proceso al canal de anuncios.
  """
  def subscribe(pid \\ self()) do
    PubSubAdapter.suscribir(@canal, pid)
  end

  @doc """
  Envía un anuncio global.
  """
  def announce(message) when is_binary(message) do
    ChannelManager.broadcast(@canal, %{type: :announcement, text: message})
  end

  # -----------------------------
  # GenServer
  # -----------------------------

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    # El propio canal se suscribe al PubSub para reenviar internamente si es necesario
    PubSubAdapter.suscribir(@canal, self())
    {:ok, state}
  end

  @impl true
  def handle_info(mensaje, state) do
    # Aquí decides qué hace el canal al recibir un anuncio
    # Por ahora solo imprime en consola (puedes eliminarlo o reemplazarlo)
    IO.puts("[AnnouncementChannel] recibido: #{inspect(mensaje)}")

    {:noreply, state}
  end
end

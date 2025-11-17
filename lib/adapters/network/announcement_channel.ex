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
    - Interfaces o procesos que deban recibir anuncios globales

  ## Funciones principales
    - `subscribe/1`: Suscribe un proceso al canal global de anuncios.
    - `announce/1`: Envía un mensaje de anuncio al sistema.
    - Procesamiento de eventos PubSub a través de `handle_info/2`.

  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  use GenServer

  alias ProyectoFinalPrg3.Adapters.Network.PubSubAdapter
  alias ProyectoFinalPrg3.Adapters.Network.ChannelManager

  @canal :announcement_channel

  # ============================================================
  # SUSCRIPCIÓN AL CANAL
  # ============================================================

  @doc """
  Suscribe un proceso al canal global de anuncios.

  ## Flujo:
    1. Verifica el proceso objetivo (por defecto, `self()`).
    2. Realiza una suscripción directa al canal PubSub interno.
    3. Permite que el proceso reciba todos los anuncios futuros.

  ## Parámetros:
    - `pid` (opcional): Proceso a suscribir. Por defecto: `self()`.

  ## Retorna:
    - `:ok` – suscripción realizada con éxito.

  ## Ejemplo:
      iex> AnnouncementChannel.subscribe()
      :ok
  """
  def subscribe(pid \\ self()) do
    PubSubAdapter.suscribir(@canal, pid)
  end

  # ============================================================
  # ENVÍO DE ANUNCIOS
  # ============================================================

  @doc """
  Envía un anuncio global al sistema.

  El mensaje será recibido por todos los procesos suscritos al canal interno
  de anuncios. El envío se realiza mediante `ChannelManager.broadcast/2`,
  asegurando consistencia con el sistema de mensajería interna.

  ## Flujo:
    1. Valida que el mensaje sea un texto.
    2. Construye un payload estandarizado (`type: :announcement`).
    3. Realiza un broadcast a través del ChannelManager.
    4. Todos los suscriptores reciben el anuncio.

  ## Parámetros:
    - `message`: Texto del anuncio (string).

  ## Retorna:
    - `:ok` – broadcast enviado correctamente.
  """
  def announce(message) when is_binary(message) do
    ChannelManager.broadcast(@canal, %{type: :announcement, text: message})
  end

  # ============================================================
  # INICIALIZACIÓN DEL SERVIDOR
  # ============================================================

  @doc """
  Inicia el proceso GenServer del canal de anuncios.

  ## Flujo:
    1. Inicia el proceso con estado vacío.
    2. Registra el proceso bajo el nombre del módulo.
    3. Permite que el canal empiece a recibir mensajes PubSub.

  ## Retorna:
    - `{:ok, pid}` si el servidor inicia correctamente.
    - `{:error, razon}` si ocurre un fallo.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # ============================================================
  # CONFIGURACIÓN INICIAL
  # ============================================================

  @doc """
  Configura el estado inicial del canal y lo suscribe automáticamente
  al canal PubSub de anuncios.

  Esto permite que el propio proceso del canal reciba los anuncios y
  ejecute lógica adicional (reenviar, persistir, depurar, etc.).

  ## Retorna:
    - `{:ok, state}` indicando estado inicial exitoso.
  """
  @impl true
  def init(state) do
    PubSubAdapter.suscribir(@canal, self())
    {:ok, state}
  end

  # ============================================================
  # RECEPCIÓN DE MENSAJES PUBSUB
  # ============================================================

  @doc """
  Maneja los mensajes recibidos desde PubSub.

  Actualmente, el canal simplemente imprime el mensaje recibido,
  pero este método puede extenderse para:

    - reenviar a websockets,
    - registrar logs,
    - disparar eventos internos,
    - integrar con interfaces administrativas,
    - procesar analíticas de uso.

  ## Parámetros:
    - `mensaje`: payload emitido en el canal PubSub.
    - `state`: estado interno del canal.

  ## Retorna:
    - `{:noreply, state}` – continúa el ciclo del GenServer.
  """
  @impl true
  def handle_info(mensaje, state) do
    IO.puts("[AnnouncementChannel] recibido: #{inspect(mensaje)}")
    {:noreply, state}
  end
end

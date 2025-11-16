defmodule ProyectoFinalPrg3.Channels.MentorshipChannel do
  @moduledoc """
  Canal privado de comunicación entre mentores y equipos.

  Cada equipo dispone de un canal lógico independiente en el formato
  `:mentor_team_<id>`, permitiendo el intercambio de mensajes entre mentores y
  miembros del equipo. Este canal soporta tanto difusión local (PubSub) como
  broadcast distribuido entre nodos mediante `MessageBroadcast`.

  Es utilizado principalmente por:

    - `MentorManager`
    - `TeamManager`
    - Interfaces de mentoría
    - Servicios que gestionan interacción mentor-equipo

  ## Funciones principales
    - `subscribe/2`: Suscribe procesos a un canal de equipo.
    - `enviar/4`: Difunde un mensaje local y distribuido al equipo.
    - Manejo de eventos PubSub mediante `handle_info/2`.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha: 2025-10-27
  Licencia: GNU GPLv3
  """

  use GenServer

  alias ProyectoFinalPrg3.Adapters.Network.{PubSubAdapter, MessageBroadcast}
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # ============================================================
  # API PÚBLICA
  # ============================================================

  @doc """
  Construye el nombre lógico del canal de mentoría para un equipo específico.

  ## Flujo:
    1. Recibe un `team_id`.
    2. Devuelve un átomo con el formato `:mentor_team_<id>`.

  ## Parámetros:
    - `team_id`: Identificador del equipo.

  ## Retorna:
    - `:mentor_team_<id>` como átomo.
  """
  def canal_equipo(team_id), do: :"mentor_team_#{team_id}"

  @doc """
  Suscribe un proceso (mentor o integrante del equipo) al canal del equipo.

  ## Flujo:
    1. Construye el nombre del canal mediante `canal_equipo/1`.
    2. Registra al proceso en PubSub como suscriptor del canal.
    3. Registra el evento de suscripción en logs.
    4. Retorna el canal para referencia externa.

  ## Parámetros:
    - `team_id`: Identificador del equipo.
    - `pid` (opcional): Proceso a suscribir. Por defecto: `self()`.

  ## Retorna:
    - `{:ok, canal}` indicando que la suscripción fue exitosa.
  """
  def subscribe(team_id, pid \\ self()) do
    canal = canal_equipo(team_id)
    PubSubAdapter.suscribir(canal, pid)

    LoggerService.registrar_evento("Suscripción a canal de mentoría", %{
      canal: canal,
      pid: inspect(pid)
    })

    {:ok, canal}
  end

  @doc """
  Envía un mensaje al canal de mentoría del equipo, tanto local como
  distribuido entre nodos del cluster.

  `MessageBroadcast.emitir/5` se encarga de:
    - enviar al canal local (PubSub),
    - difundir hacia nodos remotos (RPC),
    - formatear el payload estándar del sistema.

  ## Flujo:
    1. Construye el canal del equipo.
    2. Envía el mensaje usando broadcast local + distribuido.
    3. Agrega `team_id` al campo meta del mensaje.
    4. Devuelve la respuesta de `MessageBroadcast`.

  ## Parámetros:
    - `team_id`: Identificador del equipo.
    - `role`: Rol del emisor (`:mentor | :equipo | :sistema`).
    - `contenido`: Cuerpo del mensaje.
    - `meta` (opcional): Datos adicionales del mensaje.

  ## Retorna:
    - `{:ok, ...}` dependiendo de `MessageBroadcast.emitir/5`.
  """
  def enviar(team_id, role, contenido, meta \\ %{}) do
    canal = canal_equipo(team_id)

    MessageBroadcast.emitir(
      canal,
      :mentor_event,
      role,
      contenido,
      Map.put(meta, :team_id, team_id)
    )
  end

  # ============================================================
  # GEN_SERVER
  # ============================================================

  @doc """
  Inicia el proceso GenServer que administra las suscripciones globales
  del canal de mentoría.

  ## Flujo:
    1. Crea el proceso con estado inicial vacío.
    2. Registra el proceso bajo el nombre del módulo.
    3. Permite recibir mensajes distribuidos.

  ## Retorna:
    - `{:ok, pid}` si el servidor inicia correctamente.
    - `{:error, razon}` en caso de fallo.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Inicializa el canal de mentoría y suscribe el propio GenServer
  al evento distribuido `:mentor_event`.

  Esto permite recibir mensajes provenientes de otros nodos del cluster.

  ## Flujo:
    1. Se suscribe al evento `:mentor_event`.
    2. Registra un log indicando que el canal fue inicializado.
    3. Retorna el estado inicial del GenServer.

  ## Retorna:
    - `{:ok, state}` estado inicial.
  """
  @impl true
  def init(state) do
    PubSubAdapter.suscribir(:mentor_event)

    LoggerService.registrar_evento("MentorshipChannel inicializado", %{
      nodo: Node.self()
    })

    {:ok, state}
  end

  # ============================================================
  # MANEJO DE EVENTOS (PAYLOAD FORMATEADO)
  # ============================================================

  @doc """
  Maneja mensajes ya formateados (estructura estándar):

      %{type: role, content: contenido, meta: meta}

  Estos mensajes pueden provenir:
    - del PubSub local,
    - de un nodo remoto (RPC → MessageBroadcast → PubSub).

  ## Flujo:
    1. Extrae el rol, contenido y metadata del mensaje.
    2. Registra el evento en logs.
    3. Continúa sin responder a la fuente (`:noreply`).

  ## Retorna:
    - `{:noreply, state}`
  """

  @impl true
  def handle_info(%{type: role, content: contenido, meta: meta}, state) do
    LoggerService.registrar_evento("MentorshipChannel mensaje recibido", %{
      role: role,
      contenido: contenido,
      meta: meta
    })

    {:noreply, state}
  end

  def handle_info(mensaje, state) do
    LoggerService.registrar_evento("MentorshipChannel evento crudo recibido", %{
      mensaje: mensaje
    })

    {:noreply, state}
  end
end

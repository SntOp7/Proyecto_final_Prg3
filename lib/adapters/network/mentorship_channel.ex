defmodule ProyectoFinalPrg3.Channels.MentorshipChannel do
  @moduledoc """
  Canal privado de comunicación entre mentores y equipos.

  Cada equipo dispone de un canal lógico independiente en el formato
  `:mentor_team_<id>`, permitiendo el intercambio de mensajes entre mentores y
  miembros del equipo. Este canal soporta tanto difusión local (PubSub) como
  broadcast distribuido entre nodos.

  Es utilizado principalmente por:

    - `MentorManager`
    - `TeamManager`
    - Interfaces de mentoría
    - Servicios que gestionan interacción mentor-equipo

  ## Funciones principales
    - `subscribe/2`: Suscribe un proceso al canal de mentoría de un equipo.
    - `enviar/4`: Envía un mensaje a un canal de equipo (local + distribuido).
    - Procesamiento de eventos PubSub mediante `handle_info/2`.

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
  Retorna el nombre del canal para un equipo.
  """
  def canal_equipo(team_id), do: :"mentor_team_#{team_id}"

  @doc """
  Suscribe un proceso (mentor o miembro del equipo) al canal.
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
  Envía un mensaje al canal del equipo.

  `role` puede ser:
    - :mentor
    - :equipo
    - :sistema
  """
  def enviar(team_id, role, contenido, meta \\ %{}) do
    canal = canal_equipo(team_id)

    # Local + Distribuido usando MessageBroadcast
    MessageBroadcast.emitir(
      # canal local (PubSub)
      canal,
      # evento para nodos remotos
      :mentor_event,
      # tipo
      role,
      # contenido del mensaje
      contenido,
      Map.put(meta, :team_id, team_id)
    )
  end

  # ============================================================
  # GEN_SERVER
  # ============================================================

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    # Nos suscribimos al evento distribuido "mentor_event" para recibir RPC remotos
    PubSubAdapter.suscribir(:mentor_event)

    LoggerService.registrar_evento("MentorshipChannel inicializado", %{
      nodo: Node.self()
    })

    {:ok, state}
  end

  @impl true
  def handle_info(%{type: role, content: contenido, meta: meta}, state) do
    # Este mensaje viene de PubSub (local o remotamente si MessageBroadcast lo difunde)
    LoggerService.registrar_evento("MentorshipChannel mensaje recibido", %{
      role: role,
      contenido: contenido,
      meta: meta
    })

    # Aquí no reenviamos nada porque MessageBroadcast ya entregó el mensaje
    {:noreply, state}
  end

  # Mensajes crudos desde PubSub
  def handle_info(mensaje, state) do
    LoggerService.registrar_evento("MentorshipChannel evento crudo recibido", %{
      mensaje: mensaje
    })

    {:noreply, state}
  end
end

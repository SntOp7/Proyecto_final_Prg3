defmodule ProyectoFinalPrg3.Adapters.Network.AnnouncementChannel do
  use GenServer

  alias ProyectoFinalPrg3.Adapters.Security.SessionManager
  alias ProyectoFinalPrg3.Adapters.Persistence.ChatStore
  alias ProyectoFinalPrg3.Domain.Message
  alias ProyectoFinalPrg3.Adapters.Network.PubSubAdapter
  alias ProyectoFinalPrg3.Adapters.Network.ChannelManager
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # Canal OFICIAL de anuncios globales
  @canal "canal_anuncios_globales"

  # ------------------------------------------------------------
  # API pública
  # ------------------------------------------------------------

  # Suscripción local (CLI)
  def subscribe(pid \\ self()) do
    PubSubAdapter.suscribir(@canal, pid)
  end

  # RPC desde CLI → CENTRAL
  def publish_remote(texto, usuario) do
    enviar_validado(texto, usuario)
  end

  # Validación local dentro de CENTRAL
  def announce(texto) do
    with {:ok, usuario} <- SessionManager.obtener_participante_actual(),
         true <- usuario.rol == :admin do
      construir_y_broadcast(texto, usuario.id)
    else
      _ -> {:error, "No tienes permisos para enviar anuncios."}
    end
  end

  # ------------------------------------------------------------
  # Validación remota y local
  # ------------------------------------------------------------

  defp enviar_validado(texto, usuario) do
    contenido = String.trim(texto)

    cond do
      contenido == "" ->
        {:error, "El anuncio no puede estar vacío."}

      usuario.rol != :admin ->
        {:error, "No tienes permisos para enviar anuncios."}

      true ->
        construir_y_broadcast(contenido, usuario.id)
    end
  end

  # ------------------------------------------------------------
  # Construcción y difusión del mensaje
  # ------------------------------------------------------------

  defp construir_y_broadcast(contenido, admin_id) do
    mensaje =
      Message.nuevo(
        UUID.uuid4(),
        admin_id,
        @canal,
        "📢 #{contenido}",
        DateTime.utc_now()
      )

    # Persistencia
    ChatStore.agregar_mensaje(@canal, mensaje)

    # Broadcast a todos los nodos
    ChannelManager.broadcast(@canal, mensaje)

    # Log
    LoggerService.registrar_evento("Anuncio global enviado", %{
      admin: admin_id,
      contenido: contenido
    })

    {:ok, mensaje}
  end

  # ------------------------------------------------------------
  # GenServer
  # ------------------------------------------------------------

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    PubSubAdapter.suscribir(@canal, self())
    {:ok, state}
  end

  # Cuando llega un anuncio desde PubSub → reenviar a todos los CLI
  def handle_info(%Message{} = mensaje, state) do
    for name <- :global.registered_names() do
      case name do
        {:cli_user, _id} ->
          if pid = :global.whereis_name(name) do
            send(pid, {:anuncio_global, mensaje})
          end

        _ -> :ok
      end
    end

    {:noreply, state}
  end
end

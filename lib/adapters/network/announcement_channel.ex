defmodule ProyectoFinalPrg3.Adapters.Network.AnnouncementChannel do
  @moduledoc """
  Canal global para la difusión de anuncios del sistema.

  Permite que la administración envíe mensajes que serán recibidos
  por todos los participantes suscritos al canal interno. Los anuncios
  se persisten igual que los mensajes de chat de equipos.

  - Se usa PubSub interno para comunicación.
  - Se utiliza `Message` del dominio para formato uniforme.
  - Se almacena historial en `ChatStore`.
  - Solo administradores pueden enviar anuncios.
  """

  use GenServer

  alias ProyectoFinalPrg3.Adapters.Security.SessionManager
  alias ProyectoFinalPrg3.Adapters.Persistence.ChatStore
  alias ProyectoFinalPrg3.Domain.Message
  alias ProyectoFinalPrg3.Adapters.Network.PubSubAdapter
  alias ProyectoFinalPrg3.Adapters.Network.ChannelManager
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  @canal :announcement_channel

  # ------------------------------------------------------------
  # API PÚBLICA
  # ------------------------------------------------------------

  @doc """
  Suscribe un proceso al canal global de anuncios.
  """
  def subscribe(pid \\ self()) do
    PubSubAdapter.suscribir(@canal, pid)
  end

  @doc """
  Envía un anuncio global al sistema.

  - Verifica que el usuario sea administrador.
  - Crea un Message con formato uniforme.
  - Persiste el anuncio en ChatStore.
  - Realiza broadcast a todos los suscriptores.

  ## Retorna:
    - `{:ok, mensaje}` si fue enviado correctamente.
    - `{:error, razón}` si falla la validación.
  """
  def announce(texto) when is_binary(texto) do
    contenido = String.trim(texto)

    cond do
      contenido == "" ->
        {:error, "El anuncio no puede estar vacío."}

      true ->
        enviar_anuncio_validado(contenido)
    end
  end

  # ------------------------------------------------------------
  # LÓGICA PRINCIPAL
  # ------------------------------------------------------------

  defp enviar_anuncio_validado(contenido) do
    with {:ok, usuario} <- SessionManager.obtener_participante_actual(),
         true <- usuario.rol == :admin do
      mensaje =
        Message.nuevo(
          UUID.uuid4(),
          # remitente_id
          "sistema",
          # canal lógico
          :canal_general,
          # contenido
          "📢 #{contenido}",
          DateTime.utc_now()
        )

      # Persistir anuncio igual que chats
      ChatStore.agregar_mensaje(@canal, mensaje)

      # Difundir a todos los suscriptores
      ChannelManager.broadcast(@canal, mensaje)

      # Log administrativo
      LoggerService.registrar_evento("Anuncio global enviado", %{
        admin: usuario.id,
        contenido: contenido
      })

      {:ok, mensaje}
    else
      false ->
        {:error, "No tienes permisos para enviar anuncios."}

      {:error, :no_sesion_activa} ->
        {:error, "Debes iniciar sesión para enviar anuncios."}
    end
  end

  # ------------------------------------------------------------
  # GEN_SERVER
  # ------------------------------------------------------------

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    # El propio proceso del canal también escucha anuncios
    PubSubAdapter.suscribir(@canal, self())
    {:ok, state}
  end

  @impl true
  def handle_info(%Message{} = mensaje, state) do
    for name <- :global.registered_names() do
      case name do
        {:cli_user, _id} ->
          if pid = :global.whereis_name(name) do
            send(pid, {:anuncio_global, mensaje})
          end

        _ ->
          :ok
      end
    end

    {:noreply, state}
  end
end

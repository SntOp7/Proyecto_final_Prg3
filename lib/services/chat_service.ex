defmodule ProyectoFinalPrg3.Services.ChatService do
  @moduledoc """
  Servicio principal de gestión del chat por equipos.
  """

  alias ProyectoFinalPrg3.Services.TeamManager
  alias ProyectoFinalPrg3.Adapters.Security.SessionManager
  alias ProyectoFinalPrg3.Services.{BroadcastService, ParticipantManager}
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService
  alias ProyectoFinalPrg3.Adapters.Persistence.ChatStore

  @tabla_chat_activo :chat_activo

  # ============================================================
  # INICIALIZACIÓN
  # ============================================================

  @doc """
  Asegura que la tabla ETS de chats activos existe.
  """
  def init_tabla do
    case :ets.whereis(@tabla_chat_activo) do
      :undefined ->
        :ets.new(@tabla_chat_activo, [:named_table, :public, read_concurrency: true])
        :ok

      _ ->
        :ok
    end
  end

  # ============================================================
  # INGRESO AL CHAT
  # ============================================================

  def ingresar_chat_equipo(nombre_equipo) when is_binary(nombre_equipo) do
    # Asegurar que existe
    init_tabla()

    with {:ok, participante} <- SessionManager.obtener_participante_actual(),
         {:ok, equipo} <- TeamManager.obtener_equipo(nombre_equipo),
         true <- participante.id in equipo.participantes do
      :ets.insert(@tabla_chat_activo, {participante.id, nombre_equipo})

      LoggerService.registrar_evento("Ingreso a chat", %{
        participante: participante.id,
        equipo: equipo.nombre
      })

      BroadcastService.notificar(:ingreso_chat, %{
        equipo: equipo.nombre,
        participante: participante.nombre
      })

      {:ok,
       """
       📱 Has ingresado al chat del equipo #{equipo.nombre}
       💬 Escribe tus mensajes directamente
       🚪 Usa /salir_chat para salir
       """}
    else
      {:error, :no_sesion_activa} ->
        {:error, "Debes iniciar sesión."}

      {:error, :no_encontrado} ->
        {:error, "El equipo '#{nombre_equipo}' no existe."}

      false ->
        {:error, "No perteneces a este equipo."}
    end
  end

  # ============================================================
  # ENVIAR MENSAJE
  # ============================================================

  def enviar_mensaje(contenido) do
    # Asegurar que existe
    init_tabla()

    with {:ok, participante} <- SessionManager.obtener_participante_actual(),
         {:ok, nombre_equipo} <- obtener_chat_activo(participante.id) do
      mensaje = %{
        id: UUID.uuid4(),
        autor_id: participante.id,
        autor_nombre: participante.nombre,
        contenido: contenido,
        timestamp: DateTime.utc_now(),
        tipo: :usuario
      }

      ChatStore.agregar_mensaje(nombre_equipo, mensaje)

      BroadcastService.notificar(:nuevo_mensaje, %{
        equipo: nombre_equipo,
        mensaje: mensaje
      })

      {:ok, "✅ Mensaje enviado"}
    else
      {:error, :sin_chat_activo} ->
        {:error, "No estás en ningún chat. Usa /chat equipo=NombreEquipo"}

      error ->
        error
    end
  end

  def enviar_mensaje_sistema(nombre_equipo, contenido) do
    mensaje = %{
      id: UUID.uuid4(),
      autor_id: "sistema",
      autor_nombre: "🤖 SISTEMA",
      contenido: contenido,
      timestamp: DateTime.utc_now(),
      tipo: :sistema
    }

    ChatStore.agregar_mensaje(nombre_equipo, mensaje)

    BroadcastService.notificar(:mensaje_sistema, %{
      equipo: nombre_equipo,
      mensaje: mensaje
    })

    {:ok, mensaje}
  end

  # ============================================================
  # SALIR DEL CHAT
  # ============================================================

  def salir_chat do
    # Asegurar que existe
    init_tabla()

    with {:ok, participante} <- SessionManager.obtener_participante_actual(),
         {:ok, nombre_equipo} <- obtener_chat_activo(participante.id) do
      :ets.delete(@tabla_chat_activo, participante.id)

      LoggerService.registrar_evento("Salida de chat", %{
        participante: participante.id,
        equipo: nombre_equipo
      })

      {:ok, "👋 Has salido del chat del equipo #{nombre_equipo}"}
    else
      {:error, :sin_chat_activo} ->
        {:error, "No estás en ningún chat activo."}

      error ->
        error
    end
  end

  @doc """
  Obtiene el historial de mensajes de un equipo.
  Requiere que el usuario pertenezca al equipo.
  """
  def obtener_historial(nombre_equipo, limite \\ 50) do
    with {:ok, participante} <- SessionManager.obtener_participante_actual(),
         {:ok, equipo} <- TeamManager.obtener_equipo(nombre_equipo),
         true <- participante.id in equipo.participantes do
      mensajes = ChatStore.obtener_mensajes(nombre_equipo, limite)
      {:ok, mensajes}
    else
      false -> {:error, "No perteneces a este equipo."}
      {:error, :no_sesion_activa} -> {:error, "Debes iniciar sesión."}
      error -> error
    end
  end

  # ============================================================
  # AUXILIARES
  # ============================================================

  defp obtener_chat_activo(participante_id) do
    # Asegurar que existe
    init_tabla()

    case :ets.lookup(@tabla_chat_activo, participante_id) do
      [{^participante_id, nombre_equipo}] -> {:ok, nombre_equipo}
      [] -> {:error, :sin_chat_activo}
    end
  end

  @doc """
  Obtiene el chat activo de un usuario.
  """
  def obtener_chat_activo_usuario(participante_id) do
    init_tabla()

    case :ets.lookup(@tabla_chat_activo, participante_id) do
      [{^participante_id, nombre_equipo}] -> {:ok, nombre_equipo}
      [] -> {:error, :sin_chat_activo}
    end
  end

  def chat_activo?(participante_id) do
    # Asegurar que existe
    init_tabla()

    case :ets.lookup(@tabla_chat_activo, participante_id) do
      [{^participante_id, _}] -> true
      [] -> false
    end
  end
end

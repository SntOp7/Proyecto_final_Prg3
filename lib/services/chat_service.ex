defmodule ProyectoFinalPrg3.Services.ChatService do
  @moduledoc """
  Servicio principal de gestión del chat por equipos.
  """

  use GenServer

  alias ProyectoFinalPrg3.Adapters.Persistence.ParticipantStore
  alias ProyectoFinalPrg3.Services.TeamManager
  alias ProyectoFinalPrg3.Adapters.Security.SessionManager
  alias ProyectoFinalPrg3.Services.BroadcastService
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService
  alias ProyectoFinalPrg3.Adapters.Persistence.ChatStore
  alias ProyectoFinalPrg3.Domain.Message
  alias ProyectoFinalPrg3.Utils.DateTimeHelper

  @tabla_chat_activo :chat_activo

  # -----------------------------------------
  # GEN SERVER
  # -----------------------------------------

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    # Solo inicializamos ChatStore UNA VEZ al iniciar el sistema
    ChatStore.init_store()
    {:ok, state}
  end

  # -----------------------------------------
  # INICIALIZACIÓN ETS LOCAL
  # -----------------------------------------

  def init_tabla do
    case :ets.whereis(@tabla_chat_activo) do
      :undefined ->
        :ets.new(@tabla_chat_activo, [:named_table, :public, read_concurrency: true])
      _ ->
        :ok
    end

    :ok
  end

  # -----------------------------------------
  # INGRESAR AL CHAT
  # -----------------------------------------

  def ingresar_chat_equipo(nombre_equipo) do
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
       📜 Usa /historial para ver mensajes anteriores
       🚪 Usa /salir_chat para salir
       """}
    else
      {:error, :no_sesion_activa} -> {:error, "Debes iniciar sesión."}
      {:error, :no_encontrado} -> {:error, "El equipo '#{nombre_equipo}' no existe."}
      false -> {:error, "No perteneces a este equipo."}
    end
  end

  # -----------------------------------------
  # ENVIAR MENSAJE
  # -----------------------------------------

  def enviar_mensaje(contenido) do
    init_tabla()

    contenido = String.trim(contenido)

    cond do
      contenido == "" ->
        {:error, "No puedes enviar mensajes vacíos."}

      String.length(contenido) > 1000 ->
        {:error, "El mensaje es demasiado largo (máximo 1000 caracteres)."}

      true ->
        enviar_mensaje_valido(contenido)
    end
  end

  defp enviar_mensaje_valido(contenido) do
    with {:ok, participante} <- SessionManager.obtener_participante_actual(),
         {:ok, nombre_equipo} <- obtener_chat_activo(participante.id) do

      mensaje = Message.nuevo(
        UUID.uuid4(),
        participante.id,
        nombre_equipo,
        contenido,
        DateTime.utc_now()
      )

      ChatStore.agregar_mensaje(nombre_equipo, mensaje)

      BroadcastService.notificar(:nuevo_mensaje, %{
        equipo: nombre_equipo,
        autor: participante.nombre,
        mensaje: contenido,
        timestamp: mensaje.timestamp
      })

      {:ok, "✅"}
    else
      {:error, :sin_chat_activo} ->
        {:error, "No estás en ningún chat. Usa /chat equipo=NombreEquipo"}
      error ->
        error
    end
  end

  # -----------------------------------------
  # MENSAJE DEL SISTEMA
  # -----------------------------------------

  def enviar_mensaje_sistema(nombre_equipo, contenido) do
    contenido = String.trim(contenido)

    if contenido == "" do
      {:error, "No se puede enviar un mensaje vacío."}
    else
      mensaje = Message.nuevo(
        UUID.uuid4(),
        "sistema",
        nombre_equipo,
        "🤖 #{contenido}",
        DateTime.utc_now()
      )

      ChatStore.agregar_mensaje(nombre_equipo, mensaje)

      BroadcastService.notificar(:mensaje_sistema, %{
        equipo: nombre_equipo,
        mensaje: contenido
      })

      {:ok, mensaje}
    end
  end

  # -----------------------------------------
  # SALIR DEL CHAT
  # -----------------------------------------

  def salir_chat do
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
      {:error, :sin_chat_activo} -> {:error, "No estás en ningún chat activo."}
      error -> error
    end
  end

  # -----------------------------------------
  # HISTORIAL
  # -----------------------------------------

  def obtener_historial(nombre_equipo, limite \\ 50) do
    with {:ok, participante} <- SessionManager.obtener_participante_actual(),
         {:ok, equipo} <- TeamManager.obtener_equipo(nombre_equipo),
         true <- participante.id in equipo.participantes do

      mensajes = ChatStore.obtener_mensajes(nombre_equipo, limite)

      if mensajes == [] do
        {:ok, "📭 No hay mensajes en este chat aún."}
      else
        texto = formatear_historial(mensajes)
        {:ok, "\n📜 Historial del chat #{nombre_equipo}:\n#{texto}"}
      end
    else
      false -> {:error, "No perteneces a este equipo."}
      {:error, :no_sesion_activa} -> {:error, "Debes iniciar sesión."}
      error -> error
    end
  end

  defp formatear_historial(mensajes) do
    mensajes
    |> Enum.map(fn msg ->
      nombre = obtener_nombre_autor(msg.remitente_id)
      ts = DateTimeHelper.formato_chat(msg.timestamp)
      "[#{ts}] #{nombre}: #{msg.contenido}"
    end)
    |> Enum.join("\n")
  end

  defp obtener_nombre_autor("sistema"), do: "🤖 Sistema"

  defp obtener_nombre_autor(id) do
    case ParticipantStore.obtener_participante(id) do
      {:ok, p} -> p.nombre
      _ -> "Usuario"
    end
  end

  # -----------------------------------------
  # AUXILIARES
  # -----------------------------------------

  defp obtener_chat_activo(participante_id) do
    init_tabla()
    case :ets.lookup(@tabla_chat_activo, participante_id) do
      [{^participante_id, equipo}] -> {:ok, equipo}
      [] -> {:error, :sin_chat_activo}
    end
  end

  def obtener_chat_activo_usuario(id), do: obtener_chat_activo(id)

  def chat_activo?(id) do
    init_tabla()
    case :ets.lookup(@tabla_chat_activo, id) do
      [{^id, _}] -> true
      _ -> false
    end
  end
end

defmodule ProyectoFinalPrg3.Adapters.CLI.CommandExecutor do
  @moduledoc """
  Adaptador responsable de ejecutar comandos provenientes del CLI.
  """

  alias ProyectoFinalPrg3.Adapters.Network.AnnouncementChannel
  alias ProyectoFinalPrg3.Adapters.Security.SessionManager
  alias ProyectoFinalPrg3.Adapters.Persistence.ChatStore

  @command_service Application.compile_env(
                     :proyecto_final_prg3,
                     :command_service,
                     ProyectoFinalPrg3.Services.CommandService
                   )

  @logger_service Application.compile_env(
                    :proyecto_final_prg3,
                    :logger_service,
                    ProyectoFinalPrg3.Adapters.Logging.LoggerService
                  )

  # ============================================================
  # EJECUCIÓN PRINCIPAL
  # ============================================================

  # ---------------------------------------------
  # 🔵 1. /announcement (solo administradores)
  # ---------------------------------------------
  def execute(%{name: :announcement}, args) do
    with {:ok, usuario} <- SessionManager.obtener_participante_actual(),
         mensaje when is_binary(mensaje) <- Map.get(args, "mensaje") do

      AnnouncementChannel.publish_remote(mensaje, usuario)

    else
      _ -> {:error, "Debes enviar un mensaje válido para el anuncio."}
    end
  end

  # ---------------------------------------------
  # 🟣 2. /announcements (ver historial)
  # ---------------------------------------------
  def execute(%{name: :announcements}, _args) do
    historial = ChatStore.obtener_mensajes(:canal_anuncios_globales, 50)

    case historial do
      [] -> {:ok, "📭 No hay anuncios globales registrados."}
      _  -> {:ok, historial}
    end
  end

  # ---------------------------------------------
  # 🟢 3. Cualquier otro comando → CommandService
  # ---------------------------------------------
  def execute(info, args) when is_map(info) and is_map(args) do
    try do
      @logger_service.registrar_evento("Ejecución CLI", %{comando: info, args: args})
      @command_service.ejecutar_comando(info, args)
    rescue
      error ->
        @logger_service.registrar_evento("Error en ejecución CLI", %{
          comando: info,
          error: Exception.message(error)
        })

        {:error, "Error al ejecutar el comando: #{Exception.message(error)}"}
    end
  end

  def execute(_, _), do: {:error, "Formato inválido de comando o argumentos."}
end

defmodule ProyectoFinalPrg3.Adapters.CLI.CommandExecutor do
  @moduledoc """
  Adaptador responsable de ejecutar comandos provenientes del CLI.
  """

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

  def execute(info, args) when is_map(info) and is_list(args) do
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

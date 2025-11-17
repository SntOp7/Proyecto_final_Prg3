defmodule ProyectoFinalPrg3.Adapters.CLI.CommandExecutor do
  @moduledoc """
  Adaptador responsable de ejecutar comandos provenientes del CLI.
  Este módulo actúa como intermediario entre la interfaz de línea de comandos
  y el servicio de comandos del sistema.
  Proporciona una función `execute/2` que recibe la información del comando
  y sus argumentos, delegando la ejecución al `CommandService`.
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
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

  @doc """
  Función principal para ejecutar comandos CLI.
  Parámetros:
    - `info`: Mapa con información del comando a ejecutar.
    - `args`: Mapa con los argumentos del comando.
  Retorna:
    - `{:ok, resultado}` si la ejecución fue exitosa.
    - `{:error, mensaje}` en caso de error.
  """
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

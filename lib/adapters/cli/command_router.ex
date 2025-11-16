defmodule ProyectoFinalPrg3.Adapters.CLI.CommandRouter do
  @moduledoc """
  Módulo responsable de enrutar y ejecutar los comandos ingresados en la CLI.
  """

  alias ProyectoFinalPrg3.Adapters.CLI.{CommandRegistry, CommandExecutor}
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService
  alias ProyectoFinalPrg3.Services.PermissionService
  alias ProyectoFinalPrg3.Adapters.Security.SessionManager

  # ============================================================
  # INYECCIÓN DE DEPENDENCIA DEL PARSER
  # ============================================================

  @parser Application.compile_env(
            :proyecto_final_prg3,
            :command_parser,
            ProyectoFinalPrg3.Adapters.CLI.CommandParser
          )

  # ============================================================
  # FUNCIÓN PRINCIPAL
  # ============================================================

  def route(input) when is_binary(input) do
    case String.trim(input) do
      "" ->
        {:error, "No se ingresó ningún comando. Usa /help para ver las opciones disponibles."}

      _ ->
        case @parser.parse(input) do
          %{command: cmd, args: args} ->
            with {:ok, command_info} <- CommandRegistry.get(cmd),
                 {:ok, id_usuario} <- SessionManager.obtener_participante_actual(),
                 true <- validar_permiso(id_usuario, command_info) do
              ejecutar_comando(cmd, args, command_info)
            else
              false ->
                {:error, "Acceso denegado. No tienes permisos para ejecutar este comando."}

              {:error, :no_usuario_autenticado} ->
                {:error, "Debes iniciar sesión para ejecutar comandos."}

              _ ->
                {:error, "Comando no reconocido. Usa /help para ver las opciones disponibles."}
            end

          _ ->
            {:error, "Formato inválido. Usa /help para ver los comandos válidos."}
        end
    end
  end

  def route(_),
    do: {:error, "Entrada inválida. El comando debe ser texto."}

  # ============================================================
  # PERMISOS
  # ============================================================

  defp validar_permiso(id_usuario, %{required_permission: permiso}) when is_atom(permiso) do
    PermissionService.autorizado?(id_usuario, permiso)
  end

  defp validar_permiso(_id_usuario, _), do: true

  # ============================================================
  # EJECUCIÓN DEL COMANDO
  # ============================================================

  defp ejecutar_comando(cmd, args, command_info) do
    try do
      LoggerService.registrar_evento("Ejecución de comando", %{comando: cmd, argumentos: args})
      CommandExecutor.execute(command_info, args)
    rescue
      error ->
        LoggerService.registrar_evento("Error en comando", %{
          comando: cmd,
          error: Exception.message(error)
        })

        {:error, "Ocurrió un error al ejecutar el comando #{cmd}: #{Exception.message(error)}"}
    end
  end
end

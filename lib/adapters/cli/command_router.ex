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
          {:ok, %{command: raw_cmd, args: args}} ->
            cmd = String.trim(raw_cmd)

            with {:ok, command_info} <- CommandRegistry.get(cmd),
                 :ok <- verificar_acceso(command_info),
                 :ok <- verificar_permiso(command_info) do
              ejecutar_comando(cmd, args, command_info)
            else
              {:error, mensaje} ->
                {:error, mensaje}

              _ ->
                {:error, "Comando no reconocido. Usa /help para ver las opciones disponibles."}
            end

          {:error, _} ->
            {:error, "Formato inválido. Usa /help para ver los comandos válidos."}
        end
    end
  end

  def route(_),
    do: {:error, "Entrada inválida. El comando debe ser texto."}

  # ============================================================
  # ACCESO SEGÚN SESIÓN
  # ============================================================

  # Comandos públicos: no requieren sesión
  defp es_publico?(%{required_permission: nil}), do: true
  defp es_publico?(_), do: false

  defp verificar_acceso(command_info) do
    usuario = SessionManager.obtener_participante_actual()

    cond do
      es_publico?(command_info) ->
        :ok

      SessionManager.sesion_activa?(usuario.id) ->
        :ok

      true ->
        {:error, "Debes iniciar sesión para ejecutar este comando."}
    end
  end

  # ============================================================
  # VERIFICACIÓN DE PERMISOS POR ROL
  # ============================================================

  defp verificar_permiso(%{required_permission: nil}), do: :ok

  defp verificar_permiso(%{required_permission: permiso}) do
    case SessionManager.obtener_participante_actual() do
      {:ok, id_usuario} ->
        case PermissionService.autorizado?(id_usuario, permiso) do
          true -> :ok
          false -> {:error, "Acceso denegado. No tienes permisos para ejecutar este comando."}
        end

      {:error, :no_usuario_autenticado} ->
        {:error, "Debes iniciar sesión para ejecutar este comando."}
    end
  end

  # ============================================================
  # EJECUCIÓN DEL COMANDO
  # ============================================================

  defp ejecutar_comando(cmd, args, command_info) do
    try do
      LoggerService.registrar_evento("Ejecución de comando", %{comando: cmd, args: args})
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

defmodule ProyectoFinalPrg3.Adapters.CLI.CommandRouter do
  @moduledoc """
  Módulo responsable de enrutar y ejecutar los comandos ingresados en la CLI.
  Este adaptador recibe la entrada del usuario, valida el comando,
  verifica permisos y delega la ejecución al `CommandExecutor`.
  Ejemplo de uso:
      iex> CommandRouter.route("/help")
      {:ok, "Comandos disponibles: ..."}
  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
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

  @doc """
  Función principal para enrutar y ejecutar comandos CLI.
  Parámetros:
    - `input`: Línea de comando ingresada por el usuario.
  Retorna:
    - `{:ok, resultado}` si la ejecución fue exitosa.
    - `{:error, mensaje}` en caso de error.
  """
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
  @doc false
  defp es_publico?(%{required_permission: nil}), do: true
  defp es_publico?(_), do: false

  @doc false
  defp verificar_acceso(command_info) do
  if es_publico?(command_info) do
    :ok
  else
    case SessionManager.obtener_participante_actual() do
      {:ok, _participante} ->
        :ok

      {:error, _} ->
        {:error, "Debes iniciar sesión para ejecutar este comando."}
    end
  end
end

  # ============================================================
  # VERIFICACIÓN DE PERMISOS POR ROL
  # ============================================================

  @doc false
  defp verificar_permiso(%{required_permission: nil}), do: :ok

  defp verificar_permiso(%{required_permission: permiso}) do
    case SessionManager.obtener_participante_actual() do
      {:ok, participante} ->
        case PermissionService.autorizado?(participante.id, permiso) do
          true -> :ok
          false -> {:error, "Acceso denegado. No tienes permisos para ejecutar este comando."}
        end

      {:error, _} ->
        {:error, "Debes iniciar sesión para ejecutar este comando."}
    end
  end

  # ============================================================
  # EJECUCIÓN DEL COMANDO
  # ============================================================

  @doc false
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

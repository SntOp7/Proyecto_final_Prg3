defmodule ProyectoFinalPrg3.Adapters.CLI.CommandRouter do
  alias ProyectoFinalPrg3.Adapters.CLI.{CommandRegistry, CommandExecutor}
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService
  alias ProyectoFinalPrg3.Services.PermissionService
  alias ProyectoFinalPrg3.Adapters.Security.SessionManager

  @parser Application.compile_env(
            :proyecto_final_prg3,
            :command_parser,
            ProyectoFinalPrg3.Adapters.CLI.CommandParser
          )

  # ============================================================
  # FUNCIÓN PRINCIPAL
  # ============================================================

  def route(input) when is_binary(input) do
    case @parser.parse(input) do
      {:ok, %{command: raw_cmd, args: args}} ->
        cmd = String.trim(raw_cmd)

        with {:ok, info} <- CommandRegistry.get(cmd),
             :ok <- verificar_acceso(info),
             :ok <- verificar_permiso(info) do
          ejecutar_comando(cmd, args, info)
        else
          {:error, m} -> {:error, m}
        end

      {:error, _} ->
        {:error, "Formato inválido. Usa /help para ver los comandos válidos."}
    end
  end

  # Sin sesión → error
  def route(_),
    do: {:error, "Entrada inválida."}

  # ============================================================
  # SESIÓN
  # ============================================================

  defp es_publico?(%{required_permission: nil}), do: true
  defp es_publico?(_), do: false

  defp verificar_acceso(info) do
    if es_publico?(info) do
      :ok
    else
      case SessionManager.obtener_participante_actual() do
        {:ok, _} -> :ok
        _ -> {:error, "Debes iniciar sesión para ejecutar este comando."}
      end
    end
  end

  # ============================================================
  # PERMISOS POR ROL
  # ============================================================

  defp verificar_permiso(%{required_permission: nil}), do: :ok

  defp verificar_permiso(%{required_permission: permiso}) do
    with {:ok, user} <- SessionManager.obtener_participante_actual() do
      if PermissionService.autorizado?(user.id, permiso),
        do: :ok,
        else: {:error, "Acceso denegado. No tienes permisos."}
    else
      _ -> {:error, "Debes iniciar sesión."}
    end
  end

  # ============================================================
  # EJECUCIÓN DEL COMANDO
  # ============================================================

  defp ejecutar_comando(cmd, args, info) do
    try do
      LoggerService.registrar_evento("Ejecución de comando", %{comando: cmd})
      CommandExecutor.execute(info, args)
    rescue
      e ->
        {:error, Exception.message(e)}
    end
  end
end

defmodule ProyectoFinalPrg3.Adapters.CLI.CommandRouter do
  @moduledoc """
  Módulo responsable de **enrutar y ejecutar los comandos ingresados por el usuario** a través de la interfaz CLI.

  Este componente forma parte de la capa **Adapters/CLI** dentro de la arquitectura hexagonal,
  y se encarga de coordinar la interpretación, validación de permisos y ejecución de comandos del sistema.

  ## Funcionalidad principal
  1. Recibe el texto del comando ingresado por el usuario (`input`).
  2. Usa `CommandParser` para analizarlo y extraer el comando y sus argumentos.
  3. Consulta `CommandRegistry` para obtener la información asociada al comando.
  4. Valida si el usuario autenticado tiene permisos para ejecutarlo, mediante `PermissionService`.
  5. Si pasa la validación, delega la ejecución al `CommandExecutor`.
  6. Registra todos los eventos y errores con `LoggerService`.

  ## Integraciones
  - `CommandParser`: analiza la estructura del texto ingresado.
  - `CommandRegistry`: define los comandos disponibles y sus permisos.
  - `PermissionService`: valida que el usuario tenga autorización.
  - `SessionManager`: obtiene la sesión del usuario actual.
  - `CommandExecutor`: ejecuta la acción del comando.
  - `LoggerService`: registra la actividad y errores en logs.

  ## Ejemplos
      iex> CommandRouter.route("/teams")
      {:ok, "Listado de equipos mostrado correctamente"}

      iex> CommandRouter.route("/create_team Innovadores")
      {:error, "Acceso denegado. No tienes permisos para ejecutar este comando."}

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-27
  Última modificación: 2025-11-03
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Adapters.CLI.{CommandRegistry, CommandExecutor, CommandParser}
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService
  alias ProyectoFinalPrg3.Services.PermissionService
  alias ProyectoFinalPrg3.Adapters.Security.SessionManager

  # ============================================================
  # FUNCIÓN PRINCIPAL DE ENRUTAMIENTO
  # ============================================================

  @doc """
  Procesa y ejecuta un comando ingresado en la CLI, verificando antes que el usuario
  tenga permisos suficientes para realizar la acción.

  ## Parámetros:
    - `input` (`String`): texto completo ingresado por el usuario.

  ## Flujo:
  1. Valida que el comando no esté vacío.
  2. Usa `CommandParser` para obtener el comando (`cmd`) y sus argumentos (`args`).
  3. Busca la definición del comando en `CommandRegistry`.
  4. Obtiene el usuario actual mediante `SessionManager`.
  5. Verifica los permisos requeridos con `PermissionService`.
  6. Si todo es correcto, ejecuta el comando con `CommandExecutor`.

  ## Retorna:
    - `{:ok, resultado}` si el comando se ejecuta correctamente.
    - `{:error, mensaje}` si ocurre un error, el comando no existe o no hay permisos.
  """
  def route(input) when is_binary(input) do
    case String.trim(input) do
      "" ->
        {:error, "No se ingresó ningún comando. Usa /help para ver las opciones disponibles."}

      _ ->
        case CommandParser.parse(input) do
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

  def route(_), do: {:error, "Entrada inválida. El comando debe ser texto."}

  # ============================================================
  # FUNCIONES PRIVADAS AUXILIARES
  # ============================================================

  @doc false
  # Valida si el usuario tiene permiso explícito para ejecutar un comando.
  defp validar_permiso(id_usuario, %{required_permission: permiso}) when is_atom(permiso) do
    PermissionService.autorizado?(id_usuario, permiso)
  end

  @doc false
  # Si el comando no define permisos explícitos, se considera público.
  defp validar_permiso(_id_usuario, _), do: true

  @doc false
  # Ejecuta el comando y registra el resultado o error en el LoggerService.
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

defmodule ProyectoFinalPrg3.Adapters.CLI.CommandRouter do
  @moduledoc """
  Módulo responsable de enrutar los comandos ingresados por el usuario a través de la interfaz CLI.

  Este adaptador forma parte de la capa **Adapters/CLI** dentro de la arquitectura hexagonal,
  encargándose de traducir los comandos en texto a acciones ejecutables por el sistema.

  ## Funcionalidad principal
  - Recibe el texto ingresado por el usuario (`input`).
  - Usa `CommandParser` para extraer el comando y sus argumentos.
  - Verifica si el comando existe en el registro (`CommandRegistry`).
  - Si existe, delega su ejecución al `CommandExecutor`.

  ## Ejemplo
      iex> CommandRouter.route("/team create Innovadores")
      {:ok, "Equipo 'Innovadores' creado con éxito"}

  ## Integraciones
  - `CommandParser`: analiza el texto y separa el comando de sus argumentos.
  - `CommandRegistry`: mantiene el listado de comandos válidos.
  - `CommandExecutor`: ejecuta el comando asociado.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Adapters.CLI.{CommandRegistry, CommandExecutor, CommandParser}
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  @doc """
  Recibe el texto ingresado por el usuario, lo analiza e invoca la acción correspondiente.

  Retorna:
    - `{:ok, resultado}` si el comando fue ejecutado correctamente.
    - `{:error, mensaje}` si el comando no existe o se produjo un error durante la ejecución.
  """
  def route(input) when is_binary(input) do
    case String.trim(input) do
      "" ->
        {:error, "No se ingresó ningún comando. Usa /help para ver las opciones disponibles."}

      _ ->
        with %{command: cmd, args: args} <- CommandParser.parse(input),
          {:ok, command_info} <- CommandRegistry.get(cmd) do
          try do
            LoggerService.registrar_evento("Ejecución de comando", %{comando: cmd, argumentos: args})
            CommandExecutor.execute(command_info, args)
          rescue
            error ->
              LoggerService.registrar_evento("Error en comando", %{comando: cmd, error: Exception.message(error)})
              {:error, "Ocurrió un error al ejecutar el comando #{cmd}: #{Exception.message(error)}"}
          end
        else
          nil ->
            {:error, "Comando no reconocido. Usa /help para ver las opciones."}
        end
    end
  end

  def route(_), do: {:error, "Entrada inválida. El comando debe ser un texto."}
end

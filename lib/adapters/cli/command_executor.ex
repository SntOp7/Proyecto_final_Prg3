defmodule ProyectoFinalPrg3.Adapters.CLI.CommandExecutor do
  @moduledoc """
  Adaptador responsable de ejecutar los comandos ya validados por el `CommandRouter`.

  Este módulo sirve como punto de unión entre la capa de entrada (CLI)
  y la capa de servicios (`CommandService`), encargándose de invocar
  la función correspondiente dentro de la lógica de aplicación.

  ## Flujo general
  1. El usuario ingresa un comando por CLI.
  2. `CommandRouter` lo analiza y busca su definición en `CommandRegistry`.
  3. `CommandExecutor` recibe la información del comando (`info`) y los argumentos (`args`).
  4. Llama a `CommandService.ejecutar_comando/2`, que gestiona la lógica real.

  ## Ejemplo
      iex> CommandExecutor.execute(%{nombre: "team_create"}, ["Innovadores"])
      {:ok, "Equipo 'Innovadores' creado correctamente."}

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Services.CommandService
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # ============================================================
  # EJECUCIÓN PRINCIPAL DE COMANDOS
  # ============================================================

  @doc """
  Ejecuta el comando recibido, enviando la información al `CommandService`.

  ## Parámetros
    - `info`: mapa con los metadatos del comando (por ejemplo, nombre, descripción, alias).
    - `args`: lista con los argumentos recibidos desde la línea de comandos.

  ## Retorna
    - `{:ok, resultado}` si el comando fue ejecutado correctamente.
    - `{:error, razon}` si ocurre algún error durante la ejecución.
  """
  def execute(info, args) when is_map(info) and is_list(args) do
    try do
      LoggerService.registrar_evento("Ejecución CLI", %{comando: info, args: args})
      CommandService.ejecutar_comando(info, args)
    rescue
      error ->
        LoggerService.registrar_evento("Error en ejecución CLI", %{
          comando: info,
          error: Exception.message(error)
        })

        {:error, "Error al ejecutar el comando: #{Exception.message(error)}"}
    end
  end

  def execute(_, _), do: {:error, "Formato inválido de comando o argumentos."}
end

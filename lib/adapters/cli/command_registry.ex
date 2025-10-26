defmodule ProyectoFinalPrg3.Adapters.CLI.CommandRegistry do
  @moduledoc """
  Registro centralizado de comandos disponibles en la interfaz de línea de comandos (CLI).

  Este módulo define y expone los comandos del sistema, junto con su descripción,
  el servicio asociado y la acción que debe ejecutarse. Sirve como punto de referencia
  para el `CommandRouter` o el `CommandExecutor`, permitiendo interpretar las órdenes
  del usuario en la terminal.

  Cada comando tiene la siguiente estructura:

      "/comando" => %{
        description: "Descripción del comando",
        service: :nombre_del_servicio,
        action: :accion_a_ejecutar
      }

  Ejemplo de uso:

      iex> CommandRegistry.get("/teams")
      %{description: "Listar equipos registrados", service: :team_manager, action: :list_teams}

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-26
  Licencia: GNU GPLv3
  """

  @commands %{
    "/teams" => %{
      description: "Listar equipos registrados",
      service: :team_manager,
      action: :list_teams
    },
    "/project" => %{
      description: "Mostrar info del proyecto de un equipo",
      service: :project_manager,
      action: :show_project
    },
    "/join" => %{
      description: "Unirse a un equipo existente",
      service: :team_manager,
      action: :join_team
    },
    "/chat" => %{
      description: "Entrar al canal de chat de un equipo",
      service: :chat_manager,
      action: :open_chat
    },
    "/help" => %{
      description: "Mostrar comandos disponibles y su descripción",
      service: :command_service,
      action: :show_help
    }
  }

  # ============================================================
  # FUNCIONES DE ACCESO A COMANDOS
  # ============================================================

  @doc """
  Retorna el mapa completo de comandos registrados en el sistema.

  ## Ejemplo:
      iex> CommandRegistry.all()
      %{"/teams" => %{description: ..., service: ..., action: ...}, ...}
  """
  def all, do: @commands

  @doc """
  Obtiene la información asociada a un comando específico.

  ## Parámetros:
    - `command`: cadena que representa el comando (por ejemplo, "/teams").

  ## Ejemplo:
      iex> CommandRegistry.get("/join")
      %{description: "Unirse a un equipo existente", service: :team_manager, action: :join_team}

  Si el comando no existe, retorna `{:error, :comando_no_encontrado}`.
  """
  def get(command) do
    case Map.get(@commands, command) do
      nil -> {:error, :comando_no_encontrado}
      data -> {:ok, data}
    end
  end
end

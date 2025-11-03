defmodule ProyectoFinalPrg3.Adapters.CLI.CommandRegistry do
  @moduledoc """
  Registro centralizado de comandos disponibles en la interfaz de línea de comandos (CLI).

  Define cada comando con su descripción, servicio asociado, acción a ejecutar y, si aplica,
  el permiso requerido según `PermissionService`.

  Este módulo es utilizado por:
  - `CommandRouter` → para validar permisos y enrutar comandos.
  - `CommandExecutor` → para ejecutar la acción correspondiente.

  ## Estructura de un comando
      "/comando" => %{
        description: "Descripción del comando",
        service: :nombre_del_servicio,
        action: :accion_a_ejecutar,
        required_permission: :permiso_opcional
      }

  Si `required_permission` no está definido, el comando se considera público.

  ## Ejemplo
      iex> CommandRegistry.get("/teams")
      {:ok, %{description: "Listar equipos", service: :team_manager, action: :list_teams}}

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-26
  Última modificación: 2025-11-03
  Licencia: GNU GPLv3
  """

  @commands %{
    "/teams" => %{
      description: "Listar equipos registrados",
      service: :team_manager,
      action: :list_teams,
      required_permission: :ver_equipos
    },
    "/project" => %{
      description: "Mostrar información del proyecto de un equipo",
      service: :project_manager,
      action: :show_project,
      required_permission: :ver_proyectos
    },
    "/join" => %{
      description: "Unirse a un equipo existente",
      service: :team_manager,
      action: :join_team,
      required_permission: :unirse_equipo
    },
    "/chat" => %{
      description: "Entrar al canal de chat de un equipo",
      service: :chat_manager,
      action: :open_chat,
      required_permission: :ver_canales
    },
    "/create_team" => %{
      description: "Crear un nuevo equipo en el sistema",
      service: :team_manager,
      action: :crear_equipo,
      required_permission: :crear_equipo
    },
    "/assign_mentor" => %{
      description: "Asignar un mentor a un equipo",
      service: :team_manager,
      action: :asignar_mentor,
      required_permission: :asignar_mentor
    },
    "/help" => %{
      description: "Mostrar comandos disponibles y su descripción",
      service: :command_service,
      action: :show_help
      # Sin permiso → público
    }
  }

  # ============================================================
  # FUNCIONES DE ACCESO A COMANDOS
  # ============================================================

  @doc """
  Retorna el mapa completo de comandos registrados.
  """
  def all, do: @commands

  @doc """
  Obtiene la información de un comando específico.

  Retorna `{:ok, info}` si existe, o `{:error, :comando_no_encontrado}` en caso contrario.
  """
  def get(command) do
    case Map.get(@commands, command) do
      nil -> {:error, :comando_no_encontrado}
      data -> {:ok, data}
    end
  end
end

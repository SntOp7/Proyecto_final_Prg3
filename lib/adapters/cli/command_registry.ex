defmodule ProyectoFinalPrg3.Adapters.CLI.CommandRegistry do
  @moduledoc """
  Registro centralizado de comandos disponibles en la CLI.
  """

  @behaviour ProyectoFinalPrg3.Adapters.CLI.CommandRegistryBehaviour

  @commands %{
    # ============================================================
    # COMANDOS PÚBLICOS (no requieren sesión)
    # ============================================================

    "/help" => %{
      description: "Mostrar comandos disponibles",
      usage: "/help",
      service: :command_service,
      action: :show_help,
      required_permission: nil
    },

    "/register" => %{
      description: "Registrar un nuevo usuario",
      usage: "/register nombre=JuanJose correo=juan@gmail.com username=JuanJo123 rol=participante/mentor exp=3",
      service: :auth_service,
      action: :register,
      required_permission: nil
    },

    "/login" => %{
      description: "Iniciar sesión",
      usage: "/login correo=juan@gmail.com contrasenia=1234",
      service: :auth_service,
      action: :login,
      required_permission: nil
    },

    # ============================================================
    # COMANDOS QUE REQUIEREN SESIÓN, PERO NO PERMISOS
    # ============================================================

    "/logout" => %{
      description: "Cerrar sesión",
      usage: "/logout",
      service: :auth_service,
      action: :logout,
      required_permission: nil
    },

    # ============================================================
    # COMANDOS PERMITIDOS A PARTICIPANTES
    # ============================================================

    "/teams" => %{
      description: "Listar equipos registrados",
      usage: "/teams",
      service: :team_manager,
      action: :list_teams,
      required_permission: :ver_equipos
    },

    "/project" => %{
      description: "Ver información del proyecto de un equipo",
      usage: "/project equipo=Titanes",
      service: :project_manager,
      action: :show_project,
      required_permission: :ver_proyecto
    },

    "/join" => %{
      description: "Unirse a un equipo existente",
      usage: "/join equipo=Titanes",
      service: :team_manager,
      action: :join_team,
      required_permission: :unirse_equipo
    },

    "/create_team" => %{
      description: "Crear un equipo nuevo",
      usage: "/create_team nombre=Titanes categoria=web descripcion=\"Equipo de dev\"",
      service: :team_manager,
      action: :create_team,
      required_permission: :crear_equipo
    },

    "/chat" => %{
      description: "Entrar al chat de un equipo",
      usage: "/chat equipo=Titanes",
      service: :chat_manager,
      action: :open_chat,
      required_permission: :ver_canales
    },

    # ============================================================
    # COMANDOS EXCLUSIVOS PARA MENTORES
    # ============================================================

    "/feedback" => %{
      description: "Enviar feedback a un equipo",
      usage: "/feedback equipo=Titanes mensaje=\"Buen trabajo, pero mejoren documentación\"",
      service: :mentor_manager,
      action: :feedback,
      required_permission: :enviar_feedback
    },

    # ============================================================
    # COMANDOS EXCLUSIVOS PARA ADMINISTRADORES
    # ============================================================

    "/assign_mentor" => %{
      description: "Asignar un mentor a un equipo",
      usage: "/assign_mentor equipo=Titanes id_mentor=MENTOR123",
      service: :admin_manager,
      action: :assign_mentor,
      required_permission: :asignar_mentor
    },

    "/delete_team" => %{
      description: "Eliminar un equipo del sistema",
      usage: "/delete_team id_equipo=Titanes",
      service: :admin_manager,
      action: :delete_team,
      required_permission: :eliminar_equipo
    }
  }

  # ============================================================
  # FUNCIONES DE ACCESO
  # ============================================================

  def all, do: @commands

  def get(command) do
    case Map.get(@commands, command) do
      nil -> {:error, :comando_no_encontrado}
      info -> {:ok, info}
    end
  end
end

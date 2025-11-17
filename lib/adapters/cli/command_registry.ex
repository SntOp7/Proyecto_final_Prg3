defmodule ProyectoFinalPrg3.Adapters.CLI.CommandRegistry do
  @moduledoc """
  Registro centralizado de comandos disponibles en la CLI.
  Cada comando está asociado con su descripción, uso, servicio manejador,
  acción a ejecutar y permisos requeridos.
  Comandos Incluidos:
    - `/help`
    - `/register`
    - `/login`
    - `/logout`
    - `/teams`
    - `/project`
    - `/join`
    - `/create_team`
    - `/create_project`
    - `/chat`
    - `/feedback`
    - `/assign_mentor`
    - `/delete_team`
  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

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
      usage:
        "/register nombre=JuanJose correo=juan@gmail.com username=JuanJo123 contrasenia=123 rol=participante/mentor",
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
    "/create_project" => %{
      description: "Crear un proyecto nuevo",
      usage:
        "/create_project nombre=Titanes descripcion=\"Equipo de dev\", categoria=web , equipo=Titanes",
      service: :project_manager,
      action: :create_project,
      required_permission: :crear_proyecto
    },

    # ============================================================
    # COMANDOS EXCLUSIVOS PARA MENTORES
    # ============================================================

    "/feedback" => %{
      description: "Enviar feedback a un equipo",
      usage: "/feedback proyecto=Titanes mensaje=\"Buen trabajo, pero mejoren documentación\"",
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
    },
    "/announcement" => %{
      description: "Enviar un anuncio global visible para todos los participantes",
      usage: "/announcement mensaje=\"La hackathon inicia en 10 minutos\"",
      service: :announcement,
      action: :send,
      required_permission: :enviar_anuncio
    },

    # ============================================================
    # CHAT
    # ============================================================

    "/chat" => %{
      description: "Entrar al chat de un equipo",
      usage: "/chat equipo=Innovadores",
      service: :chat_manager,
      action: :open_chat,
      required_permission: :ver_canales
    },
    "/salir_chat" => %{
  description: "Salir del chat activo",
  usage: "/salir_chat",
  service: :chat_manager,
  action: :leave_chat,
  required_permission: nil,
  context: :solo_en_chat
},
"/historial" => %{
  description: "Ver historial de mensajes del chat activo",
  usage: "/historial",
  service: :chat_manager,
  action: :show_history,
  required_permission: nil,
  context: :solo_en_chat
},
    "/progress" => %{
      description: "Registrar un avance en el proyecto",
      usage:
        "/progress proyecto=\"Mi Proyecto\" titulo=\"Implementación API\" descripcion=\"Se completó la API REST\" version=1.0",
      service: :progress_manager,
      action: :add_progress,
      required_permission: :crear_proyecto
    },
    "/avances" => %{
      description: "Ver avances de un proyecto",
      usage: "/avances proyecto=\"Mi Proyecto\"",
      service: :progress_manager,
      action: :list_progress,
      required_permission: :ver_proyecto
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

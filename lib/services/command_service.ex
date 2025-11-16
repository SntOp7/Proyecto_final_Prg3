defmodule ProyectoFinalPrg3.Services.CommandService do
  @moduledoc """
  Intérprete central de comandos CLI.
  """

  alias ProyectoFinalPrg3.Services.{
    AuthService,
    TeamManager,
    ProjectManager,
    ChatService,
    MentorManager,
    ParticipantManager,
    PermissionService
  }

  alias ProyectoFinalPrg3.Adapters.Security.SessionManager
  alias ProyectoFinalPrg3.Adapters.CLI.CommandRegistry

  # ===================================================================
  # PÚBLICOS
  # ===================================================================

  # /register <nombre> <correo> <rol>
  def ejecutar_comando(
        %{service: :auth_service, action: :register},
        %{
          nombre: nombre,
          correo: correo,
          username: username,
          contrasenia: contrasenia,
          rol: rol,
        }
      ) do
    rol_atom = String.to_atom(rol)
    contrasenia_str = to_string(contrasenia)

    case rol_atom do
      :participante ->
        ParticipantManager.registrar_participante(
          nombre,
          correo,
          username,
          contrasenia_str,
          rol_atom
        )

      :mentor ->
        MentorManager.registrar_mentor(
          nombre,
          correo,
          contrasenia_str,
          rol_atom,
          nil
        )

      _ ->
        {:error, "Rol no permitido"}
    end
  end

  # /login <id_usuario>
  def ejecutar_comando(%{service: :auth_service, action: :login}, %{correo: correo, contrasenia: contrasenia}) do
  case AuthService.autenticar(correo, contrasenia) do
    {:ok, %{participante: _participante, token: _token}} ->
      {:ok, "Sesión iniciada correctamente."}

    {:error, razon} ->
      {:error, razon}
  end
end

  # /help
  def ejecutar_comando(%{service: :command_service, action: :show_help}, _args) do
    usuario =
      case SessionManager.obtener_participante_actual() do
        {:ok, u} -> u
        _ -> nil
      end

    comandos =
      CommandRegistry.all()
      |> Enum.filter(fn {_cmd, info} ->
        comando_visible?(usuario, info)
      end)
      |> Enum.map(fn {cmd, info} ->
        """
        #{cmd}
          → #{info.description}
          Uso: #{Map.get(info, :usage, "No especificado")}
        """
      end)
      |> Enum.join("\n")

    {:ok, "Comandos disponibles:\n" <> comandos}
  end

  # ===================================================================
  # SESIÓN ACTIVA
  # ===================================================================

  # /logout
  def ejecutar_comando(%{service: :auth_service, action: :logout}, _args) do
    usuario =
      case SessionManager.obtener_participante_actual() do
        {:ok, u} -> u
        _ -> nil
      end

    AuthService.cerrar_sesion(usuario.id)
    {:ok, "Sesión cerrada correctamente."}
  end

  # ===================================================================
  # PARTICIPANTE
  # ===================================================================

  # /teams
  def ejecutar_comando(%{service: :team_manager, action: :list_teams}, _args) do
    {:ok, TeamManager.listar_equipos()}
  end

  # /project <equipo>
  def ejecutar_comando(%{service: :project_manager, action: :show_project}, %{equipo: equipo}) do
    with {:ok, eq} <- TeamManager.obtener_equipo(equipo),
         {:ok, proyecto} <- ProjectManager.obtener_proyecto_por_id(eq.id_proyecto) do
      {:ok, proyecto}
    else
      _ -> {:error, "Equipo o proyecto no encontrado."}
    end
  end

  # /join <equipo>
  def ejecutar_comando(%{service: :team_manager, action: :join_team}, %{equipo: equipo}) do
    {:ok, user} = SessionManager.obtener_participante_actual()

    case TeamManager.unirse_a_equipo(equipo, user) do
      {:ok, eq} -> {:ok, "Te uniste al equipo #{eq.nombre}"}
      {:error, :ya_es_miembro} -> {:error, "Ya perteneces a este equipo."}
      {:error, :no_encontrado} -> {:error, "Equipo no encontrado."}
    end
  end

  # /create_team <nombre> <categoria> <descripcion>
  def ejecutar_comando(%{service: :team_manager, action: :create_team}, %{
        nombre: n,
        categoria: c,
        descripcion: d
      }) do
    TeamManager.crear_equipo(n, c, d)
    {:ok, "Equipo creado correctamente."}
  end

  # /create_project <nombre> <categoria> <descripcion>
  def ejecutar_comando(%{service: :team_manager, action: :create_project}, %{
        nombre: n,
        descripcion: d,
        categoria: c,
        id_equipo: id_equipo
      }) do
    usuario = SessionManager.obtener_participante_actual()
    ProjectManager.crear_proyecto(n, d, c, id_equipo, usuario.id, nil)
    {:ok, "Proyecto creado correctamente."}
  end

  # /chat <equipo>
  def ejecutar_comando(%{service: :chat_manager, action: :open_chat}, %{equipo: equipo}) do
    ChatService.ingresar_chat_equipo(equipo)
    {:ok, "Ingresaste al chat del equipo #{equipo}"}
  end

  # ===================================================================
  # MENTOR
  # ===================================================================

  # /feedback <proyecto_id> <mensaje>
  def ejecutar_comando(%{service: :mentor_manager, action: :feedback}, %{
        proyecto_id: proyecto_id,
        mensaje: mensaje
      }) do
    mentor = SessionManager.obtener_participante_actual()
    mensaje = Enum.join(mensaje, " ")
    MentorManager.registrar_feedback(mentor.id, proyecto_id, mensaje)
    {:ok, "Feedback enviado"}
  end

  # ===================================================================
  # ADMIN
  # ===================================================================

  # /assign_mentor <equipo> <id_mentor>
  def ejecutar_comando(%{service: :admin_manager, action: :assign_mentor}, %{
        equipo: equipo,
        id_mentor: id
      }) do
    MentorManager.asignar_a_equipo(id, equipo)
    {:ok, "Mentor asignado a #{equipo}"}
  end

  # /delete_team <equipo>
  def ejecutar_comando(%{service: :admin_manager, action: :delete_team}, %{id_equip: id_equipo}) do
    TeamManager.disolver_equipo(id_equipo)
    {:ok, "Equipo eliminado correctamente."}
  end

  # /delete_user <id>
  def ejecutar_comando(%{service: :admin_manager, action: :delete_user}, %{id: id}) do
    ParticipantManager.eliminar_participante(id)
    {:ok, "Usuario eliminado correctamente."}
  end

  # ===================================================================
  # DEFAULT
  # ===================================================================

  def ejecutar_comando(_, _) do
    {:error, "Comando no reconocido o argumentos incorrectos. Usa /help."}
  end

  # ============================================================
  # FILTRO DE VISIBILIDAD SEGÚN ROL
  # ============================================================

  defp comando_visible?(nil, %{required_permission: nil}) do
    true
  end

  defp comando_visible?(nil, %{required_permission: _perm}) do
    false
  end

  defp comando_visible?(_usuario, %{required_permission: nil}) do
    true
  end

  defp comando_visible?(usuario, %{required_permission: permiso}) do
    PermissionService.autorizado?(usuario.id, permiso)
  end
end

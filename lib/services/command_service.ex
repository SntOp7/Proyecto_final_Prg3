defmodule ProyectoFinalPrg3.Services.CommandService do
  @moduledoc """
  Intérprete central de comandos CLI.

  Mejoras:
  - Validación de parámetros con espacios (usando comillas)
  - Validación de mensajes vacíos
  - Mejor formateo de historial con timestamps legibles
  """

  alias ProyectoFinalPrg3.Services.{
    AuthService,
    TeamManager,
    ProjectManager,
    ChatService,
    MentorManager,
    ParticipantManager,
    PermissionService,
    ProgressManager
  }

  alias ProyectoFinalPrg3.Adapters.Security.SessionManager
  alias ProyectoFinalPrg3.Adapters.CLI.CommandRegistry
  alias ProyectoFinalPrg3.Adapters.Network.AnnouncementChannel

  # ===================================================================
  # PÚBLICOS
  # ===================================================================

  # /register nombre="..." correo=... username=... contrasenia=... rol=...
  def ejecutar_comando(
        %{service: :auth_service, action: :register},
        %{
          nombre: nombre,
          correo: correo,
          username: username,
          contrasenia: contrasenia,
          rol: rol
        }
      ) do
    # Validar que no haya campos vacíos
    with :ok <- validar_no_vacio(nombre, "nombre"),
         :ok <- validar_no_vacio(correo, "correo"),
         :ok <- validar_no_vacio(username, "username"),
         :ok <- validar_no_vacio(contrasenia, "contraseña") do
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
            rol_atom
          )

        _ ->
          {:error, "Rol no permitido. Usa: participante o mentor"}
      end
    end
  end

  # /login correo=... contrasenia=...
  def ejecutar_comando(%{service: :auth_service, action: :login}, %{
        correo: correo,
        contrasenia: contrasenia
      }) do
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

  # /project equipo=...
  def ejecutar_comando(%{service: :project_manager, action: :show_project}, %{equipo: equipo}) do
    with {:ok, eq} <- TeamManager.obtener_equipo(equipo),
         {:ok, proyecto} <- ProjectManager.obtener_proyecto_por_id(eq.id_proyecto) do
      {:ok, proyecto}
    else
      _ -> {:error, "Equipo o proyecto no encontrado."}
    end
  end

  # /join equipo=...
  def ejecutar_comando(%{service: :team_manager, action: :join_team}, %{equipo: equipo}) do
    {:ok, user} = SessionManager.obtener_participante_actual()

    case TeamManager.unirse_a_equipo(equipo, user) do
      {:ok, eq} -> {:ok, "Te uniste al equipo #{eq.nombre}"}
      {:error, :ya_es_miembro} -> {:error, "Ya perteneces a este equipo."}
      {:error, :no_encontrado} -> {:error, "Equipo no encontrado."}
    end
  end

  # /create_team nombre="..." categoria=... descripcion="..."
  def ejecutar_comando(%{service: :team_manager, action: :create_team}, %{
        nombre: n,
        categoria: c,
        descripcion: d
      }) do
    with :ok <- validar_no_vacio(n, "nombre"),
         :ok <- validar_no_vacio(d, "descripción") do
      TeamManager.crear_equipo(n, c, d)
      {:ok, "Equipo creado correctamente."}
    end
  end

  # /create_project nombre="..." descripcion="..." categoria=... equipo=...
  def ejecutar_comando(%{service: :project_manager, action: :create_project}, %{
        nombre: n,
        descripcion: d,
        categoria: c,
        equipo: e
      }) do
    with :ok <- validar_no_vacio(n, "nombre"),
         :ok <- validar_no_vacio(d, "descripción"),
         {:ok, usuario} <- SessionManager.obtener_participante_actual() do
      case ProjectManager.crear_proyecto(n, d, c, e, usuario.id, nil) do
        # ← Cambiar esto: devolver el proyecto
        {:ok, proyecto} -> {:ok, proyecto}
        {:error, error} -> {:error, error}
      end
    else
      {:error, :no_sesion_activa} ->
        {:error, "Debes iniciar sesión para crear un proyecto."}

      error ->
        error
    end
  end

  # ===================================================================
  # MENTOR
  # ===================================================================

  # /feedback proyecto="..." mensaje="..."
  def ejecutar_comando(%{service: :mentor_manager, action: :feedback}, %{
        proyecto: nombre_proyecto,
        mensaje: mensaje
      }) do
    # Normalizar mensaje
    mensaje_str = normalizar_texto(mensaje)

    # Validar que no esté vacío
    with :ok <- validar_no_vacio(mensaje_str, "mensaje"),
         {:ok, mentor} <- SessionManager.obtener_participante_actual(),
         {:ok, proyecto} <- ProjectManager.obtener_proyecto(nombre_proyecto) do
      MentorManager.registrar_feedback(mentor.id, proyecto.id, mensaje_str)
      {:ok, "✅ Feedback enviado al proyecto '#{nombre_proyecto}'"}
    else
      {:error, :no_sesion_activa} ->
        {:error, "Debes iniciar sesión para enviar feedback."}

      {:error, :no_encontrado} ->
        {:error, "Proyecto '#{nombre_proyecto}' no encontrado."}

      {:error, msg} when is_binary(msg) ->
        {:error, msg}
    end
  end

  # ===================================================================
  # ADMIN
  # ===================================================================

  # /assign_mentor equipo=... id_mentor=...
  def ejecutar_comando(%{service: :admin_manager, action: :assign_mentor}, %{
        equipo: equipo,
        id_mentor: id
      }) do
    MentorManager.asignar_a_equipo(id, equipo)
    {:ok, "Mentor asignado a #{equipo}"}
  end

  # /delete_team id_equipo=...
  def ejecutar_comando(%{service: :admin_manager, action: :delete_team}, %{id_equip: id_equipo}) do
    TeamManager.disolver_equipo(id_equipo)
    {:ok, "Equipo eliminado correctamente."}
  end

  # /delete_user id=...
  def ejecutar_comando(%{service: :admin_manager, action: :delete_user}, %{id: id}) do
    ParticipantManager.eliminar_participante(id)
    {:ok, "Usuario eliminado correctamente."}
  end

  # ===================================================================
  # CHAT
  # ===================================================================

  # /chat equipo=...
  def ejecutar_comando(%{service: :chat_manager, action: :open_chat}, %{equipo: equipo}) do
    ChatService.ingresar_chat_equipo(equipo)
  end

  # /salir_chat
  def ejecutar_comando(%{service: :chat_manager, action: :leave_chat}, _args) do
    ChatService.salir_chat()
  end

  # Enviar mensaje (cuando el usuario está en un chat activo)
  # Nota: Este comando NO se llama directamente, se maneja en el CLI
  def ejecutar_comando(%{service: :chat_manager, action: :send_message}, %{mensaje: mensaje}) do
    mensaje_str = normalizar_texto(mensaje)

    # La validación de vacío la hace ChatService.enviar_mensaje/1
    ChatService.enviar_mensaje(mensaje_str)
  end

  # /historial
  def ejecutar_comando(%{service: :chat_manager, action: :show_history}, _args) do
    with {:ok, participante} <- SessionManager.obtener_participante_actual(),
         {:ok, nombre_equipo} <- ChatService.obtener_chat_activo_usuario(participante.id) do
      # ChatService.obtener_historial ya retorna el historial formateado
      ChatService.obtener_historial(nombre_equipo)
    else
      {:error, :sin_chat_activo} ->
        {:error, "No estás en ningún chat. Usa /chat equipo=NombreEquipo"}

      {:error, :no_sesion_activa} ->
        {:error, "Debes iniciar sesión."}

      error ->
        error
    end
  end

  # ===================================================================
  # PROGRESS (AVANCES)
  # ===================================================================

  # /progress proyecto=... titulo="..." descripcion="..." version=...
  def ejecutar_comando(%{service: :progress_manager, action: :add_progress}, %{
        proyecto: proyecto,
        titulo: titulo,
        descripcion: descripcion,
        version: version
      }) do
    descripcion_str = normalizar_texto(descripcion)
    titulo_str = normalizar_texto(titulo)

    with :ok <- validar_no_vacio(titulo_str, "título"),
         :ok <- validar_no_vacio(descripcion_str, "descripción") do
      case ProgressManager.registrar_avance(proyecto, titulo_str, descripcion_str, version) do
        {:ok, avance} -> {:ok, "✅ Avance registrado: #{avance.titulo} (v#{avance.version})"}
        {:error, razon} -> {:error, razon}
      end
    end
  end

  # /avances proyecto=...
  def ejecutar_comando(%{service: :progress_manager, action: :list_progress}, %{
        proyecto: proyecto
      }) do
    case ProgressManager.listar_avances_proyecto(proyecto) do
      {:ok, avances} when is_list(avances) ->
        if Enum.empty?(avances) do
          {:ok, "📭 No hay avances registrados para este proyecto."}
        else
          # Formatear lista de avances
          resultado =
            avances
            |> Enum.map(fn avance ->
              fecha = Calendar.strftime(avance.fecha_registro, "%Y-%m-%d %H:%M")

              estado_emoji =
                case avance.estado do
                  :pendiente -> "⏳"
                  :revision -> "🔍"
                  :aprobado -> "✅"
                  _ -> "❓"
                end

              """
              #{estado_emoji} #{avance.titulo} (v#{avance.version})
                 📅 #{fecha}
                 👤 Autor ID: #{avance.autor_id}
                 📝 #{avance.descripcion}
                 #{if avance.retroalimentacion, do: "💬 Feedback: #{avance.retroalimentacion}", else: ""}
              """
            end)
            |> Enum.join("\n")

          {:ok, "📊 AVANCES DEL PROYECTO\n\n" <> resultado}
        end

      {:error, razon} ->
        {:error, razon}
    end
  end

  # /annoucement
  def ejecutar_comando(%{service: :announcement, action: :send}, %{mensaje: texto}) do
    texto = String.trim(texto)

    if texto == "" do
      {:error, "El anuncio no puede estar vacío."}
    else
      AnnouncementChannel.announce(texto)
      {:ok, "📢 Anuncio enviado a todos los participantes."}
    end
  end

  # ===================================================================
  # DEFAULT
  # ===================================================================

  def ejecutar_comando("anuncio", _),
    do: {:error, "Uso correcto: /anuncio mensaje=\"Texto aquí\""}

  def ejecutar_comando(_, _) do
    {:error, "Comando no reconocido o argumentos incorrectos. Usa /help."}
  end

  # ===================================================================
  # FUNCIONES AUXILIARES
  # ===================================================================

  @doc """
  Normaliza texto que puede venir como string o lista.
  """
  def normalizar_texto(texto) when is_list(texto), do: Enum.join(texto, " ")
  def normalizar_texto(texto) when is_binary(texto), do: texto
  def normalizar_texto(texto), do: to_string(texto)

  @doc """
  Valida que un campo no esté vacío después de hacer trim.
  """
  def validar_no_vacio(valor, nombre_campo) do
    valor_limpio = valor |> to_string() |> String.trim()

    if valor_limpio == "" do
      {:error, "El campo '#{nombre_campo}' no puede estar vacío."}
    else
      :ok
    end
  end

  # ==========================================
  # VISIBILIDAD DE COMANDOS
  # ==========================================

  defp comando_visible?(usuario, %{context: :solo_en_chat} = info) do
    case usuario do
      nil ->
        false

      _ ->
        # Aquí NO LLAMAMOS ChatService.init ni ChatStore
        case ChatService.obtener_chat_activo_usuario(usuario.id) do
          {:ok, _} -> comando_visible_basico?(usuario, info)
          _ -> false
        end
    end
  end

  defp comando_visible?(usuario, info) do
    comando_visible_basico?(usuario, info)
  end

  # ==========================================
  # PERMISOS BASE
  # ==========================================

  defp comando_visible_basico?(nil, %{required_permission: nil}), do: true
  defp comando_visible_basico?(nil, %{required_permission: _}), do: false
  defp comando_visible_basico?(_usuario, %{required_permission: nil}), do: true

  defp comando_visible_basico?(usuario, %{required_permission: permiso}) do
    usuario &&
      PermissionService.autorizado?(usuario.id, permiso)
  end
end

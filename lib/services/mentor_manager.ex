defmodule ProyectoFinalPrg3.Services.MentorManager do
  @moduledoc """
  Servicio de gestión de mentores y feedback dentro del Hackathon.
  Alineado al dominio simplificado.
  Proporciona funcionalidades para registrar mentores, obtener sus datos,
  actualizar información, eliminar mentores y gestionar feedback.
  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  alias ProyectoFinalPrg3.Domain.{Mentor, Feedback}
  alias ProyectoFinalPrg3.Adapters.Persistence.{MentorStore, FeedbackStore}
  alias ProyectoFinalPrg3.Services.{BroadcastService, TeamManager, ProjectManager, ChatService}

  # ============================================================
  # REGISTRO DE MENTOR
  # ============================================================

  @doc """
  Registra un mentor nuevo con los campos del dominio.
  Parámetros:
    - nombre: Nombre completo del mentor (string).
    - correo: Correo electrónico del mentor (string).
    - contrasena: Contraseña del mentor (string).
    - rol: Rol del mentor (string, opcional).
  Retorna:
    - {:ok, mentor} si el registro es exitoso.
    - {:error, :correo_ya_registrado} si el correo ya existe en el sistema.
  """
  def registrar_mentor(nombre, correo, contrasena, rol) do
    case MentorStore.buscar_por_correo(correo) do
      nil ->
        contrasena_hash = :crypto.hash(:sha256, contrasena) |> Base.encode16()

        mentor =
          Mentor.nuevo(
            UUID.uuid4(),
            nombre,
            correo,
            contrasena_hash,
            rol
          )

        MentorStore.guardar_mentor(mentor)
        BroadcastService.notificar(:mentor_registrado, mentor)

        {:ok, mentor}

      _ ->
        {:error, :correo_ya_registrado}
    end
  end

  # ============================================================
  # CONSULTA
  # ============================================================

  @doc """
  Lista todos los mentores registrados en el sistema.
  Retorna:
    - lista de mentores.
  """
  def listar_mentores do
    MentorStore.listar_mentores()
  end

  @doc """
  Obtiene un mentor por su ID.
  Parámetros:
    - id: Identificador del mentor (string).
  Retorna:
    - {:ok, mentor} si se encuentra el mentor.
    - {:error, :no_encontrado} si no existe el mentor.
  """
  def obtener_mentor(id) do
    case MentorStore.obtener_por_id(id) do
      nil -> {:error, :no_encontrado}
      mentor -> {:ok, mentor}
    end
  end

  @doc """
  Busca mentores por especialidad.
  Parámetros:
    - esp: Especialidad a buscar (string).
  Retorna:
    - lista de mentores con la especialidad dada.
  """
  def buscar_por_especialidad(esp) do
    listar_mentores()
    |> Enum.filter(&(&1.especialidad == esp))
  end

  # ============================================================
  # FEEDBACK
  # ============================================================

  @doc """
  Crea feedback y lo envía al chat del equipo.
  Parámetros:
    - mentor_id: ID del mentor que da el feedback (string).
    - proyecto_id: ID del proyecto asociado (string).
    - contenido: Texto del feedback (string).
  Retorna:
    - {:ok, feedback} si el feedback se crea correctamente.
    - {:error, razón} si ocurre un error.
  """
  def registrar_feedback(mentor_id, proyecto_id, contenido) do
    with {:ok, mentor} <- obtener_mentor(mentor_id),
         {:ok, _proyecto} <- ProjectManager.obtener_proyecto_por_id(proyecto_id),
         {:ok, equipo} <- TeamManager.obtener_equipo_por_proyecto(proyecto_id) do
      feedback =
        Feedback.nuevo(
          UUID.uuid4(),
          mentor.id,
          proyecto_id,
          contenido,
          DateTime.utc_now()
        )

      FeedbackStore.guardar_feedback(feedback)
      BroadcastService.notificar(:feedback_creado, feedback)

      # Enviar al chat del equipo
      mensaje_chat = """
      📋 FEEDBACK DEL MENTOR #{mentor.nombre}
      #{contenido}
      """

      ChatService.enviar_mensaje_sistema(equipo.nombre, mensaje_chat)

      {:ok, feedback}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Lista todos los feedbacks dados por un mentor específico.
  Parámetros:
    - id_mentor: ID del mentor (string).
  Retorna:
    - lista de feedbacks asociados al mentor.
  """
  def listar_feedback_por_mentor(id_mentor) do
    FeedbackStore.listar_feedbacks()
    |> Enum.filter(&(&1.mentor_id == id_mentor))
  end

  # ============================================================
  # ACTUALIZACIÓN BÁSICA
  # ============================================================

  @doc """
  Actualiza datos permitidos del mentor:
  - nombre
  - correo
  - contrasena
  - especialidad
  Parámetros:
    - id: ID del mentor a actualizar (string).
    - cambios: Mapa con los campos a actualizar.
  Retorna:
    - {:ok, mentor_actualizado} si la actualización es exitosa.
    - {:error, razón} si ocurre un error.
  """
  def actualizar_mentor(id, cambios) do
    with {:ok, mentor} <- obtener_mentor(id) do
      actualizado =
        mentor
        |> Map.merge(Map.take(cambios, [:nombre, :correo, :contrasena, :rol, :especialidad]))

      MentorStore.guardar_mentor(actualizado)
      BroadcastService.notificar(:mentor_actualizado, actualizado)
      {:ok, actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Elimina un mentor del sistema.
  Parámetros:
    - id: ID del mentor a eliminar (string).
  Retorna:
    - {:ok, :eliminado} si la eliminación es exitosa.
    - {:error, razón} si ocurre un error.
  """
  def eliminar_mentor(id) do
    with {:ok, mentor} <- obtener_mentor(id) do
      MentorStore.eliminar_mentor(id)
      BroadcastService.notificar(:mentor_eliminado, mentor)
      {:ok, :eliminado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Asigna un mentor a un equipo específico.
  Parámetros:
    - id_mentor: ID del mentor (string).
    - nombre_equipo: Nombre del equipo (string).
  Retorna:
    - {:ok, equipo_actualizado} si la asignación es exitosa.
    - {:error, razón} si ocurre un error.
  """
  def asignar_a_equipo(id_mentor, nombre_equipo) do
    case MentorStore.obtener_por_id(id_mentor) do
      nil ->
        {:error, :mentor_no_encontrado}

      %Mentor{} = mentor ->
        with {:ok, _equipo} <- TeamManager.obtener_equipo(nombre_equipo) do
          case TeamManager.actualizar_datos(nombre_equipo, %{id_mentor: mentor.id}) do
            {:ok, equipo_actualizado} ->
              BroadcastService.notificar(:mentor_asignado_equipo, %{
                mentor_id: mentor.id,
                equipo_id: equipo_actualizado.id
              })

              {:ok, equipo_actualizado}

            {:error, razon} ->
              {:error, razon}
          end
        end
    end
  end
end

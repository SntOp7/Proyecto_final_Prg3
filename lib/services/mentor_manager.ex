defmodule ProyectoFinalPrg3.Services.MentorManager do
  @moduledoc """
  Servicio de gestión de mentores y feedback dentro del Hackathon.
  Alineado al dominio simplificado.
  """

  alias ProyectoFinalPrg3.Domain.{Mentor, Feedback}
  alias ProyectoFinalPrg3.Adapters.Persistence.{MentorStore, FeedbackStore}
  alias ProyectoFinalPrg3.Services.{BroadcastService, TeamManager}

  # ============================================================
  # REGISTRO DE MENTOR
  # ============================================================

  @doc """
  Registra un mentor nuevo con los campos del dominio.
  """
  def registrar_mentor(nombre, correo, contrasena, rol, especialidad) do
    case MentorStore.buscar_por_correo(correo) do
      nil ->
        mentor =
          Mentor.nuevo(
            UUID.uuid4(),
            nombre,
            correo,
            contrasena,
            rol,
            especialidad
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

  def listar_mentores do
    MentorStore.listar_mentores()
  end

  def obtener_mentor(id) do
    case MentorStore.obtener_por_id(id) do
      nil -> {:error, :no_encontrado}
      mentor -> {:ok, mentor}
    end
  end

  def buscar_por_especialidad(esp) do
    listar_mentores()
    |> Enum.filter(&(&1.especialidad == esp))
  end

  # ============================================================
  # FEEDBACK
  # ============================================================

  @doc """
  Crea un feedback simple dirigido a un proyecto.
  """
  def registrar_feedback(mentor_id, proyecto_id, contenido) do
    with {:ok, mentor} <- obtener_mentor(mentor_id) do
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

      {:ok, feedback}
    else
      {:error, razon} -> {:error, razon}
    end
  end

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

  def asignar_a_equipo(id_mentor, nombre_equipo) do
    with {:ok, mentor} <- MentorStore.obtener_por_id(id_mentor),
         {:ok, _equipo} <- TeamManager.obtener_equipo(nombre_equipo) do
      case TeamManager.actualizar_datos(nombre_equipo, %{id_mentor: mentor.id}) do
        {:ok, equipo_actualizado} ->
          BroadcastService.notificar(:mentor_asignado_equipo, %{
            mentor_id: mentor.id,
            equipo_id: equipo_actualizado.id
          })

          {:ok, equipo_actualizado}

        error ->
          error
      end
    else
      {:error, razon} -> {:error, razon}
    end
  end
end

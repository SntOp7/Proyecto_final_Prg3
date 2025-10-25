defmodule ProyectoFinalPrg3.Services.MentorManager do
  @moduledoc """
  Servicio encargado de la gestión de mentores dentro del sistema de hackathon.
  Permite registrar, listar, asignar mentores a equipos o proyectos, registrar retroalimentaciones
  y consultar el progreso de los equipos que supervisan.

  Este módulo pertenece a la capa de servicios de la arquitectura hexagonal.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-26
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.{Mentor, Team, Project, Feedback}
  alias ProyectoFinalPrg3.Adapters.Persistence.{MentorStore, FeedbackStore}
  alias ProyectoFinalPrg3.Services.{TeamManager, ProjectManager, BroadcastService}

  # ============================================================
  # FUNCIONES PRINCIPALES DE GESTIÓN DE MENTORES
  # ============================================================

  @doc """
  Registra un nuevo mentor en el sistema.
  """
  def registrar_mentor(nombre, especialidad, experiencia) do
    case MentorStore.obtener_por_nombre(nombre) do
      nil ->
        mentor = %Mentor{
          id: UUID.uuid4(),
          nombre: nombre,
          especialidad: especialidad,
          experiencia: experiencia,
          equipos_asignados: [],
          proyectos_asignados: [],
          fecha_registro: DateTime.utc_now(),
          estado: :activo
        }

        MentorStore.guardar_mentor(mentor)
        BroadcastService.notificar(:mentor_registrado, mentor)
        {:ok, mentor}

      _ ->
        {:error, :mentor_existente}
    end
  end

  @doc """
  Actualiza la información de un mentor existente.
  """
  def actualizar_mentor(%Mentor{} = mentor) do
    MentorStore.guardar_mentor(mentor)
    BroadcastService.notificar(:mentor_actualizado, mentor)
    {:ok, mentor}
  end

  @doc """
  Desactiva un mentor del sistema (sin eliminarlo físicamente).
  """
  def desactivar_mentor(id_mentor) do
    with {:ok, mentor} <- obtener_mentor(id_mentor) do
      mentor_actualizado = %{mentor | estado: :inactivo}
      MentorStore.guardar_mentor(mentor_actualizado)
      BroadcastService.notificar(:mentor_desactivado, mentor_actualizado)
      {:ok, mentor_actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  # ============================================================
  # FUNCIONES DE CONSULTA Y FILTRADO
  # ============================================================

  @doc """
  Lista todos los mentores registrados en el sistema.
  """
  def listar_mentores, do: MentorStore.listar_mentores()

  @doc """
  Obtiene los datos completos de un mentor por su ID.
  """
  def obtener_mentor(id_mentor) do
    case MentorStore.obtener_por_id(id_mentor) do
      nil -> {:error, :no_encontrado}
      mentor -> {:ok, mentor}
    end
  end

  @doc """
  Obtiene los mentores activos del sistema.
  """
  def listar_activos do
    listar_mentores() |> Enum.filter(&(&1.estado == :activo))
  end

  # ============================================================
  # FUNCIONES DE ASIGNACIÓN Y SUPERVISIÓN
  # ============================================================

  @doc """
  Asigna un mentor a un equipo específico.
  """
  def asignar_a_equipo(id_mentor, nombre_equipo) do
    with {:ok, mentor} <- obtener_mentor(id_mentor),
         {:ok, equipo} <- TeamManager.obtener_equipo(nombre_equipo) do
      equipo_actualizado = %{equipo | id_mentor: mentor.id}
      TeamManager.actualizar_equipo(equipo_actualizado)

      mentor_actualizado = %{
        mentor
        | equipos_asignados: Enum.uniq([equipo.id | mentor.equipos_asignados])
      }

      MentorStore.guardar_mentor(mentor_actualizado)
      BroadcastService.notificar(:mentor_asignado_equipo, %{mentor: mentor.id, equipo: equipo.id})

      {:ok, mentor_actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Asigna un mentor a un proyecto determinado.
  """
  def asignar_a_proyecto(id_mentor, nombre_proyecto) do
    with {:ok, mentor} <- obtener_mentor(id_mentor),
         {:ok, proyecto} <- ProjectManager.obtener_proyecto(nombre_proyecto) do
      proyecto_actualizado = %{proyecto | mentor_id: mentor.id}
      ProjectManager.actualizar_proyecto(nombre_proyecto, proyecto_actualizado)

      mentor_actualizado = %{
        mentor
        | proyectos_asignados: Enum.uniq([proyecto.id | mentor.proyectos_asignados])
      }

      MentorStore.guardar_mentor(mentor_actualizado)
      BroadcastService.notificar(:mentor_asignado_proyecto, %{mentor: mentor.id, proyecto: proyecto.id})

      {:ok, mentor_actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Obtiene todos los equipos supervisados por un mentor.
  """
  def listar_equipos_asignados(id_mentor) do
    with {:ok, mentor} <- obtener_mentor(id_mentor) do
      mentor.equipos_asignados
      |> Enum.map(&TeamManager.obtener_por_id/1)
      |> Enum.map(fn
        {:ok, equipo} -> equipo
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)
    end
  end

  @doc """
  Obtiene todos los proyectos asignados a un mentor.
  """
  def listar_proyectos_asignados(id_mentor) do
    with {:ok, mentor} <- obtener_mentor(id_mentor) do
      mentor.proyectos_asignados
      |> Enum.map(&ProjectManager.obtener_por_id/1)
      |> Enum.map(fn
        {:ok, proyecto} -> proyecto
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)
    end
  end

  # ============================================================
  # FUNCIONES DE RETROALIMENTACIÓN Y EVALUACIÓN
  # ============================================================

  @doc """
  Registra una retroalimentación de un mentor hacia un proyecto o equipo.
  """
  def registrar_feedback(id_mentor, destino, comentario, puntaje \\ nil) do
    with {:ok, mentor} <- obtener_mentor(id_mentor) do
      feedback = %Feedback{
        id: UUID.uuid4(),
        proyecto_id: destino.proyecto_id || destino.id,
        autor_id: mentor.id,
        titulo: "Retroalimentación de #{mentor.nombre}",
        comentario: comentario,
        puntaje: puntaje,
        tipo: "mentor",
        fecha: DateTime.utc_now(),
        adjuntos: %{}
      }

      FeedbackStore.guardar_feedback(feedback)
      BroadcastService.notificar(:retroalimentacion_registrada, feedback)

      {:ok, feedback}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Evalúa un proyecto con un puntaje, y actualiza su estado.
  """
  def evaluar_proyecto(id_mentor, nombre_proyecto, puntaje) do
    with {:ok, _mentor} <- obtener_mentor(id_mentor),
         {:ok, proyecto} <- ProjectManager.obtener_proyecto(nombre_proyecto) do
      actualizado = ProjectManager.actualizar_puntaje(nombre_proyecto, puntaje)
      BroadcastService.notificar(:proyecto_evaluado, %{mentor: id_mentor, proyecto: proyecto.id, puntaje: puntaje})
      actualizado
    else
      {:error, razon} -> {:error, razon}
    end
  end

  # ============================================================
  # FUNCIONES DE COMUNICACIÓN
  # ============================================================

  @doc """
  Envía un mensaje a todos los equipos o proyectos supervisados por un mentor.
  """
  def enviar_mensaje_general(id_mentor, mensaje) do
    with {:ok, mentor} <- obtener_mentor(id_mentor) do
      destinos =
        mentor.equipos_asignados
        |> Enum.map(&TeamManager.obtener_por_id/1)
        |> Enum.filter(&match?({:ok, _}, &1))
        |> Enum.map(fn {:ok, equipo} -> equipo end)

      Enum.each(destinos, fn equipo ->
        BroadcastService.notificar(:mensaje_mentor, %{mentor: mentor.nombre, equipo: equipo.nombre, mensaje: mensaje})
      end)

      {:ok, :mensajes_enviados}
    else
      {:error, razon} -> {:error, razon}
    end
  end
end

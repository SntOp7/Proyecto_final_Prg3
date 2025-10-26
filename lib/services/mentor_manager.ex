defmodule ProyectoFinalPrg3.Services.MentorManager do
  @moduledoc """
  Servicio encargado de la gestión de mentores dentro del sistema de hackathon.
  Permite registrar, listar, asignar mentores a equipos, administrar su disponibilidad,
  canal de mentoría, biografía y retroalimentaciones.

  Este módulo pertenece a la capa de servicios dentro de la arquitectura hexagonal.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-26
  Última modificación: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.{Mentor, Team, Feedback}
  alias ProyectoFinalPrg3.Adapters.Persistence.{MentorStore, FeedbackStore}
  alias ProyectoFinalPrg3.Services.{TeamManager, BroadcastService}

  # ============================================================
  # FUNCIONES PRINCIPALES DE GESTIÓN DE MENTORES
  # ============================================================

  @doc """
  Registra un nuevo mentor con sus datos principales en el sistema.
  """
  def registrar_mentor(nombre, correo, especialidad, rol \\ "mentor", biografia \\ "") do
    case MentorStore.buscar_por_correo(correo) do
      nil ->
        mentor = %Mentor{
          id: UUID.uuid4(),
          nombre: nombre,
          correo: correo,
          especialidad: especialidad,
          biografia: biografia,
          equipos_asignados: [],
          disponibilidad: :disponible,
          canal_mentoria_id: nil,
          fecha_registro: DateTime.utc_now(),
          retroalimentaciones: [],
          rol: rol,
          activo: true
        }

        MentorStore.guardar_mentor(mentor)
        BroadcastService.notificar(:mentor_registrado, mentor)
        {:ok, mentor}

      _ ->
        {:error, :correo_ya_registrado}
    end
  end

  @doc """
  Actualiza la información de un mentor (biografía, especialidad, rol, etc.).
  """
  def actualizar_datos(id_mentor, nuevos_datos) when is_map(nuevos_datos) do
    with {:ok, mentor} <- obtener_mentor(id_mentor) do
      actualizado = Map.merge(mentor, nuevos_datos)
      MentorStore.guardar_mentor(actualizado)
      BroadcastService.notificar(:mentor_actualizado, actualizado)
      {:ok, actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Marca a un mentor como inactivo en el sistema.
  """
  def desactivar_mentor(id_mentor) do
    with {:ok, mentor} <- obtener_mentor(id_mentor) do
      actualizado = %{mentor | activo: false, disponibilidad: :desconectado}
      MentorStore.guardar_mentor(actualizado)
      BroadcastService.notificar(:mentor_desactivado, actualizado)
      {:ok, actualizado}
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
  Obtiene la información de un mentor por su ID.
  """
  def obtener_mentor(id_mentor) do
    case MentorStore.obtener_por_id(id_mentor) do
      nil -> {:error, :no_encontrado}
      mentor -> {:ok, mentor}
    end
  end

  @doc """
  Lista todos los mentores activos.
  """
  def listar_activos do
    listar_mentores() |> Enum.filter(&(&1.activo))
  end

  @doc """
  Filtra mentores por especialidad o disponibilidad.
  """
  def filtrar(filtro, valor) do
    listar_mentores()
    |> Enum.filter(fn mentor ->
      case filtro do
        :especialidad -> mentor.especialidad == valor
        :disponibilidad -> mentor.disponibilidad == valor
        :rol -> mentor.rol == valor
        _ -> false
      end
    end)
  end

  # ============================================================
  # FUNCIONES DE ASIGNACIÓN Y SUPERVISIÓN
  # ============================================================

  @doc """
  Asigna un mentor a un equipo.
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
  Cambia la disponibilidad actual del mentor.
  """
  def cambiar_disponibilidad(id_mentor, nuevo_estado) do
    with {:ok, mentor} <- obtener_mentor(id_mentor) do
      actualizado = %{mentor | disponibilidad: nuevo_estado}
      MentorStore.guardar_mentor(actualizado)
      BroadcastService.notificar(:disponibilidad_cambiada, actualizado)
      {:ok, actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  # ============================================================
  # FUNCIONES DE RETROALIMENTACIÓN
  # ============================================================

  @doc """
  Registra una retroalimentación realizada por un mentor.
  """
  def registrar_feedback(id_mentor, destino_id, comentario, puntaje \\ nil) do
    with {:ok, mentor} <- obtener_mentor(id_mentor) do
      feedback = %Feedback{
        id: UUID.uuid4(),
        autor_id: mentor.id,
        destino_id: destino_id,
        comentario: comentario,
        puntaje: puntaje,
        tipo: "mentor",
        fecha: DateTime.utc_now()
      }

      FeedbackStore.guardar_feedback(feedback)

      mentor_actualizado = %{
        mentor
        | retroalimentaciones: [feedback.id | mentor.retroalimentaciones]
      }

      MentorStore.guardar_mentor(mentor_actualizado)
      BroadcastService.notificar(:feedback_mentor, feedback)

      {:ok, feedback}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  # ============================================================
  # FUNCIONES DE COMUNICACIÓN
  # ============================================================

  @doc """
  Asigna o actualiza el canal de mentoría para el mentor.
  """
  def asignar_canal(id_mentor, canal_id) do
    with {:ok, mentor} <- obtener_mentor(id_mentor) do
      actualizado = %{mentor | canal_mentoria_id: canal_id}
      MentorStore.guardar_mentor(actualizado)
      BroadcastService.notificar(:canal_asignado_mentor, actualizado)
      {:ok, actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Envía un mensaje general del mentor a todos sus equipos asignados.
  """
  def enviar_mensaje_general(id_mentor, mensaje) do
    with {:ok, mentor} <- obtener_mentor(id_mentor) do
      Enum.each(mentor.equipos_asignados, fn equipo_id ->
        BroadcastService.notificar(:mensaje_mentor, %{
          mentor: mentor.nombre,
          equipo_id: equipo_id,
          mensaje: mensaje
        })
      end)

      {:ok, :mensajes_enviados}
    else
      {:error, razon} -> {:error, razon}
    end
  end
end

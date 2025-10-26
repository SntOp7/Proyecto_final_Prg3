defmodule ProyectoFinalPrg3.Services.ProjectManager do
  @moduledoc """
  Servicio encargado de la gestión integral de proyectos dentro del sistema de hackathon.

  Permite crear, actualizar, listar y eliminar proyectos, así como administrar sus avances,
  retroalimentaciones, categorías, visibilidad y vinculación con equipos y mentores.

  Además, mantiene comunicación con los servicios de difusión (`BroadcastService`),
  persistencia (`ProjectStore`, `ProgressStore`, `FeedbackStore`) y coordinación (`TeamManager`, `CategoryService`).

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-26
  Última modificación: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.{Project, Progress, Category}
  alias ProyectoFinalPrg3.Adapters.Persistence.{ProjectStore, ProgressStore, FeedbackStore}
  alias ProyectoFinalPrg3.Services.{TeamManager, BroadcastService, CategoryService}

  # ============================================================
  # FUNCIONES PRINCIPALES DE GESTIÓN DE PROYECTOS
  # ============================================================

  @doc """
  Crea un nuevo proyecto en el sistema.

  - Verifica si el nombre ya existe.
  - Asocia el proyecto con su equipo y categoría si se proporcionan.
  - Registra el evento de creación en el sistema de broadcast.
  """
  def crear_proyecto(nombre, descripcion, categoria, equipo_id, mentor_id \\ nil) do
    if existe_proyecto?(nombre) do
      {:error, :proyecto_ya_existente}
    else
      proyecto = %Project{
        id: UUID.uuid4(),
        nombre: nombre,
        descripcion: descripcion,
        categoria: categoria,
        estado: :en_desarrollo,
        fecha_creacion: DateTime.utc_now(),
        fecha_actualizacion: DateTime.utc_now(),
        equipo_id: equipo_id,
        mentor_id: mentor_id,
        avances: [],
        retroalimentaciones: [],
        repositorio_url: nil,
        puntaje: 0,
        visibilidad: :privado,
        tags: []
      }

      ProjectStore.guardar_proyecto(proyecto)
      BroadcastService.notificar(:proyecto_creado, proyecto)

      # Asociar al equipo si existe
      if equipo_id do
        case TeamManager.obtener_equipo_por_id(equipo_id) do
          {:ok, equipo} -> TeamManager.vincular_proyecto(equipo.nombre, proyecto.id)
          {:error, _} -> BroadcastService.notificar(:equipo_no_encontrado, %{equipo_id: equipo_id})
        end
      end

      # Asociar a la categoría si existe
      if categoria, do: CategoryService.agregar_proyecto_a_categoria(categoria, proyecto.id)

      {:ok, proyecto}
    end
  end

  @doc """
  Actualiza los datos de un proyecto, como descripción, estado, visibilidad o URL del repositorio.
  """
  def actualizar_proyecto(nombre, nuevos_datos) do
    with {:ok, proyecto} <- obtener_proyecto(nombre) do
      actualizado =
        proyecto
        |> Map.merge(nuevos_datos)
        |> Map.put(:fecha_actualizacion, DateTime.utc_now())

      ProjectStore.guardar_proyecto(actualizado)
      BroadcastService.notificar(:proyecto_actualizado, actualizado)
      {:ok, actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Elimina un proyecto del sistema y desvincula sus referencias en equipos y categorías.
  """
  def eliminar_proyecto(nombre) do
    with {:ok, proyecto} <- obtener_proyecto(nombre) do
      ProjectStore.eliminar_proyecto(nombre)

      # Desvincular del equipo si aplica
      if proyecto.equipo_id do
        case TeamManager.obtener_equipo_por_id(proyecto.equipo_id) do
          {:ok, equipo} -> TeamManager.vincular_proyecto(equipo.nombre, nil)
          _ -> :ok
        end
      end

      # Eliminar de la categoría
      if proyecto.categoria, do: CategoryService.eliminar_proyecto_de_categoria(proyecto.categoria, proyecto.id)

      BroadcastService.notificar(:proyecto_eliminado, proyecto)
      {:ok, :proyecto_eliminado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  # ============================================================
  # FUNCIONES DE CONSULTA Y FILTRADO
  # ============================================================

  @doc "Lista todos los proyectos almacenados."
  def listar_proyectos, do: ProjectStore.listar_proyectos()

  @doc "Obtiene un proyecto por su nombre."
  def obtener_proyecto(nombre) do
    case ProjectStore.obtener_proyecto(nombre) do
      nil -> {:error, :no_encontrado}
      proyecto -> {:ok, proyecto}
    end
  end

  @doc "Obtiene un proyecto por su ID."
  def obtener_proyecto_por_id(id) do
    case ProjectStore.obtener_por_id(id) do
      nil -> {:error, :no_encontrado}
      proyecto -> {:ok, proyecto}
    end
  end

  @doc """
  Filtra proyectos por categoría, estado o visibilidad.
  """
  def filtrar_proyectos(filtro, valor) do
    proyectos = ProjectStore.listar_proyectos()

    case filtro do
      :categoria -> Enum.filter(proyectos, &(&1.categoria == valor))
      :estado -> Enum.filter(proyectos, &(&1.estado == valor))
      :visibilidad -> Enum.filter(proyectos, &(&1.visibilidad == valor))
      _ -> proyectos
    end
  end

  @doc "Lista proyectos asociados a un mentor específico."
  def listar_por_mentor(mentor_id),
    do: ProjectStore.listar_proyectos() |> Enum.filter(&(&1.mentor_id == mentor_id))

  @doc "Lista proyectos vinculados a un equipo específico."
  def listar_por_equipo(equipo_id),
    do: ProjectStore.listar_proyectos() |> Enum.filter(&(&1.equipo_id == equipo_id))

  # ============================================================
  # FUNCIONES DE AVANCES Y RETROALIMENTACIÓN
  # ============================================================

  @doc """
  Registra un nuevo avance dentro de un proyecto y lo guarda tanto en ProjectStore como en ProgressStore.
  """
  def registrar_avance(nombre_proyecto, %Progress{} = avance) do
    with {:ok, proyecto} <- obtener_proyecto(nombre_proyecto) do
      actualizado = %{
        proyecto
        | avances: proyecto.avances ++ [avance],
          fecha_actualizacion: DateTime.utc_now()
      }

      ProgressStore.guardar_avance(avance)
      ProjectStore.guardar_proyecto(actualizado)
      BroadcastService.notificar(:avance_registrado, %{proyecto: nombre_proyecto, avance: avance.id})
      {:ok, actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Registra una nueva retroalimentación para un proyecto.
  Guarda solo el ID de la retroalimentación en el proyecto para evitar duplicación de datos.
  """
  def registrar_retroalimentacion(nombre_proyecto, feedback) do
    with {:ok, proyecto} <- obtener_proyecto(nombre_proyecto) do
      actualizado = %{
        proyecto
        | retroalimentaciones: [feedback.id | proyecto.retroalimentaciones],
          fecha_actualizacion: DateTime.utc_now()
      }

      FeedbackStore.guardar_feedback(feedback)
      ProjectStore.guardar_proyecto(actualizado)
      BroadcastService.notificar(:retroalimentacion_registrada, %{proyecto: nombre_proyecto, feedback: feedback.id})
      {:ok, actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  # ============================================================
  # FUNCIONES DE GESTIÓN ADICIONAL
  # ============================================================

  def actualizar_visibilidad(nombre, nueva_visibilidad),
    do: actualizar_campo(nombre, :visibilidad, nueva_visibilidad, :visibilidad_actualizada)

  def actualizar_tags(nombre, nuevas_tags),
    do: actualizar_campo(nombre, :tags, nuevas_tags, :tags_actualizados)

  def actualizar_estado(nombre, nuevo_estado),
    do: actualizar_campo(nombre, :estado, nuevo_estado, :estado_actualizado)

  def actualizar_repositorio_url(nombre, url),
    do: actualizar_campo(nombre, :repositorio_url, url, :repositorio_actualizado)

  def asignar_mentor(nombre, nuevo_mentor_id),
    do: actualizar_campo(nombre, :mentor_id, nuevo_mentor_id, :mentor_asignado)

  def actualizar_puntaje(nombre, nuevo_puntaje),
    do: actualizar_campo(nombre, :puntaje, nuevo_puntaje, :puntaje_actualizado)

  @doc """
  Archiva un proyecto sin eliminarlo (por ejemplo, tras la finalización del evento).
  """
  def archivar_proyecto(nombre) do
    with {:ok, proyecto} <- obtener_proyecto(nombre) do
      actualizado = %{proyecto | estado: :archivado, visibilidad: :privado}
      ProjectStore.guardar_proyecto(actualizado)
      BroadcastService.notificar(:proyecto_archivado, actualizado)
      {:ok, actualizado}
    end
  end

  # ============================================================
  # FUNCIONES AUXILIARES PRIVADAS
  # ============================================================

  @doc false
  defp existe_proyecto?(nombre), do: ProjectStore.obtener_proyecto(nombre) != nil

  @doc false
  defp actualizar_campo(nombre, campo, valor, evento) do
    with {:ok, proyecto} <- obtener_proyecto(nombre) do
      actualizado = Map.put(proyecto, campo, valor) |> Map.put(:fecha_actualizacion, DateTime.utc_now())
      ProjectStore.guardar_proyecto(actualizado)
      BroadcastService.notificar(evento, actualizado)
      {:ok, actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end
end

defmodule ProyectoFinalPrg3.Services.ProjectManager do
  @moduledoc """
  Define la lógica de negocio relacionada con la gestión de proyectos dentro del sistema de hackathon.
  Permite crear, actualizar, listar y eliminar proyectos, así como administrar sus avances,
  retroalimentaciones, categorías, visibilidad y vinculación con equipos y mentores.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-26
  Fecha de última modificación: 2025-10-26
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.{Project, Team, Progress, Category}
  alias ProyectoFinalPrg3.Adapters.Persistence.{ProjectStore, ProgressStore, FeedbackStore}
  alias ProyectoFinalPrg3.Services.{TeamManager, BroadcastService, CategoryService}

  # ============================================================
  # FUNCIONES PRINCIPALES DE GESTIÓN DE PROYECTOS
  # ============================================================

  @doc """
  Crea un nuevo proyecto en el sistema con sus atributos completos.
  Si se asocia a un equipo o categoría existente, se actualizan las referencias correspondientes.
  """
  def crear_proyecto(nombre, descripcion, categoria, equipo_id, mentor_id \\ nil) do
    case ProjectStore.obtener_proyecto(nombre) do
      nil ->
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

        # Asociar al equipo
        if equipo_id do
          with {:ok, equipo} <- TeamManager.obtener_equipo_por_id(equipo_id) do
            TeamManager.vincular_proyecto(equipo.nombre, proyecto.id)
          end
        end

        # Asociar a la categoría
        if categoria do
          CategoryService.agregar_proyecto_a_categoria(categoria, proyecto.id)
        end

        {:ok, proyecto}

      _existente ->
        {:error, :proyecto_ya_existente}
    end
  end

  @doc """
  Actualiza los datos de un proyecto, incluyendo descripción, estado, visibilidad o URL del repositorio.
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

      # Desvincular del equipo
      if proyecto.equipo_id do
        with {:ok, equipo} <- TeamManager.obtener_equipo_por_id(proyecto.equipo_id) do
          TeamManager.vincular_proyecto(equipo.nombre, nil)
        end
      end

      # Eliminar referencia en la categoría
      if proyecto.categoria do
        CategoryService.eliminar_proyecto_de_categoria(proyecto.categoria, proyecto.id)
      end

      BroadcastService.notificar(:proyecto_eliminado, proyecto)
      {:ok, :proyecto_eliminado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  # ============================================================
  # FUNCIONES DE CONSULTA Y FILTRADO
  # ============================================================

  @doc """
  Lista todos los proyectos almacenados en el sistema.
  """
  def listar_proyectos do
    ProjectStore.listar_proyectos()
  end

  @doc """
  Obtiene un proyecto a partir de su nombre.
  """
  def obtener_proyecto(nombre) do
    case ProjectStore.obtener_proyecto(nombre) do
      nil -> {:error, :no_encontrado}
      proyecto -> {:ok, proyecto}
    end
  end

  @doc """
  Obtiene un proyecto a partir de su ID.
  """
  def obtener_proyecto_por_id(id) do
    case ProjectStore.obtener_por_id(id) do
      nil -> {:error, :no_encontrado}
      proyecto -> {:ok, proyecto}
    end
  end

  @doc """
  Filtra los proyectos según su categoría, estado o visibilidad.
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

  @doc """
  Lista los proyectos asociados a un mentor específico.
  """
  def listar_por_mentor(mentor_id) do
    ProjectStore.listar_proyectos()
    |> Enum.filter(&(&1.mentor_id == mentor_id))
  end

  @doc """
  Lista los proyectos vinculados a un equipo específico.
  """
  def listar_por_equipo(equipo_id) do
    ProjectStore.listar_proyectos()
    |> Enum.filter(&(&1.equipo_id == equipo_id))
  end

  # ============================================================
  # FUNCIONES DE AVANCES Y RETROALIMENTACIÓN
  # ============================================================

  @doc """
  Registra un nuevo avance para un proyecto y lo persiste tanto en ProjectStore como en ProgressStore.
  """
  def registrar_avance(nombre_proyecto, avance = %Progress{}) do
    with {:ok, proyecto} <- obtener_proyecto(nombre_proyecto) do
      proyecto_actualizado = %{
        proyecto
        | avances: [avance | proyecto.avances],
          fecha_actualizacion: DateTime.utc_now()
      }

      ProgressStore.guardar_avance(avance)
      ProjectStore.guardar_proyecto(proyecto_actualizado)
      BroadcastService.notificar(:avance_registrado, proyecto_actualizado)
      {:ok, proyecto_actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Registra una nueva retroalimentación dentro de un proyecto y la guarda en FeedbackStore.
  """
  def registrar_retroalimentacion(nombre_proyecto, feedback) do
    with {:ok, proyecto} <- obtener_proyecto(nombre_proyecto) do
      proyecto_actualizado = %{
        proyecto
        | retroalimentaciones: [feedback | proyecto.retroalimentaciones],
          fecha_actualizacion: DateTime.utc_now()
      }

      FeedbackStore.guardar_feedback(feedback)
      ProjectStore.guardar_proyecto(proyecto_actualizado)
      BroadcastService.notificar(:retroalimentacion_registrada, proyecto_actualizado)
      {:ok, proyecto_actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  # ============================================================
  # FUNCIONES DE GESTIÓN ADICIONAL
  # ============================================================

  @doc """
  Actualiza la visibilidad del proyecto (:publico o :privado).
  """
  def actualizar_visibilidad(nombre, nueva_visibilidad) do
    with {:ok, proyecto} <- obtener_proyecto(nombre) do
      actualizado = %{proyecto | visibilidad: nueva_visibilidad}
      ProjectStore.guardar_proyecto(actualizado)
      BroadcastService.notificar(:visibilidad_actualizada, actualizado)
      {:ok, actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Actualiza las etiquetas o palabras clave de un proyecto.
  """
  def actualizar_tags(nombre, nuevas_tags) do
    with {:ok, proyecto} <- obtener_proyecto(nombre) do
      actualizado = %{proyecto | tags: nuevas_tags}
      ProjectStore.guardar_proyecto(actualizado)
      BroadcastService.notificar(:tags_actualizados, actualizado)
      {:ok, actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Actualiza el estado del proyecto (:en_desarrollo, :pausado, :completado).
  """
  def actualizar_estado(nombre, nuevo_estado) do
    with {:ok, proyecto} <- obtener_proyecto(nombre) do
      actualizado = %{
        proyecto
        | estado: nuevo_estado,
          fecha_actualizacion: DateTime.utc_now()
      }

      ProjectStore.guardar_proyecto(actualizado)
      BroadcastService.notificar(:estado_actualizado, actualizado)
      {:ok, actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Actualiza la URL del repositorio del proyecto.
  """
  def actualizar_repositorio_url(nombre, url) do
    with {:ok, proyecto} <- obtener_proyecto(nombre) do
      actualizado = %{proyecto | repositorio_url: url, fecha_actualizacion: DateTime.utc_now()}
      ProjectStore.guardar_proyecto(actualizado)
      BroadcastService.notificar(:repositorio_actualizado, actualizado)
      {:ok, actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Asigna o actualiza el mentor responsable de un proyecto.
  """
  def asignar_mentor(nombre, nuevo_mentor_id) do
    with {:ok, proyecto} <- obtener_proyecto(nombre) do
      actualizado = %{proyecto | mentor_id: nuevo_mentor_id, fecha_actualizacion: DateTime.utc_now()}
      ProjectStore.guardar_proyecto(actualizado)
      BroadcastService.notificar(:mentor_asignado, actualizado)
      {:ok, actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Actualiza el puntaje obtenido por el proyecto.
  """
  def actualizar_puntaje(nombre, nuevo_puntaje) do
    with {:ok, proyecto} <- obtener_proyecto(nombre) do
      actualizado = %{proyecto | puntaje: nuevo_puntaje, fecha_actualizacion: DateTime.utc_now()}
      ProjectStore.guardar_proyecto(actualizado)
      BroadcastService.notificar(:puntaje_actualizado, actualizado)
      {:ok, actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end
end

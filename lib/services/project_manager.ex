defmodule ProyectoFinalPrg3.Services.ProjectService do
  @moduledoc """
  Define la lógica de negocio relacionada con la gestión de proyectos dentro del sistema de hackathon.
  Permite crear, actualizar, listar y eliminar proyectos, así como administrar sus avances,
  retroalimentaciones, categorías, visibilidad y vinculación con equipos y mentores.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-26
  Fecha de última modificación: 2025-10-25
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.{Project, Team, Progress, Category}
  alias ProyectoFinalPrg3.Adapters.Persistence.ProjectStore
  alias ProyectoFinalPrg3.Services.{TeamService, BroadcastService, CategoryService}

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

        # Asociar al equipo si existe
        if equipo_id, do: TeamService.vincular_proyecto(obtener_nombre_equipo(equipo_id), proyecto.id)

        # Asociar a la categoría
        if categoria, do: CategoryService.actualizar_categoria(categoria, %{proyectos: [proyecto.id]})

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
      proyecto_actualizado =
        proyecto
        |> Map.merge(nuevos_datos)
        |> Map.put(:fecha_actualizacion, DateTime.utc_now())

      ProjectStore.guardar_proyecto(proyecto_actualizado)
      BroadcastService.notificar(:proyecto_actualizado, proyecto_actualizado)
      {:ok, proyecto_actualizado}
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

      # Eliminar referencia del equipo
      if proyecto.equipo_id do
        {:ok, equipo} = TeamService.obtener_equipo(obtener_nombre_equipo(proyecto.equipo_id))
        equipo_actualizado = %{equipo | id_proyecto: nil}
        TeamService.actualizar_equipo(equipo_actualizado)
      end

      # Eliminar referencia de la categoría
      if proyecto.categoria do
        {:ok, categoria} = CategoryService.obtener_categoria(proyecto.categoria)
        nueva_lista = Enum.reject(categoria.proyectos, &(&1 == proyecto.id))
        CategoryService.actualizar_categoria(proyecto.categoria, %{proyectos: nueva_lista})
      end

      BroadcastService.notificar(:proyecto_eliminado, proyecto)
      :ok
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
  Filtra los proyectos registrados según su categoría, estado o visibilidad.
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
  Registra un nuevo avance para un proyecto, asociado a su equipo o autor correspondiente.
  """
  def registrar_avance(nombre_proyecto, avance = %Progress{}) do
    with {:ok, proyecto} <- obtener_proyecto(nombre_proyecto) do
      proyecto_actualizado = %{
        proyecto
        | avances: [avance | proyecto.avances],
          fecha_actualizacion: DateTime.utc_now()
      }

      ProjectStore.guardar_proyecto(proyecto_actualizado)
      BroadcastService.notificar(:avance_registrado, proyecto_actualizado)
      {:ok, proyecto_actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Registra una nueva retroalimentación (comentario o evaluación) dentro de un proyecto.
  """
  def registrar_retroalimentacion(nombre_proyecto, feedback) do
    with {:ok, proyecto} <- obtener_proyecto(nombre_proyecto) do
      proyecto_actualizado = %{
        proyecto
        | retroalimentaciones: [feedback | proyecto.retroalimentaciones],
          fecha_actualizacion: DateTime.utc_now()
      }

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
  Actualiza la visibilidad del proyecto (`:publico` o `:privado`).
  """
  def actualizar_visibilidad(nombre, nueva_visibilidad) do
    with {:ok, proyecto} <- obtener_proyecto(nombre) do
      proyecto_actualizado = %{proyecto | visibilidad: nueva_visibilidad}
      ProjectStore.guardar_proyecto(proyecto_actualizado)
      BroadcastService.notificar(:visibilidad_actualizada, proyecto_actualizado)
      {:ok, proyecto_actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Asigna etiquetas o palabras clave a un proyecto.
  """
  def actualizar_tags(nombre, nuevas_tags) do
    with {:ok, proyecto} <- obtener_proyecto(nombre) do
      proyecto_actualizado = %{proyecto | tags: nuevas_tags}
      ProjectStore.guardar_proyecto(proyecto_actualizado)
      BroadcastService.notificar(:tags_actualizados, proyecto_actualizado)
      {:ok, proyecto_actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Actualiza el estado general del proyecto (`:en_desarrollo`, `:pausado`, `:completado`).
  """
  def actualizar_estado(nombre, nuevo_estado) do
    with {:ok, proyecto} <- obtener_proyecto(nombre) do
      proyecto_actualizado = %{
        proyecto
        | estado: nuevo_estado,
          fecha_actualizacion: DateTime.utc_now()
      }

      ProjectStore.guardar_proyecto(proyecto_actualizado)
      BroadcastService.notificar(:estado_proyecto_actualizado, proyecto_actualizado)
      {:ok, proyecto_actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Actualiza la URL del repositorio asociado al proyecto.
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
  Asigna o actualiza el puntaje obtenido por el proyecto (por jurados o mentores).
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

  # ============================================================
  # FUNCIONES AUXILIARES
  # ============================================================

  @doc false
  defp obtener_nombre_equipo(id_equipo) do
    case TeamService.listar_equipos() |> Enum.find(&(&1.id == id_equipo)) do
      nil -> nil
      equipo -> equipo.nombre
    end
  end
end

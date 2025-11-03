defmodule ProyectoFinalPrg3.Services.ProjectManager do
  @moduledoc """
  Servicio encargado de la gestión integral de proyectos dentro del sistema de hackathon,
  con control de acceso mediante `PermissionService`.
  """

  alias ProyectoFinalPrg3.Domain.{Project, Progress}
  alias ProyectoFinalPrg3.Adapters.Persistence.{ProjectStore, ProgressStore, FeedbackStore}

  alias ProyectoFinalPrg3.Services.{
    TeamManager,
    BroadcastService,
    CategoryService,
    PermissionService
  }

  # ============================================================
  # FUNCIONES PRINCIPALES DE GESTIÓN DE PROYECTOS
  # ============================================================

  @doc """
  Crea un nuevo proyecto en el sistema (requiere permiso :crear_proyecto).
  """
  def crear_proyecto(nombre, descripcion, categoria, equipo_id, id_usuario, mentor_id \\ nil) do
    if PermissionService.autorizado?(id_usuario, :crear_proyecto) do
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
          case TeamManager.obtener_por_id(equipo_id) do
            {:ok, equipo} ->
              TeamManager.vincular_proyecto(equipo.nombre, proyecto.id)

            {:error, _} ->
              BroadcastService.notificar(:equipo_no_encontrado, %{equipo_id: equipo_id})
          end
        end

        # Asociar a la categoría si existe
        if categoria, do: CategoryService.agregar_proyecto(categoria, proyecto.id)

        {:ok, proyecto}
      end
    else
      {:error, :permiso_denegado}
    end
  end

  @doc """
  Actualiza los datos de un proyecto existente (requiere permiso :editar_proyecto).
  """
  def actualizar_proyecto(nombre, nuevos_datos, id_usuario) do
    if PermissionService.autorizado?(id_usuario, :editar_proyecto) do
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
    else
      {:error, :permiso_denegado}
    end
  end

  @doc """
  Elimina un proyecto del sistema (requiere permiso :eliminar_proyecto).
  """
  def eliminar_proyecto(nombre, id_usuario) do
    if PermissionService.autorizado?(id_usuario, :eliminar_proyecto) do
      with {:ok, proyecto} <- obtener_proyecto(nombre) do
        ProjectStore.eliminar_proyecto(nombre)

        if proyecto.equipo_id do
          case TeamManager.obtener_por_id(proyecto.equipo_id) do
            {:ok, equipo} -> TeamManager.vincular_proyecto(equipo.nombre, nil)
            _ -> :ok
          end
        end

        if proyecto.categoria,
          do: CategoryService.remover_proyecto(proyecto.categoria.id, proyecto.id)

        BroadcastService.notificar(:proyecto_eliminado, proyecto)
        {:ok, :proyecto_eliminado}
      else
        {:error, razon} -> {:error, razon}
      end
    else
      {:error, :permiso_denegado}
    end
  end

  # ============================================================
  # FUNCIONES DE CONSULTA Y FILTRADO (SIN CAMBIOS)
  # ============================================================

  def listar_proyectos, do: ProjectStore.listar_proyectos()

  def obtener_proyecto(nombre) do
    case ProjectStore.obtener_proyecto(nombre) do
      nil -> {:error, :no_encontrado}
      proyecto -> {:ok, proyecto}
    end
  end

  def obtener_proyecto_por_id(id) do
    case ProjectStore.obtener_por_id(id) do
      nil -> {:error, :no_encontrado}
      proyecto -> {:ok, proyecto}
    end
  end

  def filtrar_proyectos(filtro, valor) do
    proyectos = ProjectStore.listar_proyectos()

    case filtro do
      :categoria -> Enum.filter(proyectos, &(&1.categoria == valor))
      :estado -> Enum.filter(proyectos, &(&1.estado == valor))
      :visibilidad -> Enum.filter(proyectos, &(&1.visibilidad == valor))
      _ -> proyectos
    end
  end

  def listar_por_mentor(mentor_id),
    do: ProjectStore.listar_proyectos() |> Enum.filter(&(&1.mentor_id == mentor_id))

  def listar_por_equipo(equipo_id),
    do: ProjectStore.listar_proyectos() |> Enum.filter(&(&1.equipo_id == equipo_id))

  # ============================================================
  # FUNCIONES DE AVANCES, FEEDBACK Y ARCHIVO (SIN CAMBIOS)
  # ============================================================

  def registrar_avance(nombre_proyecto, %Progress{} = avance),
    do: actualizar_lista(nombre_proyecto, :avances, avance, ProgressStore, :avance_registrado)

  def registrar_retroalimentacion(nombre_proyecto, feedback),
    do:
      actualizar_lista(
        nombre_proyecto,
        :retroalimentaciones,
        feedback,
        FeedbackStore,
        :retroalimentacion_registrada
      )

  @doc """
  Archiva un proyecto (requiere permiso :archivar_proyecto).
  """
  def archivar_proyecto(nombre, id_usuario) do
    if PermissionService.autorizado?(id_usuario, :archivar_proyecto) do
      with {:ok, proyecto} <- obtener_proyecto(nombre) do
        actualizado = %{proyecto | estado: :archivado, visibilidad: :privado}
        ProjectStore.guardar_proyecto(actualizado)
        BroadcastService.notificar(:proyecto_archivado, actualizado)
        {:ok, actualizado}
      end
    else
      {:error, :permiso_denegado}
    end
  end

  # ============================================================
  # AUXILIARES PRIVADOS
  # ============================================================

  defp existe_proyecto?(nombre), do: ProjectStore.obtener_proyecto(nombre) != nil

  defp actualizar_lista(nombre, campo, item, store_mod, evento) do
    with {:ok, proyecto} <- obtener_proyecto(nombre) do
      actualizado =
        proyecto
        |> Map.update!(campo, fn lista -> [item | lista] end)
        |> Map.put(:fecha_actualizacion, DateTime.utc_now())

      store_mod.guardar_feedback(item)
      ProjectStore.guardar_proyecto(actualizado)
      BroadcastService.notificar(evento, %{proyecto: nombre, item: item.id})
      {:ok, actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end
end

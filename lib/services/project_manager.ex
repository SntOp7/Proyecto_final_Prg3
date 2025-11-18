defmodule ProyectoFinalPrg3.Services.ProjectManager do
  @moduledoc """
  Servicio responsable de gestionar proyectos dentro del sistema,
  manteniendo consistencia con el struct Project SIN avances, SIN tags,
  SIN visibilidad, SIN retroalimentaciones y SIN fecha_actualizacion.
  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  alias ProyectoFinalPrg3.Domain.Project
  alias ProyectoFinalPrg3.Adapters.Persistence.ProjectStore

  alias ProyectoFinalPrg3.Services.{
    TeamManager,
    BroadcastService,
    PermissionService
  }

  # ============================================================
  # CREACIÓN DE PROYECTOS
  # ============================================================

  @doc """
  Crea un proyecto nuevo y lo registra en el equipo y categoría correspondiente.
  Respeta estrictamente los campos definidos en el struct Project.
  Requiere permiso :crear_proyecto.
  Parámetros:
    - nombre: Nombre del proyecto (string).
    - descripcion: Descripción del proyecto (string).
    - categoria: Categoría del proyecto (string).
    - nombre_equipo: Nombre del equipo asociado (string).
    - usuario_id: ID del usuario que crea el proyecto (string).
    - mentor_id: ID del mentor asignado (string, opcional).
  Retorna:
    - {:ok, proyecto} si la creación es exitosa.
    - {:error, razón} si ocurre un error.
  """
  def crear_proyecto(nombre, descripcion, categoria, nombre_equipo, usuario_id, mentor_id \\ nil) do

  case PermissionService.autorizado?(usuario_id, :crear_proyecto) do
    true ->
      if existe_proyecto?(nombre) do
        {:error, :proyecto_ya_existente}
      else
        case TeamManager.obtener_equipo(nombre_equipo) do
          {:ok, equipo} ->
            id_equipo = equipo.id
            proyecto_id = UUID.uuid4()
            fecha = DateTime.utc_now()
            try do
              proyecto = Project.nuevo(
                proyecto_id,
                nombre,
                descripcion,
                categoria,
                :en_desarrollo,
                fecha,
                id_equipo,
                mentor_id,
                nil,
                nil
              )

              IO.inspect(proyecto, label: "   Proyecto")

              ProjectStore.guardar_proyecto(proyecto)

              BroadcastService.notificar(:proyecto_creado, proyecto)

              TeamManager.vincular_proyecto(equipo.nombre, proyecto.id)

              IO.puts("PROYECTO CREADO EXITOSAMENTE\n")

              {:ok, proyecto}
            rescue
              e ->
                IO.puts("ERROR EN: #{inspect(e)}")
                reraise e, __STACKTRACE__
            end

          {:error, :no_encontrado} ->
            IO.puts("Equipo no encontrado")
            {:error, "No se encontró un equipo con ese nombre"}
        end
      end

    false ->
      {:error, :permiso_denegado}
  end
end

  # ============================================================
  # ACTUALIZACIÓN
  # ============================================================

  @doc """
  Actualiza únicamente los campos EXISTENTES del struct Project.
  Requiere permiso :editar_proyecto.
  Parámetros:
    - nombre: Nombre del proyecto a actualizar (string).
    - cambios: Mapa con los campos a actualizar.
    - usuario_id: ID del usuario que realiza la actualización (string).
  Retorna:
    - {:ok, proyecto_actualizado} si la actualización es exitosa.
    - {:error, razón} si ocurre un error.
  """
  def actualizar_proyecto(nombre, cambios, usuario_id) do
    if PermissionService.autorizado?(usuario_id, :editar_proyecto) do
      with {:ok, proyecto} <- obtener_proyecto(nombre) do
        # Se permiten solo campos válidos del struct
        cambios_validos =
          Map.take(cambios, [
            :nombre,
            :descripcion,
            :categoria,
            :estado,
            :equipo_id,
            :mentor_id,
            :repositorio_url,
            :puntaje
          ])

        actualizado = Map.merge(proyecto, cambios_validos)

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

  # ============================================================
  # ELIMINAR PROYECTO
  # ============================================================

  @doc """
  Elimina un proyecto del sistema.

  Requiere permiso :eliminar_proyecto.
  Parámetros:
    - nombre: Nombre del proyecto a eliminar (string).
    - usuario_id: ID del usuario que realiza la eliminación (string).
  Retorna:
    - {:ok, :proyecto_eliminado} si la eliminación es exitosa.
    - {:error, razón} si ocurre un error.
  """
  def eliminar_proyecto(nombre, usuario_id) do
    if PermissionService.autorizado?(usuario_id, :eliminar_proyecto) do
      with {:ok, proyecto} <- obtener_proyecto(nombre) do
        ProjectStore.eliminar_proyecto(nombre)

        # Desvincular del equipo
        if proyecto.equipo_id do
          case TeamManager.obtener_por_id(proyecto.equipo_id) do
            {:ok, equipo} ->
              TeamManager.vincular_proyecto(equipo.nombre, nil)

            _ ->
              :ok
          end
        end

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
  # CONSULTAS DIRECTAS
  # ============================================================

  @doc """
  Lista todos los proyectos.
  Retorna:
    - lista de proyectos (lista de structs Project).
  """
  def listar_proyectos, do: ProjectStore.listar_proyectos()

  @doc """
  Obtiene un proyecto por su nombre.
  Parámetros:
    - nombre: Nombre del proyecto (string).
  Retorna:
    - {:ok, proyecto} si se encuentra.
    - {:error, :no_encontrado} si no existe.
  """
  def obtener_proyecto(nombre) do
    case ProjectStore.obtener_proyecto(nombre) do
      nil -> {:error, :no_encontrado}
      proyecto -> {:ok, proyecto}
    end
  end

  @doc """
  Obtiene un proyecto por su ID.
  Parámetros:
    - id: ID del proyecto (string).
  Retorna:
    - {:ok, proyecto} si se encuentra.
    - {:error, :no_encontrado} si no existe.
  """
  def obtener_proyecto_por_id(id) do
    case ProjectStore.obtener_por_id(id) do
      nil -> {:error, :no_encontrado}
      proyecto -> {:ok, proyecto}
    end
  end

  @doc """
  Lista proyectos por mentor.
  Parámetros:
    - mentor_id: ID del mentor (string).
  Retorna:
    - lista de proyectos asignados al mentor.
  """
  def listar_por_mentor(mentor_id),
    do: ProjectStore.listar_proyectos() |> Enum.filter(&(&1.mentor_id == mentor_id))

  @doc """
  Lista proyectos por equipo.
  Parámetros:
    - equipo_id: ID del equipo (string).
  Retorna:
    - lista de proyectos asignados al equipo.
  """
  def listar_por_equipo(equipo_id),
    do: ProjectStore.listar_proyectos() |> Enum.filter(&(&1.equipo_id == equipo_id))

  # ============================================================
  # FILTROS BÁSICOS (SOLO CAMPOS EXISTENTES)
  # ============================================================

  @doc """
  Filtra proyectos según un campo y valor dado.
  Parámetros:
    - filtro: Átomo que indica el campo a filtrar (:categoria, :estado, :mentor_id, :equipo_id).
    - valor: Valor a comparar para el filtro.
  Retorna:
    - lista de proyectos que cumplen con el filtro.
  """
  def filtrar_proyectos(filtro, valor) do
    proyectos = ProjectStore.listar_proyectos()

    case filtro do
      :categoria -> Enum.filter(proyectos, &(&1.categoria == valor))
      :estado -> Enum.filter(proyectos, &(&1.estado == valor))
      :mentor_id -> Enum.filter(proyectos, &(&1.mentor_id == valor))
      :equipo_id -> Enum.filter(proyectos, &(&1.equipo_id == valor))
      _ -> proyectos
    end
  end

  # ============================================================
  # AUX
  # ============================================================

  @doc false
  defp existe_proyecto?(nombre), do: ProjectStore.obtener_proyecto(nombre) != nil
end

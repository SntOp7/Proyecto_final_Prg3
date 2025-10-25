defmodule ProyectoFinalPrg3.Services.ProjectService do
  @moduledoc """
  Define la lógica de negocio relacionada con la gestión de proyectos dentro del sistema de hackathon.
  Este módulo permite crear, actualizar, listar y eliminar proyectos, así como vincularlos a equipos,
  asignar categorías, registrar avances y mantener su trazabilidad general.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-26
  Fecha de última modificación:
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.{Project, Team, Progress, Category}
  alias ProyectoFinalPrg3.Adapters.Persistence.ProjectStore
  alias ProyectoFinalPrg3.Services.{TeamService, BroadcastService, CategoryService}

  # ============================================================
  # FUNCIONES PRINCIPALES DE GESTIÓN DE PROYECTOS
  # ============================================================

  @doc """
  Crea un nuevo proyecto en el sistema con sus atributos iniciales.
  Se asigna una categoría opcional y se vincula al equipo correspondiente si aplica.
  """
  def crear_proyecto(nombre, descripcion, categoria \\ nil, id_equipo \\ nil) do
    case ProjectStore.obtener_proyecto(nombre) do
      nil ->
        proyecto = %Project{
          id: UUID.uuid4(),
          nombre: nombre,
          descripcion: descripcion,
          categoria: categoria,
          id_equipo: id_equipo,
          estado: :en_desarrollo,
          avances: [],
          fecha_creacion: DateTime.utc_now(),
          fecha_ultima_actualizacion: DateTime.utc_now(),
          retroalimentaciones: []
        }

        ProjectStore.guardar_proyecto(proyecto)
        BroadcastService.notificar(:proyecto_creado, proyecto)

        if id_equipo, do: TeamService.vincular_proyecto(nombre_equipo(id_equipo), proyecto.id)
        {:ok, proyecto}

      _existente ->
        {:error, :proyecto_ya_existente}
    end
  end

  @doc """
  Actualiza la descripción o información general de un proyecto existente.
  """
  def actualizar_proyecto(nombre, nuevos_datos) do
    with {:ok, proyecto} <- obtener_proyecto(nombre) do
      proyecto_actualizado =
        proyecto
        |> Map.merge(nuevos_datos)
        |> Map.put(:fecha_ultima_actualizacion, DateTime.utc_now())

      ProjectStore.guardar_proyecto(proyecto_actualizado)
      BroadcastService.notificar(:proyecto_actualizado, proyecto_actualizado)
      {:ok, proyecto_actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Elimina un proyecto de la base de datos de persistencia.
  """
  def eliminar_proyecto(nombre) do
    with {:ok, proyecto} <- obtener_proyecto(nombre) do
      ProjectStore.eliminar_proyecto(nombre)
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
  Lista todos los proyectos registrados en el sistema.
  """
  def listar_proyectos do
    ProjectStore.listar_proyectos()
  end

  @doc """
  Obtiene la información completa de un proyecto a partir de su nombre.
  """
  def obtener_proyecto(nombre) do
    case ProjectStore.obtener_proyecto(nombre) do
      nil -> {:error, :no_encontrado}
      proyecto -> {:ok, proyecto}
    end
  end

  @doc """
  Filtra los proyectos registrados según su categoría o estado actual.
  """
  def filtrar_proyectos(filtro, valor) do
    proyectos = ProjectStore.listar_proyectos()

    case filtro do
      :categoria -> Enum.filter(proyectos, &(&1.categoria == valor))
      :estado -> Enum.filter(proyectos, &(&1.estado == valor))
      _ -> proyectos
    end
  end

  # ============================================================
  # FUNCIONES DE AVANCE Y RETROALIMENTACIÓN
  # ============================================================

  @doc """
  Registra un nuevo avance asociado a un proyecto determinado.
  """
  def registrar_avance(nombre_proyecto, avance = %Progress{}) do
    with {:ok, proyecto} <- obtener_proyecto(nombre_proyecto) do
      proyecto_actualizado = %{
        proyecto
        | avances: [avance | proyecto.avances],
          fecha_ultima_actualizacion: DateTime.utc_now()
      }

      ProjectStore.guardar_proyecto(proyecto_actualizado)
      BroadcastService.notificar(:avance_registrado, proyecto_actualizado)
      {:ok, proyecto_actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Registra una retroalimentación o comentario sobre el progreso de un proyecto.
  """
  def registrar_retroalimentacion(nombre_proyecto, feedback) do
    with {:ok, proyecto} <- obtener_proyecto(nombre_proyecto) do
      proyecto_actualizado = %{
        proyecto
        | retroalimentaciones: [feedback | proyecto.retroalimentaciones],
          fecha_ultima_actualizacion: DateTime.utc_now()
      }

      ProjectStore.guardar_proyecto(proyecto_actualizado)
      BroadcastService.notificar(:feedback_registrado, proyecto_actualizado)
      {:ok, proyecto_actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  # ============================================================
  # FUNCIONES DE ESTADO Y CATEGORÍA
  # ============================================================

  @doc """
  Actualiza el estado de desarrollo de un proyecto (por ejemplo: `:en_revision`, `:finalizado`).
  """
  def actualizar_estado(nombre, nuevo_estado) do
    with {:ok, proyecto} <- obtener_proyecto(nombre) do
      proyecto_actualizado = %{proyecto | estado: nuevo_estado, fecha_ultima_actualizacion: DateTime.utc_now()}
      ProjectStore.guardar_proyecto(proyecto_actualizado)
      BroadcastService.notificar(:estado_proyecto_actualizado, proyecto_actualizado)
      {:ok, proyecto_actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Asigna o cambia la categoría de un proyecto, validando su existencia en el sistema.
  """
  def asignar_categoria(nombre, categoria) do
    with {:ok, _categoria_valida} <- CategoryService.obtener_categoria(categoria),
         {:ok, proyecto} <- obtener_proyecto(nombre) do
      proyecto_actualizado = %{proyecto | categoria: categoria}
      ProjectStore.guardar_proyecto(proyecto_actualizado)
      BroadcastService.notificar(:categoria_asignada, proyecto_actualizado)
      {:ok, proyecto_actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  # ============================================================
  # FUNCIONES AUXILIARES
  # ============================================================

  @doc false
  defp nombre_equipo(id_equipo) do
    case TeamService.listar_equipos() |> Enum.find(&(&1.id == id_equipo)) do
      nil -> nil
      equipo -> equipo.nombre
    end
  end
end

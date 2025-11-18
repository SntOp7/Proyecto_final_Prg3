defmodule ProyectoFinalPrg3.Services.TeamManager do
  @moduledoc """
  Servicio oficial de gestión de equipos.
  Totalmente alineado con el struct Team sin campos extra
  (sin canal_chat_id, sin puntaje, sin historial).
  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  alias ProyectoFinalPrg3.Domain.{Team, Participant}
  alias ProyectoFinalPrg3.Adapters.Persistence.TeamStore
  alias ProyectoFinalPrg3.Adapters.Security.SessionManager

  alias ProyectoFinalPrg3.Services.{
    BroadcastService,
    ParticipantManager,
    PermissionService
  }

  # ============================================================
  # CREAR EQUIPO
  # ============================================================

  @doc """
  Función para crear un nuevo equipo.
  Requiere permiso :crear_equipo.
  Parámetros:
    - nombre: Nombre del equipo (string).
    - categoria: Categoría del equipo (string).
    - descripcion: Descripción del equipo (string).
  Retorna:
    - {:ok, equipo} si la creación es exitosa.
    - {:error, :equipo_ya_existente} si ya existe un equipo con ese nombre.
    - {:error, :permiso_denegado} si el usuario no tiene permiso para crear equipos.
  """
  def crear_equipo(nombre, categoria, descripcion) do
    with {:ok, usuario} <- SessionManager.obtener_participante_actual(),
         true <- PermissionService.autorizado?(usuario.id, :crear_equipo) do
      case TeamStore.obtener_equipo(nombre) do
        nil ->
          equipo =
            Team.nuevo(
              UUID.uuid4(),
              nombre,
              descripcion,
              categoria,
              # id_proyecto
              nil,
              # id_mentor
              nil,
              # participantes
              [],
              DateTime.utc_now(),
              :activo
            )

          TeamStore.guardar_equipo(equipo)
          BroadcastService.notificar(:equipo_creado, equipo)

          {:ok, equipo}

        _ ->
          {:error, :equipo_ya_existente}
      end
    else
      false -> {:error, :permiso_denegado}
      error -> error
    end
  end

  @doc """
  Actualiza los datos de un equipo existente.
  Parámetros:
    - nombre_equipo: Nombre del equipo a actualizar (string).
    - cambios: Mapa con los campos a modificar y sus nuevos valores.
  Retorna:
    - {:ok, equipo_actualizado} si la actualización es exitosa.
    - {:error, razón} si ocurre un error.
  """
  def actualizar_datos(nombre_equipo, cambios) when is_map(cambios) do
    with {:ok, equipo} <- obtener_equipo(nombre_equipo) do
      # Solo actualiza campos que realmente existen en el struct Team
      cambios_validos =
        cambios
        |> Map.take([
          :nombre,
          :descripcion,
          :categoria,
          :id_proyecto,
          :id_mentor,
          :participantes,
          :fecha_creacion,
          :estado
        ])

      equipo_actualizado = Map.merge(equipo, cambios_validos)

      TeamStore.guardar_equipo(equipo_actualizado)
      BroadcastService.notificar(:equipo_actualizado, equipo_actualizado)

      {:ok, equipo_actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  # ============================================================
  # CONSULTA
  # ============================================================

  @doc """
  Lista todos los equipos disponibles.
  Retorna:
    - Lista de structs Team.
  """
  def listar_equipos, do: TeamStore.listar_equipos()

  @doc """
  Obtiene un equipo por su nombre.
  Parámetros:
    - nombre: Nombre del equipo (string).
  Retorna:
    - {:ok, equipo} si se encuentra el equipo.
    - {:error, :no_encontrado} si no existe el equipo.
  """
  def obtener_equipo(nombre) do
    case TeamStore.obtener_equipo(nombre) do
      nil -> {:error, :no_encontrado}
      eq -> {:ok, eq}
    end
  end

  @doc """
  Obtiene un equipo por su ID.
  Parámetros:
    - id: ID del equipo (string).
  Retorna:
    - {:ok, equipo} si se encuentra el equipo.
    - {:error, :no_encontrado} si no existe el equipo.
  """
  def obtener_por_id(id) do
    case TeamStore.obtener_equipo_por_id(id) do
      nil -> {:error, :no_encontrado}
      eq -> {:ok, eq}
    end
  end

  @doc """
  Obtiene el equipo asociado a un proyecto.
  Parámetros:
    - proyecto_id: ID del proyecto (string).
  Retorna:
    - {:ok, equipo} si se encuentra el equipo.
    - {:error, :equipo_no_encontrado} si no existe el equipo.
  """
  def obtener_equipo_por_proyecto(proyecto_id) do
    case TeamStore.listar_equipos()
         |> Enum.find(&(&1.id_proyecto == proyecto_id)) do
      nil -> {:error, :equipo_no_encontrado}
      equipo -> {:ok, equipo}
    end
  end

  # ============================================================
  # PARTICIPANTES
  # ============================================================

  @doc """
  Función para agregar un participante a un equipo.
  Parámetros:
    - nombre_equipo: Nombre del equipo (string).
    - participante: Struct Participant del participante a agregar.
  Retorna:
    - {:ok, equipo_actualizado} si se agrega correctamente.
    - {:error, :ya_en_equipo} si el participante ya está en el equipo.
    - {:error, razón} si ocurre otro error.
  """
  def agregar_participante(nombre_equipo, %Participant{} = participante) do
    with {:ok, equipo} <- obtener_equipo(nombre_equipo),
         false <- participante_en_equipo?(equipo, participante.id) do
      equipo_actualizado = %{
        equipo
        | participantes: [participante.id | equipo.participantes]
      }

      TeamStore.guardar_equipo(equipo_actualizado)
      ParticipantManager.actualizar_equipo(participante.id, equipo.id)

      BroadcastService.notificar(:equipo_actualizado, equipo_actualizado)

      {:ok, equipo_actualizado}
    else
      true -> {:error, :ya_en_equipo}
      error -> error
    end
  end

  @doc """
  Permite a un participante unirse a un equipo existente.
  Parámetros:
    - nombre_equipo: Nombre del equipo (string).
    - participante: Struct Participant del participante que desea unirse.
  Retorna:
    - {:ok, equipo_actualizado} si la unión es exitosa.
    - {:error, :ya_es_miembro} si el participante ya es miembro del equipo.
    - {:error, razón} si ocurre otro error.
  """
  def unirse_a_equipo(nombre_equipo, participante) do
    with {:ok, usuario} <- ParticipantManager.obtener_participante(participante.id),
         {:ok, equipo} <- obtener_equipo(nombre_equipo),
         false <- participante_en_equipo?(equipo, usuario.id) do
      equipo_actualizado = %{
        equipo
        | participantes: [usuario.id | equipo.participantes]
      }

      TeamStore.guardar_equipo(equipo_actualizado)
      ParticipantManager.actualizar_equipo(usuario.id, equipo.id)

      BroadcastService.notificar(:miembro_unido, equipo_actualizado)

      {:ok, equipo_actualizado}
    else
      true -> {:error, :ya_es_miembro}
      err -> err
    end
  end

  @doc """
  Remueve un participante de un equipo.
  Parámetros:
    - nombre_equipo: Nombre del equipo (string).
    - id_usuario: ID del participante a remover (string).
  Retorna:
    - {:ok, equipo_actualizado} si se remueve correctamente.
    - {:error, razón} si ocurre un error.
  """
  def remover_participante(nombre_equipo, id_usuario) do
    with {:ok, equipo} <- obtener_equipo(nombre_equipo) do
      nuevos =
        Enum.reject(equipo.participantes, fn id -> id == id_usuario end)

      equipo_actualizado = %{equipo | participantes: nuevos}

      TeamStore.guardar_equipo(equipo_actualizado)
      ParticipantManager.actualizar_equipo(id_usuario, nil)

      BroadcastService.notificar(:equipo_actualizado, equipo_actualizado)

      {:ok, equipo_actualizado}
    else
      err -> err
    end
  end

  # ============================================================
  # ESTADO DEL EQUIPO
  # ============================================================

  @doc """
  Función para disolver un equipo (marcar como inactivo).
  Requiere permiso :disolver_equipo.
  Parámetros:
    - nombre_equipo: Nombre del equipo a disolver (string).
  Retorna:
    - {:ok, :equipo_disuelto} si la disolución es exitosa.
    - {:error, :permiso_denegado} si el usuario no tiene permiso.
    - {:error, razón} si ocurre otro error.
  """
  def disolver_equipo(nombre_equipo) do
    with {:ok, usuario} <- SessionManager.obtener_participante_actual(),
         true <- PermissionService.autorizado?(usuario.id, :disolver_equipo),
         {:ok, equipo} <- obtener_equipo(nombre_equipo) do
      equipo_actualizado = %{equipo | estado: :inactivo}

      TeamStore.guardar_equipo(equipo_actualizado)
      BroadcastService.notificar(:equipo_disuelto, equipo_actualizado)

      {:ok, :equipo_disuelto}
    else
      false -> {:error, :permiso_denegado}
      err -> err
    end
  end

  # ============================================================
  # MENTOR Y PROYECTO
  # ============================================================

  @doc """
  Asigna un mentor a un equipo.
  Requiere permiso :asignar_mentor.
  Parámetros:
    - nombre_equipo: Nombre del equipo (string).
    - id_mentor: ID del mentor a asignar (string).
  Retorna:
    - {:ok, equipo_actualizado} si la asignación es exitosa.
    - {:error, :permiso_denegado} si el usuario no tiene permiso.
    - {:error, razón} si ocurre otro error.
  """
  def asignar_mentor(nombre_equipo, id_mentor) do
    with {:ok, usuario} <- SessionManager.obtener_participante_actual(),
         true <- PermissionService.autorizado?(usuario.id, :asignar_mentor),
         {:ok, equipo} <- obtener_equipo(nombre_equipo) do
      actualizado = %{equipo | id_mentor: id_mentor}

      TeamStore.guardar_equipo(actualizado)
      BroadcastService.notificar(:mentor_asignado, actualizado)

      {:ok, actualizado}
    else
      false -> {:error, :permiso_denegado}
      err -> err
    end
  end

  @doc """
  Vincula un proyecto a un equipo.
  Parámetros:
    - nombre_equipo: Nombre del equipo (string).
    - id_proyecto: ID del proyecto a vincular (string).
  Retorna:
    - {:ok, equipo_actualizado} si la vinculación es exitosa.
    - {:error, razón} si ocurre un error.
  """
  def vincular_proyecto(nombre_equipo, id_proyecto) do
    with {:ok, equipo} <- obtener_equipo(nombre_equipo) do
      actualizado = %{equipo | id_proyecto: id_proyecto}

      TeamStore.guardar_equipo(actualizado)
      BroadcastService.notificar(:proyecto_vinculado, actualizado)

      {:ok, actualizado}
    else
      err -> err
    end
  end

  # ============================================================
  # AUXILIAR
  # ============================================================

  @doc false
  defp participante_en_equipo?(equipo, participante_id) do
    Enum.member?(equipo.participantes, participante_id)
  end
end

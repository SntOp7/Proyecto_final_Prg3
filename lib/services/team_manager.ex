defmodule ProyectoFinalPrg3.Services.TeamManager do
  @moduledoc """
  Servicio oficial de gestión de equipos.
  Totalmente alineado con el struct Team sin campos extra
  (sin canal_chat_id, sin puntaje, sin historial).
  """

  alias ProyectoFinalPrg3.Domain.{Team, Participant}
  alias ProyectoFinalPrg3.Adapters.Persistence.TeamStore
  alias ProyectoFinalPrg3.Adapters.Security.SessionManager

  alias ProyectoFinalPrg3.Services.{
    AuthService,
    BroadcastService,
    ParticipantManager,
    PermissionService
  }

  # ============================================================
  # CREAR EQUIPO
  # ============================================================

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
              nil,     # id_proyecto
              nil,     # id_mentor
              [],      # participantes
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

  # ============================================================
  # CONSULTA
  # ============================================================

  def listar_equipos, do: TeamStore.listar_equipos()

  def obtener_equipo(nombre) do
    case TeamStore.obtener_equipo(nombre) do
      nil -> {:error, :no_encontrado}
      eq -> {:ok, eq}
    end
  end

  def obtener_por_id(id) do
    case TeamStore.obtener_equipo_por_id(id) do
      nil -> {:error, :no_encontrado}
      eq -> {:ok, eq}
    end
  end

  # ============================================================
  # PARTICIPANTES
  # ============================================================

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

  def unirse_a_equipo(nombre_equipo, participante) do
    with {:ok, usuario} <- AuthService.obtener_participante(participante.id),
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

  defp participante_en_equipo?(equipo, participante_id) do
    Enum.member?(equipo.participantes, participante_id)
  end
end

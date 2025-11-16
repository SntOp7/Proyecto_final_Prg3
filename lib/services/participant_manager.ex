defmodule ProyectoFinalPrg3.Services.ParticipantManager do
  @moduledoc """
  Servicio encargado de gestionar participantes dentro del sistema de hackathon.

  Permite registrar, actualizar, consultar y eliminar participantes, además de
  administrar roles, estados, equipos y mensajes enviados.

  Autores: Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez
  Fecha de creación: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.Participant
  alias ProyectoFinalPrg3.Adapters.Persistence.ParticipantStore
  alias ProyectoFinalPrg3.Services.BroadcastService
  alias ProyectoFinalPrg3.Adapters.Security.EncryptionAdapter
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # ============================================================
  # REGISTRO
  # ============================================================

  @doc """
  Registra un nuevo participante usando correo como identificador único.
  Genera un hash de la contraseña antes de guardarlo.
  """
  def registrar_participante(nombre, correo, username, contrasena, rol \\ "participante") do
    case ParticipantStore.buscar_por_correo(correo) do
      nil ->
        hash = EncryptionAdapter.cifrar(contrasena)

        participante =
          %Participant{
            id: UUID.uuid4(),
            nombre: nombre,
            correo: correo,
            username: username,
            contrasena: hash,
            rol: rol,
            equipo_id: nil,
            estado: :activo,
            mensajes: []
          }

        ParticipantStore.guardar_participante(participante)
        BroadcastService.notificar(:participante_registrado, participante)

        {:ok, participante}

      _ ->
        {:error, :correo_ya_registrado}
    end
  end

  # ============================================================
  # CONSULTAS
  # ============================================================

  @doc """
  Obtiene un participante por su ID.
  """
  def obtener_participante(id) do
    case ParticipantStore.obtener_participante(id) do
      nil -> {:error, :no_encontrado}
      p -> {:ok, p}
    end
  end

  @doc """
  Busca un participante por correo.
  """
  def buscar_por_correo(correo) do
    case ParticipantStore.buscar_por_correo(correo) do
      nil -> {:error, :no_encontrado}
      p -> {:ok, p}
    end
  end

  # ============================================================
  # ACTUALIZACIÓN
  # ============================================================

  @doc """
  Actualiza solo los campos permitidos (nombre, username, rol, estado, correo).
  """
  def actualizar_datos(id, cambios) when is_map(cambios) do
    with {:ok, participante} <- obtener_participante(id) do
      permitidos = Map.take(cambios, campos_validos())

      actualizado =
        participante
        |> Map.merge(permitidos)

      ParticipantStore.guardar_participante(actualizado)
      BroadcastService.notificar(:participante_actualizado, actualizado)

      {:ok, actualizado}
    end
  end

  defp campos_validos do
    [:nombre, :correo, :username, :rol, :estado]
  end

  @doc """
  Actualiza solo el campo `equipo_id` del participante.
  Usado por TeamManager para asignar o remover un participante de un equipo.
  """
  def actualizar_equipo(id_participante, nuevo_equipo_id) do
    actualizar_datos(id_participante, %{equipo_id: nuevo_equipo_id})
  end

  @doc """
  Actualiza el rol del participante.
  """
  def actualizar_rol(id, nuevo_rol),
    do: actualizar_datos(id, %{rol: nuevo_rol})

  @doc """
  Actualiza el estado del participante (:activo, :inactivo, :suspendido).
  """
  def actualizar_estado(id, estado),
    do: actualizar_datos(id, %{estado: estado})

  @doc """
  Asigna un participante a un equipo.
  """
  def asignar_equipo(id, equipo_id),
    do: actualizar_datos(id, %{equipo_id: equipo_id})

  @doc """
  Cambia la contraseña del participante, generando un nuevo hash.
  """
  def actualizar_contrasena(id, nueva_contra) do
    actualizar_datos(id, %{contrasena: EncryptionAdapter.cifrar(nueva_contra)})
  end

  # ============================================================
  # MENSAJERÍA
  # ============================================================

  @doc """
  Registra un mensaje enviado por el participante.
  """
  def registrar_mensaje(id, contenido) do
    with {:ok, participante} <- obtener_participante(id) do
      mensaje = %{
        contenido: contenido,
        timestamp: DateTime.utc_now()
      }

      nuevos_mensajes = [mensaje | participante.mensajes]

      actualizar_datos(id, %{mensajes: nuevos_mensajes})
    end
  end

  @doc """
  Obtiene el historial de mensajes enviados por un participante.
  """
  def obtener_mensajes(id) do
    with {:ok, participante} <- obtener_participante(id) do
      {:ok, participante.mensajes}
    end
  end

  # ============================================================
  # ELIMINACIÓN
  # ============================================================

  @doc """
  Elimina un participante por su ID.
  """
  def eliminar_participante(id) do
    BroadcastService.notificar(:participante_eliminado, %{id: id})
    LoggerService.registrar_evento("Participante eliminado", %{id: id})
    {:ok, :eliminado}
  end

  # ============================================================
  # FILTROS
  # ============================================================

  @doc """
  Devuelve los participantes con el rol indicado.
  """
  def filtrar_por_rol(rol) do
    listar_participantes()
    |> Enum.filter(&(&1.rol == rol))
  end

  @doc """
  Devuelve los participantes que no tienen equipo asignado.
  """
  def sin_equipo do
    listar_participantes()
    |> Enum.filter(&is_nil(&1.equipo_id))
  end

  # ============================================================
  # AUXILIARES
  # ============================================================

  @doc """
  Verifica si un participante existe.
  """
  def participante_existe?(id), do: match?({:ok, _}, obtener_participante(id))

  def listar_participantes do
    ProyectoFinalPrg3.Adapters.Persistence.ParticipantStore.listar_participantes()
  end
end

defmodule ProyectoFinalPrg3.Services.ParticipantManager do
  @moduledoc """
  Servicio de gestión de participantes dentro del sistema de hackathon.
  Permite registrar, consultar, actualizar y eliminar participantes, además de
  gestionar sus canales, tokens, experiencia y estado de conexión.

  Se comunica con la capa de persistencia (`ParticipantStore`) y otros servicios
  como `AuthService` o `BroadcastService`.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.Participant
  alias ProyectoFinalPrg3.Adapters.Persistence.ParticipantStore
  alias ProyectoFinalPrg3.Services.BroadcastService

  # ============================================================
  # FUNCIONES PRINCIPALES DE GESTIÓN DE PARTICIPANTES
  # ============================================================

  @doc """
  Registra un nuevo participante con todos los campos relevantes.
  """
  def registrar_participante(nombre, correo, username, rol \\ "participante", experiencia \\ "N/A") do
    case ParticipantStore.buscar_por_correo(correo) do
      nil ->
        participante = %Participant{
          id: UUID.uuid4(),
          nombre: nombre,
          correo: correo,
          username: username,
          rol: rol,
          equipo_id: nil,
          experiencia: experiencia,
          fecha_registro: DateTime.utc_now(),
          estado: :activo,
          ultima_conexion: nil,
          mensajes: [],
          canales_asignados: [],
          token_sesion: nil,
          perfil_url: nil
        }

        ParticipantStore.guardar_participante(participante)
        BroadcastService.notificar(:participante_registrado, participante)
        {:ok, participante}

      _existente ->
        {:error, :correo_ya_registrado}
    end
  end

  @doc """
  Lista todos los participantes registrados.
  """
  def listar_participantes do
    ParticipantStore.listar_participantes()
  end

  @doc """
  Obtiene un participante por su ID.
  """
  def obtener_participante(id_participante) do
    case ParticipantStore.obtener_participante(id_participante) do
      nil -> {:error, :no_encontrado}
      participante -> {:ok, participante}
    end
  end

  @doc """
  Busca un participante por su correo electrónico.
  """
  def buscar_por_correo(correo) do
    case ParticipantStore.buscar_por_correo(correo) do
      nil -> {:error, :no_encontrado}
      participante -> {:ok, participante}
    end
  end

  # ============================================================
  # FUNCIONES DE ACTUALIZACIÓN Y PERFIL
  # ============================================================

  @doc """
  Actualiza datos generales del participante (nombre, rol, experiencia, etc.).
  """
  def actualizar_datos(id_participante, nuevos_datos) when is_map(nuevos_datos) do
    with {:ok, participante} <- obtener_participante(id_participante) do
      actualizado =
        participante
        |> Map.merge(nuevos_datos)
        |> Map.put(:ultima_conexion, DateTime.utc_now())

      ParticipantStore.guardar_participante(actualizado)
      BroadcastService.notificar(:participante_actualizado, actualizado)
      {:ok, actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Actualiza la experiencia o descripción del participante.
  """
  def actualizar_experiencia(id_participante, nueva_exp) do
    actualizar_datos(id_participante, %{experiencia: nueva_exp})
  end

  @doc """
  Cambia el rol del participante (por ejemplo, de participante a mentor).
  """
  def actualizar_rol(id_participante, nuevo_rol) do
    actualizar_datos(id_participante, %{rol: nuevo_rol})
  end

  @doc """
  Actualiza el estado actual del participante (:activo, :desconectado, :pendiente).
  """
  def actualizar_estado(id_participante, nuevo_estado) do
    actualizar_datos(id_participante, %{estado: nuevo_estado})
  end

  @doc """
  Actualiza el enlace de perfil público o imagen del participante.
  """
  def actualizar_perfil(id_participante, nueva_url) do
    actualizar_datos(id_participante, %{perfil_url: nueva_url})
  end

  @doc """
  Actualiza el token de sesión de un participante autenticado.
  """
  def asignar_token(id_participante, token) do
    actualizar_datos(id_participante, %{token_sesion: token})
  end

  @doc """
  Actualiza la fecha y hora de última conexión del participante.
  """
  def registrar_conexion(id_participante) do
    actualizar_datos(id_participante, %{ultima_conexion: DateTime.utc_now(), estado: :activo})
  end

  # ============================================================
  # FUNCIONES RELACIONADAS CON EQUIPOS Y CANALES
  # ============================================================

  @doc """
  Actualiza el equipo al que pertenece el participante.
  """
  def actualizar_equipo(id_participante, id_equipo) do
    actualizar_datos(id_participante, %{equipo_id: id_equipo})
  end

  @doc """
  Añade un canal a la lista de canales asignados al participante.
  """
  def asignar_canal(id_participante, canal_id) do
    with {:ok, participante} <- obtener_participante(id_participante) do
      nuevos_canales = Enum.uniq([canal_id | participante.canales_asignados])
      actualizar_datos(id_participante, %{canales_asignados: nuevos_canales})
    end
  end

  @doc """
  Elimina un canal de la lista de canales asignados al participante.
  """
  def remover_canal(id_participante, canal_id) do
    with {:ok, participante} <- obtener_participante(id_participante) do
      nuevos_canales = Enum.reject(participante.canales_asignados, &(&1 == canal_id))
      actualizar_datos(id_participante, %{canales_asignados: nuevos_canales})
    end
  end

  @doc """
  Registra un nuevo mensaje enviado por el participante.
  """
  def registrar_mensaje(id_participante, mensaje) do
    with {:ok, participante} <- obtener_participante(id_participante) do
      nuevos_mensajes = [%{mensaje: mensaje, timestamp: DateTime.utc_now()} | participante.mensajes]
      actualizar_datos(id_participante, %{mensajes: nuevos_mensajes})
    end
  end

  # ============================================================
  # FUNCIONES DE ELIMINACIÓN Y FILTRADO
  # ============================================================

  @doc """
  Elimina un participante del sistema.
  """
  def eliminar_participante(id_participante) do
    case ParticipantStore.eliminar_participante(id_participante) do
      :ok ->
        BroadcastService.notificar(:participante_eliminado, id_participante)
        {:ok, :eliminado}

      {:error, razon} ->
        {:error, razon}
    end
  end

  @doc """
  Filtra los participantes por rol.
  """
  def filtrar_por_rol(rol) do
    listar_participantes()
    |> Enum.filter(&(&1.rol == rol))
  end

  @doc """
  Lista los participantes que no pertenecen a ningún equipo.
  """
  def sin_equipo do
    listar_participantes()
    |> Enum.filter(&is_nil(&1.equipo_id))
  end

  # ============================================================
  # FUNCIONES AUXILIARES
  # ============================================================

  @doc false
  def participante_existe?(id_participante) do
    case obtener_participante(id_participante) do
      {:ok, _} -> true
      _ -> false
    end
  end
end

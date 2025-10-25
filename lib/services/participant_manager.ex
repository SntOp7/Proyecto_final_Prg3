defmodule ProyectoFinalPrg3.Services.ParticipantManager do
  @moduledoc """
  Módulo encargado de la gestión de participantes dentro del sistema de hackathon.
  Permite registrar, consultar, actualizar y eliminar participantes, así como administrar
  su asociación con equipos y roles dentro de la plataforma.

  Este servicio se comunica con la capa de persistencia (`ParticipantStore`)
  y otros servicios relacionados como `AuthService` o `TeamManager`.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-25
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.Participant
  alias ProyectoFinalPrg3.Adapters.Persistence.ParticipantStore
  alias ProyectoFinalPrg3.Services.BroadcastService

  # ============================================================
  # FUNCIONES PRINCIPALES DE GESTIÓN DE PARTICIPANTES
  # ============================================================

  @doc """
  Registra un nuevo participante en el sistema con los datos básicos.
  Genera un identificador único y lo almacena en el repositorio.
  """
  def registrar_participante(nombre, correo, rol \\ "participante") do
    case ParticipantStore.buscar_por_correo(correo) do
      nil ->
        participante = %Participant{
          id: UUID.uuid4(),
          nombre: nombre,
          correo: correo,
          rol: rol,
          equipo_id: nil,
          sesion_activa: false
        }

        ParticipantStore.guardar_participante(participante)
        BroadcastService.notificar(:participante_registrado, participante)
        {:ok, participante}

      _existente ->
        {:error, :correo_ya_registrado}
    end
  end

  @doc """
  Lista todos los participantes registrados en el sistema.
  """
  def listar_participantes do
    ParticipantStore.listar_participantes()
  end

  @doc """
  Obtiene un participante a partir de su identificador.
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
  # FUNCIONES DE ACTUALIZACIÓN
  # ============================================================

  @doc """
  Actualiza los datos de un participante (nombre, rol, etc.).
  """
  def actualizar_datos(id_participante, nuevos_datos) when is_map(nuevos_datos) do
    with {:ok, participante} <- obtener_participante(id_participante) do
      actualizado = Map.merge(participante, nuevos_datos)
      ParticipantStore.guardar_participante(actualizado)
      BroadcastService.notificar(:participante_actualizado, actualizado)
      {:ok, actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Actualiza el identificador del equipo al que pertenece un participante.
  """
  def actualizar_equipo(id_participante, id_equipo) do
    with {:ok, participante} <- obtener_participante(id_participante) do
      actualizado = %{participante | equipo_id: id_equipo}
      ParticipantStore.guardar_participante(actualizado)
      BroadcastService.notificar(:equipo_actualizado_participante, actualizado)
      {:ok, actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Cambia el rol de un participante (por ejemplo, de "participante" a "mentor").
  """
  def actualizar_rol(id_participante, nuevo_rol) do
    with {:ok, participante} <- obtener_participante(id_participante) do
      actualizado = %{participante | rol: nuevo_rol}
      ParticipantStore.guardar_participante(actualizado)
      BroadcastService.notificar(:rol_cambiado, actualizado)
      {:ok, actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  # ============================================================
  # FUNCIONES DE ELIMINACIÓN Y FILTRADO
  # ============================================================

  @doc """
  Elimina un participante del sistema por su ID.
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
  Filtra los participantes por rol (ej. "mentor", "participante", "admin").
  """
  def filtrar_por_rol(rol) do
    listar_participantes()
    |> Enum.filter(&(&1.rol == rol))
  end

  @doc """
  Lista los participantes que no pertenecen actualmente a ningún equipo.
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

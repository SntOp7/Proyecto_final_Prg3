defmodule ProyectoFinalPrg3.Services.TeamManager do
  @moduledoc """
  Define la lógica de negocio y operaciones asociadas a la gestión de equipos dentro del sistema de hackathon.
  Gestiona la creación, actualización, listado, vinculación de proyectos, asignación de mentores,
  manejo de participantes, historial y canales de comunicación.

  Este módulo forma parte de la capa de servicios de la arquitectura hexagonal.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez].
  Fecha de creación: 2025-10-25
  Fecha de última modificación: 2025-10-26
  Licencia: GNU GPLv3
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
  # FUNCIONES PRINCIPALES DE GESTIÓN DE EQUIPOS
  # ============================================================

  @doc """
  Crea un nuevo equipo y lo registra en el sistema.
  Genera un ID único, asigna la fecha de creación y notifica a los servicios asociados.
  """
  def crear_equipo(nombre, categoria, descripcion) do
    if PermissionService.autorizado?(
         SessionManager.obtener_participante_actual().id,
         :crear_equipo
       ) do
      case TeamStore.obtener_equipo(nombre) do
        nil ->
          equipo = %Team{
            id: UUID.uuid4(),
            nombre: nombre,
            descripcion: descripcion,
            categoria: categoria,
            id_proyecto: nil,
            id_mentor: nil,
            participantes: [],
            fecha_creacion: DateTime.utc_now(),
            estado: :activo,
            canal_chat_id: nil,
            puntaje: 0,
            historial: []
          }

          TeamStore.guardar_equipo(equipo)
          BroadcastService.notificar(:equipo_creado, equipo)
          {:ok, equipo}

        _existente ->
          {:error, :equipo_ya_existente}
      end
    else
      {:error, :permiso_denegado}
    end
  end

  @doc """
  Actualiza la información completa de un equipo existente.
  """
  def actualizar_equipo(%Team{} = equipo) do
    TeamStore.guardar_equipo(equipo)
    BroadcastService.notificar(:equipo_actualizado, equipo)
    {:ok, equipo}
  end

  @doc """
  Agrega un participante a un equipo, verificando que no exista previamente.
  También actualiza la información del participante.
  """
  def agregar_participante(nombre_equipo, participante = %Participant{}) do
    with {:ok, equipo} <- obtener_equipo(nombre_equipo),
         false <- participante_en_equipo?(equipo, participante.id) do
      participante_actualizado = %{participante | equipo_id: equipo.id}

      equipo_actualizado = %{
        equipo
        | participantes: [participante_actualizado | equipo.participantes]
      }

      TeamStore.guardar_equipo(equipo_actualizado)
      ParticipantManager.actualizar_equipo(participante.id, equipo.id)
      BroadcastService.notificar(:equipo_actualizado, equipo_actualizado)

      {:ok, equipo_actualizado}
    else
      true -> {:error, :ya_en_equipo}
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Permite que un participante autenticado se una a un equipo existente.
  """
  def unirse_a_equipo(nombre_equipo, id_participante) do
    with {:ok, usuario} <- AuthService.obtener_participante(id_participante),
         {:ok, equipo} <- obtener_equipo(nombre_equipo),
         false <- participante_en_equipo?(equipo, id_participante) do
      usuario_actualizado = %{usuario | equipo_id: equipo.id}
      equipo_actualizado = %{equipo | participantes: [usuario_actualizado | equipo.participantes]}

      TeamStore.guardar_equipo(equipo_actualizado)
      ParticipantManager.actualizar_equipo(usuario.id, equipo.id)
      BroadcastService.notificar(:miembro_unido, equipo_actualizado)

      {:ok, equipo_actualizado}
    else
      true -> {:error, :ya_es_miembro}
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Remueve un participante de un equipo.
  """
  def remover_participante(nombre_equipo, id_participante) do
    with {:ok, equipo} <- obtener_equipo(nombre_equipo) do
      nuevos_participantes =
        Enum.reject(equipo.participantes, fn p -> p.id == id_participante end)

      equipo_actualizado = %{equipo | participantes: nuevos_participantes}

      TeamStore.guardar_equipo(equipo_actualizado)
      ParticipantManager.actualizar_equipo(id_participante, nil)
      BroadcastService.notificar(:equipo_actualizado, equipo_actualizado)

      {:ok, equipo_actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Disuelve un equipo (marca su estado como inactivo y notifica el cambio).
  """
  def disolver_equipo(nombre_equipo) do
    if PermissionService.autorizado?(
         SessionManager.obtener_participante_actual().id,
         :disolver_equipo
       ) do
      with {:ok, equipo} <- obtener_equipo(nombre_equipo) do
        equipo_actualizado = %{equipo | estado: :inactivo}
        TeamStore.guardar_equipo(equipo_actualizado)
        BroadcastService.notificar(:equipo_disuelto, equipo_actualizado)
        {:ok, :equipo_disuelto}
      else
        {:error, razon} -> {:error, razon}
      end
    else
      {:error, :permiso_denegado}
    end
  end

  # ============================================================
  # FUNCIONES DE CONSULTA Y FILTRADO
  # ============================================================

  @doc """
  Lista todos los equipos registrados.
  """
  def listar_equipos, do: TeamStore.listar_equipos()

  @doc """
  Obtiene un equipo por su nombre.
  """
  def obtener_equipo(nombre) do
    case TeamStore.obtener_equipo(nombre) do
      nil -> {:error, :no_encontrado}
      equipo -> {:ok, equipo}
    end
  end

  @doc """
  Obtiene un equipo por su ID único.
  """
  def obtener_por_id(id) do
    case TeamStore.obtener_equipo_por_id(id) do
      nil -> {:error, :no_encontrado}
      equipo -> {:ok, equipo}
    end
  end

  @doc """
  Filtra los equipos por categoría o estado.
  """
  def filtrar_equipos(filtro, valor) do
    equipos = TeamStore.listar_equipos()

    case filtro do
      :categoria -> Enum.filter(equipos, &(&1.categoria == valor))
      :estado -> Enum.filter(equipos, &(&1.estado == valor))
      _ -> equipos
    end
  end

  @doc """
  Verifica si un equipo está activo.
  """
  def equipo_activo?(nombre_equipo) do
    with {:ok, equipo} <- obtener_equipo(nombre_equipo) do
      equipo.estado == :activo
    else
      _ -> false
    end
  end

  # ============================================================
  # FUNCIONES DE MENTORÍA Y PROYECTOS
  # ============================================================

  @doc """
  Asigna o actualiza el mentor de un equipo.
  """
  def asignar_mentor(nombre_equipo, id_mentor) do
    if PermissionService.autorizado?(
         SessionManager.obtener_participante_actual().id,
         :asignar_mentor
       ) do
      with {:ok, equipo} <- obtener_equipo(nombre_equipo) do
        equipo_actualizado = %{equipo | id_mentor: id_mentor}
        TeamStore.guardar_equipo(equipo_actualizado)
        BroadcastService.notificar(:mentor_asignado, equipo_actualizado)
        {:ok, equipo_actualizado}
      else
        {:error, razon} -> {:error, razon}
      end
    else
      {:error, :permiso_denegado}
    end
  end

  @doc """
  Vincula un proyecto existente al equipo mediante su ID.
  """
  def vincular_proyecto(nombre_equipo, id_proyecto) do
    with {:ok, equipo} <- obtener_equipo(nombre_equipo) do
      equipo_actualizado = %{equipo | id_proyecto: id_proyecto}
      TeamStore.guardar_equipo(equipo_actualizado)
      BroadcastService.notificar(:proyecto_vinculado, equipo_actualizado)
      {:ok, equipo_actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  # ============================================================
  # FUNCIONES DE EVALUACIÓN Y PUNTAJE
  # ============================================================

  @doc """
  Actualiza el puntaje global del equipo tras una evaluación.
  """
  def actualizar_puntaje(nombre_equipo, nuevo_puntaje) do
    with {:ok, equipo} <- obtener_equipo(nombre_equipo) do
      equipo_actualizado = %{equipo | puntaje: nuevo_puntaje}
      TeamStore.guardar_equipo(equipo_actualizado)
      BroadcastService.notificar(:puntaje_actualizado, equipo_actualizado)
      {:ok, equipo_actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  # ============================================================
  # FUNCIONES DE HISTORIAL Y TRAZABILIDAD
  # ============================================================

  @doc """
  Registra un evento o acción en el historial del equipo.
  """
  def registrar_evento(nombre_equipo, evento) do
    with {:ok, equipo} <- obtener_equipo(nombre_equipo) do
      historial_actualizado = [
        %{timestamp: DateTime.utc_now(), detalle: evento} | equipo.historial
      ]

      equipo_actualizado = %{equipo | historial: historial_actualizado}
      TeamStore.guardar_equipo(equipo_actualizado)
      {:ok, equipo_actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Obtiene el historial completo de eventos de un equipo.
  """
  def obtener_historial(nombre_equipo) do
    with {:ok, equipo} <- obtener_equipo(nombre_equipo) do
      {:ok, equipo.historial}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  # ============================================================
  # FUNCIONES DE COMUNICACIÓN
  # ============================================================

  @doc """
  Asigna o actualiza el canal de chat del equipo.
  """
  def asignar_canal_chat(nombre_equipo, canal_id) do
    with {:ok, equipo} <- obtener_equipo(nombre_equipo) do
      equipo_actualizado = %{equipo | canal_chat_id: canal_id}
      TeamStore.guardar_equipo(equipo_actualizado)
      BroadcastService.notificar(:canal_chat_asignado, equipo_actualizado)
      {:ok, equipo_actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Envía un mensaje de notificación a todos los miembros del equipo.
  """
  def notificar_equipo(equipo, mensaje) do
    BroadcastService.notificar(:mensaje_equipo, %{equipo: equipo.nombre, contenido: mensaje})
    {:ok, :mensaje_enviado}
  end

  # ============================================================
  # FUNCIONES AUXILIARES
  # ============================================================

  @doc false
  defp participante_en_equipo?(equipo, id_participante),
    do: Enum.any?(equipo.participantes, fn p -> p.id == id_participante end)
end

defmodule ProyectoFinalPrg3.Services.TeamManager do
  @moduledoc """
  Define la lógica y las operaciones asociadas a la gestión de equipos dentro del sistema de hackathon.
  Permite crear, listar, actualizar y eliminar equipos, así como administrar participantes,
  mentores, proyectos asociados, canales de comunicación, historial de eventos y puntajes de evaluación.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-25
  Fecha de última modificación: 2025-10-25
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.{Team, Participant}
  alias ProyectoFinalPrg3.Adapters.Persistence.TeamStore
  alias ProyectoFinalPrg3.Services.{AuthService, BroadcastService, ParticipantManager}

  # ============================================================
  # FUNCIONES PRINCIPALES DE GESTIÓN DE EQUIPOS
  # ============================================================

  @doc """
  Crea un nuevo equipo con sus atributos principales y lo registra en el sistema.
  Genera un identificador único, establece la fecha de creación y notifica a los servicios correspondientes.
  """
  def crear_equipo(nombre, categoria, descripcion) do
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
  end

  @doc """
  Agrega un participante a un equipo, validando su pertenencia previa y actualizando su información.
  """
  def agregar_participante(nombre_equipo, participante = %Participant{}) do
    with {:ok, equipo} <- obtener_equipo(nombre_equipo),
         false <- participante_en_equipo?(equipo, participante.id) do
      participante_actualizado = %{participante | equipo_id: equipo.id}
      equipo_actualizado = %{equipo | participantes: [participante_actualizado | equipo.participantes]}

      TeamStore.guardar_equipo(equipo_actualizado)
      ParticipantManager.actualizar_equipo(participante.id, equipo.id)
      BroadcastService.notificar(:equipo_actualizado, equipo_actualizado)

      {:ok, equipo_actualizado}
    else
      true -> {:error, :ya_en_equipo}
      {:error, razon} -> {:error, razon}
      nil -> {:error, :equipo_no_encontrado}
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
  Remueve un participante de un equipo y actualiza la información persistida.
  """
  def remover_participante(nombre_equipo, id_participante) do
    with {:ok, equipo} <- obtener_equipo(nombre_equipo) do
      nuevos_participantes = Enum.reject(equipo.participantes, fn p -> p.id == id_participante end)
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
  Disuelve un equipo: cambia su estado a inactivo, lo guarda y notifica a los servicios asociados.
  """
  def disolver_equipo(nombre_equipo) do
    with {:ok, equipo} <- obtener_equipo(nombre_equipo) do
      equipo_actualizado = %{equipo | estado: :inactivo}
      TeamStore.guardar_equipo(equipo_actualizado)
      BroadcastService.notificar(:equipo_disuelto, equipo_actualizado)
      {:ok, :equipo_disuelto}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  # ============================================================
  # FUNCIONES DE CONSULTA Y FILTRADO
  # ============================================================

  @doc """
  Lista todos los equipos registrados en el sistema.
  """
  def listar_equipos do
    TeamStore.listar_equipos()
  end

  @doc """
  Obtiene los datos completos de un equipo a partir de su nombre.
  """
  def obtener_equipo(nombre) do
    case TeamStore.obtener_equipo(nombre) do
      nil -> {:error, :no_encontrado}
      equipo -> {:ok, equipo}
    end
  end

  @doc """
  Filtra los equipos según una categoría o estado determinado.
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
  Verifica si un equipo se encuentra activo.
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
  Asigna o actualiza el mentor responsable de un equipo.
  """
  def asignar_mentor(nombre_equipo, id_mentor) do
    with {:ok, equipo} <- obtener_equipo(nombre_equipo) do
      equipo_actualizado = %{equipo | id_mentor: id_mentor}
      TeamStore.guardar_equipo(equipo_actualizado)
      BroadcastService.notificar(:mentor_asignado, equipo_actualizado)
      {:ok, equipo_actualizado}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Vincula un proyecto existente al equipo mediante su identificador.
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
  Actualiza el puntaje del equipo tras un proceso de evaluación o retroalimentación.
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
  Obtiene el historial de eventos o acciones asociadas a un equipo.
  """
  def obtener_historial(nombre_equipo) do
    with {:ok, equipo} <- obtener_equipo(nombre_equipo) do
      {:ok, equipo.historial}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  # ============================================================
  # FUNCIONES DE COMUNICACIÓN Y CANALES
  # ============================================================

  @doc """
  Asigna o actualiza el canal de chat del equipo dentro del sistema de comunicación.
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
  Envía un mensaje o notificación a todos los miembros de un equipo.
  """
  def notificar_equipo(equipo, mensaje) do
    BroadcastService.notificar(:mensaje_equipo, %{equipo: equipo.nombre, contenido: mensaje})
    {:ok, :mensaje_enviado}
  end

  # ============================================================
  # FUNCIONES AUXILIARES
  # ============================================================

  @doc false
  defp participante_en_equipo?(equipo, id_participante) do
    Enum.any?(equipo.participantes, fn p -> p.id == id_participante end)
  end
end

defmodule ProyectoFinalPrg3.Services.ProgressManager do
  @moduledoc """
  Servicio de gestión de avances (progress) de proyectos.
  """

  alias ProyectoFinalPrg3.Domain.Progress
  alias ProyectoFinalPrg3.Adapters.Persistence.ProgressStore
  alias ProyectoFinalPrg3.Services.{BroadcastService, TeamManager, ProjectManager, ChatService}
  alias ProyectoFinalPrg3.Adapters.Security.SessionManager

  # ============================================================
  # CREAR AVANCE
  # ============================================================

  @doc """
  Registra un nuevo avance en un proyecto.
  """
  def registrar_avance(proyecto_nombre, titulo, descripcion, version \\ "1.0") do
    with {:ok, participante} <- SessionManager.obtener_participante_actual(),
         {:ok, proyecto} <- ProjectManager.obtener_proyecto(proyecto_nombre),
         {:ok, equipo} <- TeamManager.obtener_equipo_por_proyecto(proyecto.id),
         true <- participante.id in equipo.participantes do
      avance =
        Progress.nuevo(
          UUID.uuid4(),
          proyecto.id,
          equipo.id,
          titulo,
          descripcion,
          DateTime.utc_now(),
          participante.id,
          :pendiente,
          version
        )

      ProgressStore.guardar_avance(avance)
      BroadcastService.notificar(:avance_registrado, avance)

      # Notificar en el chat del equipo
      mensaje_chat = """
      📊 NUEVO AVANCE REGISTRADO
      👤 Autor: #{participante.nombre}
      📝 Título: #{titulo}
      📋 Descripción: #{descripcion}
      🔖 Versión: #{version}
      """

      ChatService.enviar_mensaje_sistema(equipo.nombre, mensaje_chat)

      {:ok, avance}
    else
      false -> {:error, "No perteneces al equipo de este proyecto."}
      error -> error
    end
  end

  # ============================================================
  # CONSULTAR AVANCES
  # ============================================================

  @doc """
  Lista todos los avances de un proyecto.
  """
  def listar_avances_proyecto(proyecto_nombre) do
    with {:ok, proyecto} <- ProjectManager.obtener_proyecto(proyecto_nombre) do
      avances =
        ProgressStore.listar_por_proyecto(proyecto.id)
        |> Enum.sort_by(& &1.fecha_registro, {:desc, DateTime})

      {:ok, avances}
    end
  end

  @doc """
  Obtiene un avance específico por ID.
  """
  def obtener_avance(id) do
    ProgressStore.obtener_avance(id)
  end

  # ============================================================
  # ACTUALIZAR ESTADO
  # ============================================================

  @doc """
  Actualiza el estado de un avance (pendiente -> revisión -> aprobado).
  """
  def actualizar_estado(avance_id, nuevo_estado)
      when nuevo_estado in [:pendiente, :revision, :aprobado] do
    with {:ok, avance} <- obtener_avance(avance_id) do
      avance_actualizado = %{avance | estado: nuevo_estado}

      ProgressStore.guardar_avance(avance_actualizado)
      BroadcastService.notificar(:avance_actualizado, avance_actualizado)

      {:ok, avance_actualizado}
    end
  end

  # ============================================================
  # RETROALIMENTACIÓN
  # ============================================================

  @doc """
  Agrega retroalimentación a un avance (usualmente por mentores).
  """
  def agregar_retroalimentacion(avance_id, retroalimentacion) do
    with {:ok, mentor} <- SessionManager.obtener_participante_actual(),
         {:ok, avance} <- obtener_avance(avance_id),
         {:ok, equipo} <- TeamManager.obtener_por_id(avance.equipo_id) do
      avance_actualizado = %{avance | retroalimentacion: retroalimentacion}

      ProgressStore.guardar_avance(avance_actualizado)
      BroadcastService.notificar(:retroalimentacion_agregada, avance_actualizado)

      # Notificar en el chat
      mensaje_chat = """
      💬 RETROALIMENTACIÓN EN AVANCE
      👨‍🏫 Mentor: #{mentor.nombre}
      📝 Avance: #{avance.titulo}
      💭 Comentario: #{retroalimentacion}
      """

      ChatService.enviar_mensaje_sistema(equipo.nombre, mensaje_chat)

      {:ok, avance_actualizado}
    end
  end
end

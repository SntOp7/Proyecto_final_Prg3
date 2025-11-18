defmodule ProyectoFinalPrg3.Services.BroadcastService do
  @moduledoc """
  Servicio responsable de la difusión de eventos y notificaciones dentro del sistema.
  Actúa como el bus central de comunicación entre módulos del dominio y adaptadores de red.

  Gestiona tres niveles de difusión:
    1. Local (logs y auditoría)
    2. Red (PubSub y ChannelManager)
    3. Distribuido (NodeManager, para sincronización entre nodos)

  Este módulo es usado por gestores como `TeamManager`, `ProjectManager`, `MentorManager`, etc.

  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  alias ProyectoFinalPrg3.Adapters.Network.{PubSubAdapter, ChannelManager, NodeManager}
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService
  alias ProyectoFinalPrg3.Services.MetricsService

  # ==========================================
  # UTILIDADES DE NODO
  # ==========================================

  @central Application.compile_env(:proyecto_final_prg3, :central_node)

  @doc false
  defp soy_central? do
    Node.self() == @central
  end

  @doc false
  defp reenviar_al_central(fun, args) do
    :rpc.call(@central, __MODULE__, fun, args)
  end

  # ============================================================
  # DIFUSIÓN DE EVENTOS
  # ============================================================

  @doc """
  Envía una notificación general del sistema.
  Es la forma estándar de propagar eventos como `:proyecto_creado` o `:equipo_actualizado`.

  ## Ejemplo:
      BroadcastService.notificar(:proyecto_creado, %{nombre: "SmartHub", categoria: "IA"})
  ## Parámetros:
    - evento: Átomo que identifica el evento.
    - data: Datos asociados al evento (mapa o cualquier estructura).
    - tipo: Tipo de notificación (:info, :warning, :error, etc.).
  ## Retorna:
    - {:ok, mensaje} con el contenido de la notificación.
  """
  def notificar(evento, data, tipo \\ :info) when is_atom(evento) do
    mensaje = construir_mensaje(tipo, evento, data)

    LoggerService.registrar_evento("Difusión: #{evento}", mensaje)

    {:ok, mensaje}
  end

  @doc """
  Envía un mensaje directo a un destino específico (por ejemplo, a un canal o a un nodo).
  Útil para comunicaciones puntuales o privadas.
  ## Parámetros:
    - destino: Identificador del destino (string o átomo).
    - mensaje: Contenido del mensaje (cualquier estructura).
    - tipo: Tipo de mensaje (:directo, :notificación, etc.).
  ## Retorna:
    - {:ok, payload} con el contenido enviado.
  """
  def enviar_directo(destino, mensaje, tipo \\ :directo) do
    payload = %{
      tipo: tipo,
      destino: destino,
      contenido: mensaje,
      timestamp: DateTime.utc_now(),
      nodo: Atom.to_string(Node.self())
    }

    LoggerService.registrar_evento("Mensaje directo enviado", payload)

    # CLI y Persistencia → reenviar al nodo central
    if not soy_central?() do
      return = reenviar_al_central(:enviar_directo, [destino, mensaje, tipo])
      return
    else
      safe_broadcast(fn ->
        ChannelManager.enviar(destino, payload)
        NodeManager.enviar_directo(destino, payload)
      end)

      {:ok, payload}
    end
  end

  @doc """
  Notifica simultáneamente un mismo evento a múltiples destinos.
  Útil para difusión grupal (equipos, proyectos o mentores asignados).
  ## Parámetros:
    - evento: Átomo que identifica el evento.
    - lista_destinos: Lista de destinos (strings o átomos).
    - contenido: Datos asociados al evento.
  ## Retorna:
    - :ok al completar la difusión.
  """
  def notificar_grupo(evento, lista_destinos, contenido) do
    if not soy_central?() do
      reenviar_al_central(:notificar_grupo, [evento, lista_destinos, contenido])
    else
      Enum.each(lista_destinos, fn destino ->
        enviar_directo(destino, %{evento: evento, data: contenido})
      end)

      LoggerService.registrar_evento("Difusión grupal completada", %{
        evento: evento,
        cantidad_destinos: length(lista_destinos),
        fecha: DateTime.utc_now()
      })

      :ok
    end
  end

  # ============================================================
  # SUSCRIPCIÓN
  # ============================================================

  @doc """
  Permite que un proceso se suscriba a eventos específicos dentro del sistema.
  ## Parámetros:
    - evento: Átomo que identifica el evento.
    - pid: PID del proceso que se suscribe (por defecto, el proceso actual).
  ## Retorna:
    - {:ok, :suscrito} al completar la suscripción.
  """
  def suscribirse(evento, pid \\ self()) when is_atom(evento) and is_pid(pid) do
    if not soy_central?() do
      # nodos no centrales no tienen PubSub
      {:ok, :suscrito}
    else
      PubSubAdapter.suscribir(evento, pid)

      LoggerService.registrar_evento("Suscripción añadida", %{evento: evento, pid: inspect(pid)})

      {:ok, :suscrito}
    end
  end

  @doc """
  Cancela una suscripción existente a un evento.
  ## Parámetros:
    - evento: Átomo que identifica el evento.
    - pid: PID del proceso que cancela la suscripción (por defecto, el proceso actual).
  ## Retorna:
    - {:ok, :cancelado} al completar la cancelación.
  """
  def cancelar_suscripcion(evento, pid \\ self()) when is_atom(evento) and is_pid(pid) do
    if soy_central?() do
      PubSubAdapter.desuscribir(evento, pid)

      LoggerService.registrar_evento("Suscripción cancelada", %{
        evento: evento,
        pid: inspect(pid)
      })
    end

    {:ok, :cancelado}
  end

  # ============================================================
  # TRAZABILIDAD Y ALERTAS
  # ============================================================

  @doc """
  Registra un evento especial para trazabilidad de proyectos.
  Usado por `ProjectManager` para registrar avances, evaluaciones y cambios.
  ## Parámetros:
    - evento: Átomo que identifica el evento.
    - proyecto_nombre: Nombre del proyecto asociado (string).
    - detalles: Detalles adicionales del evento (mapa o cualquier estructura).
  ## Retorna:
    - {:ok, payload} con el contenido del evento registrado.
  """
  def registrar_evento_proyecto(evento, proyecto_nombre, detalles) do
    payload = construir_mensaje(:proyecto, evento, %{proyecto: proyecto_nombre, data: detalles})

    LoggerService.registrar_evento("Evento de proyecto: #{evento}", payload)

    if not soy_central?() do
      reenviar_al_central(:registrar_evento_proyecto, [evento, proyecto_nombre, detalles])
    else
      safe_broadcast(fn ->
        PubSubAdapter.publicar(:evento_proyecto, payload)
        ChannelManager.broadcast(:evento_proyecto, payload)
      end)

      {:ok, payload}
    end
  end

  @doc """
  Envía una alerta o error del sistema con prioridad alta.
  ## Parámetros:
    - contexto: Contexto o módulo donde ocurrió el error (string o átomo).
    - detalle: Detalle o mensaje del error (string o cualquier estructura).
  ## Retorna:
    - {:error, mensaje} con el contenido de la notificación de error.
  """
  def notificar_error(contexto, detalle) do
    mensaje = construir_mensaje(:error, :error_sistema, %{contexto: contexto, detalle: detalle})
    LoggerService.registrar_evento("ERROR", mensaje)
    MetricsService.registrar_evento(:error_sistema, %{contexto: contexto, detalle: detalle})

    if not soy_central?() do
      reenviar_al_central(:notificar_error, [contexto, detalle])
    else
      safe_broadcast(fn ->
        PubSubAdapter.publicar(:error_sistema, mensaje)
        ChannelManager.broadcast(:error_sistema, mensaje)
      end)

      {:error, mensaje}
    end
  end

  # ============================================================
  # AUXILIARES
  # ============================================================

  @doc false
  defp construir_mensaje(tipo, evento, data) do
    %{
      tipo: tipo,
      evento: evento,
      contenido: data,
      timestamp: DateTime.utc_now(),
      nodo: Atom.to_string(Node.self())
    }
  end

  @doc false
  defp safe_broadcast(fun) do
    try do
      fun.()
    rescue
      error ->
        LoggerService.registrar_evento("Error de difusión", %{
          mensaje: Exception.message(error),
          tipo: :error,
          timestamp: DateTime.utc_now()
        })

        {:error, :fallo_difusion}
    end
  end

  # ============================================================
  # SUPERVISIÓN
  # ============================================================

  @doc """
  Registra el servicio de broadcast dentro del `SupervisionManager` para monitoreo.
  ## Retorna:
    - :ok al completar el registro.
  """
  def registrar_supervision do
    ProyectoFinalPrg3.Services.SupervisionService.registrar_proceso(
      :broadcast_service,
      __MODULE__
    )
  end

  @doc """
  Inicializa el servicio de broadcast. Si no existe el sistema PubSub, lo arranca nuevamente.
  ## Retorna:
    - :ok al completar la inicialización.
  """
  def inicializar_supervision do
    if soy_central?() do
      {:ok, _pid} =
        Phoenix.PubSub.PG2.start_link(name: ProyectoFinalPrg3.PubSub)

      LoggerService.registrar_evento("BroadcastService reiniciado", %{estado: :ok})
    end

    :ok
  end
end

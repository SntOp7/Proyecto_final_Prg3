defmodule ProyectoFinalPrg3.Services.BroadcastService do
  @moduledoc """
  Servicio responsable de la difusión de eventos y notificaciones dentro del sistema.
  Actúa como el bus central de comunicación entre módulos del dominio y adaptadores de red.

  Gestiona tres niveles de difusión:
    1. Local (logs y auditoría)
    2. Red (PubSub y ChannelManager)
    3. Distribuido (NodeManager, para sincronización entre nodos)

  Este módulo es usado por gestores como `TeamManager`, `ProjectManager`, `MentorManager`, etc.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-26
  Última modificación: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Adapters.Network.{PubSubAdapter, ChannelManager, NodeManager}
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # ============================================================
  # DIFUSIÓN DE EVENTOS
  # ============================================================

  @doc """
  Envía una notificación general del sistema.
  Es la forma estándar de propagar eventos como `:proyecto_creado` o `:equipo_actualizado`.

  ## Ejemplo:
      BroadcastService.notificar(:proyecto_creado, %{nombre: "SmartHub", categoria: "IA"})
  """
  def notificar(evento, data, tipo \\ :info) when is_atom(evento) do
    mensaje = construir_mensaje(tipo, evento, data)

    # Log local (historial del sistema)
    LoggerService.registrar_evento("Difusión: #{evento}", mensaje)

    # Difusión segura hacia red y nodos
    safe_broadcast(fn ->
      PubSubAdapter.publicar(evento, mensaje)
      ChannelManager.broadcast(evento, mensaje)
      NodeManager.enviar_a_nodos(evento, mensaje)
    end)

    {:ok, mensaje}
  end

  @doc """
  Envía un mensaje directo a un destino específico (por ejemplo, a un canal o a un nodo).
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

    safe_broadcast(fn ->
      ChannelManager.enviar(destino, payload)
      NodeManager.enviar_directo(destino, payload)
    end)

    {:ok, payload}
  end

  @doc """
  Notifica simultáneamente un mismo evento a múltiples destinos.
  Útil para difusión grupal (equipos, proyectos o mentores asignados).
  """
  def notificar_grupo(evento, lista_destinos, contenido) do
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

  # ============================================================
  # SUSCRIPCIÓN Y CONTROL DE EVENTOS
  # ============================================================

  @doc """
  Permite que un proceso se suscriba a eventos específicos dentro del sistema.
  """
  def suscribirse(evento, pid \\ self()) when is_atom(evento) and is_pid(pid) do
    PubSubAdapter.suscribir(evento, pid)
    LoggerService.registrar_evento("Suscripción añadida", %{evento: evento, pid: inspect(pid)})
    {:ok, :suscrito}
  end

  @doc """
  Cancela una suscripción existente a un evento.
  """
  def cancelar_suscripcion(evento, pid \\ self()) when is_atom(evento) and is_pid(pid) do
    PubSubAdapter.desuscribir(evento, pid)
    LoggerService.registrar_evento("Suscripción cancelada", %{evento: evento, pid: inspect(pid)})
    {:ok, :cancelado}
  end

  # ============================================================
  # TRAZABILIDAD Y ALERTAS DE PROYECTOS
  # ============================================================

  @doc """
  Registra un evento especial para trazabilidad de proyectos.
  Usado por `ProjectManager` para registrar avances, evaluaciones y cambios.
  """
  def registrar_evento_proyecto(evento, proyecto_nombre, detalles) do
    payload = construir_mensaje(:proyecto, evento, %{proyecto: proyecto_nombre, data: detalles})

    LoggerService.registrar_evento("Evento de proyecto: #{evento}", payload)

    safe_broadcast(fn ->
      PubSubAdapter.publicar(:evento_proyecto, payload)
      ChannelManager.broadcast(:evento_proyecto, payload)
    end)

    {:ok, payload}
  end

  @doc """
  Envía una alerta o error del sistema con prioridad alta.
  """
  def notificar_error(contexto, detalle) do
    mensaje = construir_mensaje(:error, :error_sistema, %{contexto: contexto, detalle: detalle})
    LoggerService.registrar_evento("ERROR", mensaje)

    safe_broadcast(fn ->
      PubSubAdapter.publicar(:error_sistema, mensaje)
      ChannelManager.broadcast(:error_sistema, mensaje)
    end)

    {:error, mensaje}
  end

  # ============================================================
  # FUNCIONES AUXILIARES
  # ============================================================

  defp construir_mensaje(tipo, evento, data) do
    %{
      tipo: tipo,
      evento: evento,
      contenido: data,
      timestamp: DateTime.utc_now(),
      nodo: Atom.to_string(Node.self())
    }
  end

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
end

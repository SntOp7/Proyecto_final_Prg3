defmodule ProyectoFinalPrg3.Services.BroadcastService do
  @moduledoc """
  Servicio responsable de la difusión de eventos y notificaciones dentro del sistema.
  Permite notificar a diferentes módulos o nodos (como chat, equipos o proyectos)
  sobre cambios o acciones que deben ser replicadas.

  Este módulo actúa como capa de orquestación de eventos dentro de la arquitectura hexagonal,
  comunicándose con los adaptadores de red (`PubSubAdapter`, `ChannelManager`) o con el sistema de logs.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-26
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Adapters.Network.{PubSubAdapter, ChannelManager, NodeManager}
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # ============================================================
  # FUNCIONES PRINCIPALES DE DIFUSIÓN DE EVENTOS
  # ============================================================

  @doc """
  Envía una notificación general a través del sistema.

  ## Parámetros:
    - `evento`: átomo que indica el tipo de evento (`:equipo_creado`, `:proyecto_actualizado`, etc.).
    - `data`: estructura de datos asociada al evento.

  ## Ejemplo:
      BroadcastService.notificar(:equipo_creado, %{nombre: "Innovadores"})
  """
  def notificar(evento, data) when is_atom(evento) do
    mensaje = construir_mensaje(:info, evento, data)

    LoggerService.registrar_evento("Notificación enviada", mensaje)

    safe_broadcast(fn ->
      PubSubAdapter.publicar(evento, mensaje)
      ChannelManager.broadcast(evento, mensaje)
      NodeManager.enviar_a_nodos(evento, mensaje)
    end)

    {:ok, mensaje}
  end

  @doc """
  Envía un mensaje directo entre componentes internos.
  Por ejemplo, desde un mentor a un equipo, o desde el sistema a un participante.

  ## Parámetros:
    - `destino`: identificador del canal o entidad destino.
    - `mensaje`: contenido o payload a enviar.
  """
  def enviar_directo(destino, mensaje) do
    payload = %{
      tipo: :directo,
      destino: destino,
      contenido: mensaje,
      timestamp: DateTime.utc_now(),
      nodo: Atom.to_string(Node.self())
    }

    LoggerService.registrar_evento("Mensaje directo", payload)

    safe_broadcast(fn ->
      ChannelManager.enviar(destino, payload)
      NodeManager.enviar_directo(destino, payload)
    end)

    {:ok, payload}
  end

  @doc """
  Notifica un cambio a múltiples suscriptores o canales simultáneamente.
  """
  def notificar_grupo(evento, lista_destinos, contenido) do
    Enum.each(lista_destinos, fn destino ->
      enviar_directo(destino, %{evento: evento, data: contenido})
    end)

    LoggerService.registrar_evento("Difusión grupal", %{
      evento: evento,
      cantidad: length(lista_destinos),
      fecha: DateTime.utc_now()
    })

    :ok
  end

  # ============================================================
  # FUNCIONES DE SUSCRIPCIÓN Y CONTROL DE EVENTOS
  # ============================================================

  @doc """
  Permite que un módulo o proceso se suscriba a eventos específicos.
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
  # FUNCIONES AUXILIARES DE CONSTRUCCIÓN Y CONTROL
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
        LoggerService.registrar_evento("Error de difusión", %{error: Exception.message(error)})
        {:error, :fallo_difusion}
    end
  end
end

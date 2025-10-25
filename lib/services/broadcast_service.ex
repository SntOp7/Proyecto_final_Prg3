defmodule ProyectoFinalPrg3.Services.BroadcastService do
  @moduledoc """
  Servicio responsable de la difusión de eventos y notificaciones dentro del sistema.
  Permite notificar a diferentes módulos o nodos (como chat, equipos o proyectos)
  sobre cambios o acciones que deben ser replicadas.

  Este módulo actúa como capa de orquestación de eventos dentro de la arquitectura hexagonal,
  comunicándose con los adaptadores de red (PubSub, ChannelManager) o con el sistema de logs.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-26
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Adapters.Network.{PubSubAdapter, ChannelManager}
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
    mensaje = construir_mensaje(evento, data)

    # Publicar localmente (log del sistema)
    LoggerService.registrar_evento("Notificación enviada", mensaje)

    # Difundir por red si hay subscriptores activos
    PubSubAdapter.publicar(evento, mensaje)
    ChannelManager.broadcast(evento, mensaje)

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
    payload = %{to: destino, contenido: mensaje, timestamp: DateTime.utc_now()}

    LoggerService.registrar_evento("Mensaje directo", payload)
    ChannelManager.enviar(destino, payload)

    {:ok, payload}
  end

  @doc """
  Notifica un cambio a múltiples suscriptores o canales simultáneamente.
  """
  def notificar_grupo(evento, lista_destinos, contenido) do
    Enum.each(lista_destinos, fn destino ->
      enviar_directo(destino, %{evento: evento, data: contenido})
    end)

    LoggerService.registrar_evento("Difusión grupal", %{evento: evento, cantidad: length(lista_destinos)})
    :ok
  end

  # ============================================================
  # FUNCIONES AUXILIARES DE CONSTRUCCIÓN DE EVENTOS
  # ============================================================

  @doc false
  defp construir_mensaje(evento, data) do
    %{
      evento: evento,
      contenido: data,
      timestamp: DateTime.utc_now(),
      nodo: Node.self() |> Atom.to_string()
    }
  end
end

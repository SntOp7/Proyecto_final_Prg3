defmodule ProyectoFinalPrg3.Adapters.Network.MessageBroadcast do
  @moduledoc """
  Adaptador encargado de unificar el envío de mensajes locales y distribuidos.

  Este módulo centraliza la lógica para difundir mensajes dentro del nodo actual
  (vía PubSub) y hacia otros nodos del cluster (vía RPC). Adicionalmente,
  normaliza y formatea los mensajes emitidos para mantener consistencia entre
  los distintos módulos de comunicación.

  Es utilizado principalmente por:

    - `AnnouncementChannel`
    - `MentorshipChannel`
    - `ChatService`
    - `TeamManager`
    - `MentorManager`

  ## Funciones principales
    - `emitir_local/4`: Envía un mensaje únicamente dentro del nodo actual.
    - `emitir_distribuido/4`: Difunde un mensaje hacia nodos remotos.
    - `emitir/5`: Realiza un broadcast combinado (local + distribuido).
    - `formatear/3`: Genera un payload estándar para todos los canales.

  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  alias ProyectoFinalPrg3.Adapters.Network.ChannelManager
  alias ProyectoFinalPrg3.Adapters.Network.NodeManager
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # ============================================================
  # UTILIDADES DE FORMATO
  # ============================================================

  @doc """
  Construye un payload de mensaje estándar para todo el sistema.

  El propósito de esta función es asegurar que **todos los mensajes emitidos**
  tengan la misma estructura, permitiendo estandarización en:

    - canales,
    - interacción mentor-equipo,
    - análisis de logs,
    - transmisión entre nodos,
    - depuración.

  ## Flujo:
    1. Recibe tipo, contenido y metadata.
    2. Agrega un timestamp en UTC.
    3. Devuelve un mapa uniforme usado por todo el sistema.

  ## Parámetros:
    - `tipo`: Rol o categoría del mensaje.
    - `contenido`: Cuerpo del mensaje.
    - `meta`: Datos adicionales (opcional).

  ## Retorna:
    - Un mapa estándar con campos `:type`, `:content`, `:meta`, y `:timestamp`.
  """
  def formatear(tipo, contenido, meta \\ %{}) do
    %{
      type: tipo,
      content: contenido,
      meta: meta,
      timestamp: DateTime.utc_now()
    }
  end

  # ============================================================
  # BROADCAST LOCAL (DENTRO DEL NODO)
  # ============================================================

  @doc """
  Emite un mensaje dentro del nodo actual utilizando PubSub.

  El mensaje será recibido únicamente por los procesos locales suscritos al
  canal especificado. Este método es la base del sistema de mensajería interno.

  ## Flujo:
    1. Formatea el payload mediante `formatear/3`.
    2. Envia el mensaje por PubSub usando `ChannelManager.broadcast/2`.
    3. Registra la operación en logs.
    4. Devuelve confirmación exitosa.

  ## Parámetros:
    - `canal`: Canal PubSub local.
    - `tipo`: Tipo o rol del mensaje.
    - `contenido`: Contenido del mensaje.
    - `meta`: Metadata opcional.

  ## Retorna:
    - `{:ok, :local}` indicando broadcast local exitoso.
  """
  def emitir_local(canal, tipo, contenido, meta \\ %{}) do
    payload = formatear(tipo, contenido, meta)

    ChannelManager.broadcast(canal, payload)

    LoggerService.registrar_evento("Broadcast local enviado", %{
      canal: canal,
      payload: payload
    })

    {:ok, :local}
  end

  # ============================================================
  # BROADCAST ENTRE NODOS (MENSAJERÍA DISTRIBUIDA)
  # ============================================================

  @doc """
  Emite un mensaje a todos los nodos conectados mediante RPC distribuido.

  Este método representa la capa de comunicación distribuida del sistema,
  permitiendo que los mensajes lleguen a otros nodos BEAM conectados.

  ## Flujo:
    1. Construye el payload mediante `formatear/3`.
    2. Difunde el mensaje hacia todos los nodos usando `NodeManager.enviar_a_nodos/2`.
    3. Registra la operación en logs del sistema.
    4. Devuelve confirmación exitosa.

  ## Parámetros:
    - `evento`: Etiqueta o nombre del evento distribuido.
    - `tipo`: Tipo del mensaje.
    - `contenido`: Contenido del mensaje.
    - `meta`: Info adicional opcional.

  ## Retorna:
    - `{:ok, :distribuido}` si la difusión hacia nodos fue exitosa.
  """
  def emitir_distribuido(evento, tipo, contenido, meta \\ %{}) do
    payload = formatear(tipo, contenido, meta)

    NodeManager.enviar_a_nodos(evento, payload)

    LoggerService.registrar_evento("Broadcast distribuido enviado", %{
      evento: evento,
      payload: payload
    })

    {:ok, :distribuido}
  end

  # ============================================================
  # BROADCAST COMBINADO (LOCAL + DISTRIBUIDO)
  # ============================================================

  @doc """
  Emite un mensaje tanto local como distribuido en una sola operación.

  Esta función combina `emitir_local/4` y `emitir_distribuido/4` y es la más
  utilizada por los canales orientados a interacción (mentor-equipo, chat,
  anuncios, etc.).

  ## Flujo:
    1. Envía el mensaje localmente mediante PubSub.
    2. Difunde el mensaje al cluster BEAM vía RPC.
    3. Regresa confirmación general.

  ## Parámetros:
    - `canal_local`: Canal PubSub interno.
    - `evento_remoto`: Evento para nodos remotos.
    - `tipo`: Tipo de mensaje.
    - `contenido`: Cuerpo del mensaje.
    - `meta`: Metadata opcional.

  ## Retorna:
    - `{:ok, :enviado}` si ambas operaciones fueron exitosas.
  """
  def emitir(canal_local, evento_remoto, tipo, contenido, meta \\ %{}) do
    {:ok, :local} = emitir_local(canal_local, tipo, contenido, meta)
    {:ok, :distribuido} = emitir_distribuido(evento_remoto, tipo, contenido, meta)

    {:ok, :enviado}
  end
end

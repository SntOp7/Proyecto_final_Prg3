defmodule ProyectoFinalPrg3.Adapters.Network.PubSubAdapter do
  @moduledoc """
  Adaptador encargado de gestionar la mensajería interna basada en `Phoenix.PubSub`.

  Este módulo proporciona una capa ligera y segura para enviar y recibir mensajes
  entre procesos dentro de un mismo nodo del sistema distribuido. No utiliza
  WebSockets ni Phoenix Channels; únicamente emplea PubSub interno del BEAM para
  difusión local de eventos.

  Es utilizado principalmente por:

    - `ChannelManager`
    - `MessageBroadcast`
    - `AnnouncementChannel`
    - `MentorshipChannel`
    - Servicios que requieren suscripción a eventos internos

  ## Funciones principales
    - `publicar/2`: Difunde un mensaje a todos los suscriptores de un evento.
    - `suscribir/2`: Registra un proceso como suscriptor de un canal lógico.
    - `desuscribir/2`: Elimina la suscripción de un proceso.
    - Utilidad auxiliar: conversión segura de nombres de eventos a tópicos.

  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  require Logger

  @pubsub ProyectoFinalPrg3.PubSub

  # ============================================================
  # PUBLICAR MENSAJES
  # ============================================================

  @doc """
  Difunde un mensaje a todos los procesos suscritos a un evento específico.

  Este método es el núcleo de la mensajería interna del sistema. Utiliza el
  backend `Phoenix.PubSub` para distribuir eventos de manera local dentro del
  nodo actual.

  ## Flujo:
    1. Verifica que el módulo Phoenix.PubSub esté cargado (soporte opcional).
    2. Si está disponible:
         - Convierte el nombre del evento en un tópico.
         - Ejecuta `broadcast/3` para difundir el mensaje.
    3. Si no está disponible:
         - Registra un debug indicando que el mensaje fue omitido.

  ## Parámetros:
    - `evento`: Nombre lógico del canal o evento (átomo o string).
    - `mensaje`: Cualquier estructura que será enviada a los suscriptores.

  ## Retorna:
    - `:ok` en todos los casos (no arroja errores).
  """
  def publicar(evento, mensaje) do
    if Code.ensure_loaded?(Phoenix.PubSub) do
      Phoenix.PubSub.broadcast(@pubsub, to_topic(evento), mensaje)
    else
      Logger.debug("PubSub no disponible — mensaje no enviado")
    end

    :ok
  end

  # ============================================================
  # SUSCRIBIR A UN EVENTO
  # ============================================================

  @doc """
  Suscribe un proceso al evento especificado.

  Permite que el proceso (por defecto `self/0`) reciba todos los mensajes que
  se publiquen en el tópico asociado al evento.

  ## Flujo:
    1. Verifica disponibilidad de Phoenix.PubSub.
    2. Si está cargado:
         - Convierte el evento al tópico correspondiente.
         - Ejecuta `subscribe/2`.
    3. Retorna confirmación independientemente del soporte disponible.

  ## Parámetros:
    - `evento`: Nombre del evento (átomo o string).
    - `pid`: Proceso que recibirá los mensajes (por defecto `self()`).

  ## Retorna:
    - `:ok` siempre.
  """
  def suscribir(evento, _pid \\ self()) do
    if Code.ensure_loaded?(Phoenix.PubSub) do
      Phoenix.PubSub.subscribe(@pubsub, to_topic(evento))
    end

    :ok
  end

  # ============================================================
  # DESUSCRIBIR UN EVENTO
  # ============================================================

  @doc """
  Elimina la suscripción de un proceso a un evento.

  Es útil para liberar recursos o evitar que un proceso reciba eventos que ya
  no son relevantes para su contexto.

  ## Flujo:
    1. Verifica soporte de Phoenix.PubSub.
    2. Si está disponible:
         - Convierte el evento al tópico.
         - Ejecuta `unsubscribe/2`.
    3. Retorna confirmación.

  ## Parámetros:
    - `evento`: Nombre del evento (átomo o string).
    - `pid`: Proceso que dejará de recibir mensajes (por defecto `self()`).

  ## Retorna:
    - `:ok`.
  """
  def desuscribir(evento, _pid \\ self()) do
    if Code.ensure_loaded?(Phoenix.PubSub) do
      Phoenix.PubSub.unsubscribe(@pubsub, to_topic(evento))
    end

    :ok
  end

  # ============================================================
  # UTILIDADES INTERNAS
  # ============================================================

  @doc false
  # Convierte un nombre de evento en el tópico que requiere Phoenix.PubSub
  defp to_topic(ev) when is_atom(ev), do: Atom.to_string(ev)
  defp to_topic(ev), do: ev
end

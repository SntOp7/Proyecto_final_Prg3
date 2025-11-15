defmodule ProyectoFinalPrg3.Adapters.Network.NodeManager do
  @moduledoc """
  Servicio encargado de gestionar la comunicación entre **nodos distribuidos**
  del sistema. Funciona como el adaptador que permite enviar mensajes entre
  diferentes nodos en un clúster Erlang.

  Este módulo permite:
    - Difundir eventos a todos los nodos conectados.
    - Enviar mensajes directos a un nodo específico.
    - Registrar fallos de comunicación.
    - Verificar estado del clúster.

  Utilizado principalmente por:
    - `BroadcastService`
    - `SupervisionManager`
    - Servicio de replicación distribuida (cuando exista)

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # ============================================================
  # API PÚBLICA
  # ============================================================

  @doc """
  Envía un mensaje a **todos los nodos conectados**.

  Si no hay nodos, simplemente retorna `:sin_nodos`.

  ## Ejemplo
      NodeManager.enviar_a_nodos(:evento, %{msg: "Hola"})
  """
  def enviar_a_nodos(evento, mensaje) do
    nodos = Node.list()

    if nodos == [] do
      LoggerService.registrar_evento("Difusión distribuida omitida: sin nodos", %{
        evento: evento
      })

      :sin_nodos
    else
      Enum.each(nodos, fn nodo ->
        enviar_directo(nodo, {evento, mensaje})
      end)

      :ok
    end
  end

  @doc """
  Envía un mensaje directo a un nodo en particular.

  Internamente utiliza `:rpc.call`, asegurando que:
    - No explota si el nodo está caído
    - Registra logs de error cuando falla
  """
  def enviar_directo(nodo, payload) when is_atom(nodo) do
    if nodo in Node.list() do
      respuesta = :rpc.call(nodo, __MODULE__, :recibir_mensaje, [payload])

      LoggerService.registrar_evento("Mensaje enviado a nodo", %{
        destino: nodo,
        payload: payload,
        respuesta: respuesta
      })

      :ok
    else
      LoggerService.registrar_evento("Error: nodo no está conectado", %{
        destino: nodo
      })

      {:error, :nodo_no_conectado}
    end
  end

  # ============================================================
  # RECEPCIÓN EN NODOS REMOTOS
  # ============================================================

  @doc """
  Función remota llamada vía RPC para recibir mensajes en un nodo externo.

  Esta función siempre debe ser pública, pues `:rpc.call/4`
  la ejecutará desde otro nodo.
  """
  def recibir_mensaje({evento, data}) do
    LoggerService.registrar_evento("Mensaje recibido desde otro nodo", %{
      evento: evento,
      data: data
    })

    {:ok, :recibido}
  end

  # ============================================================
  # UTILIDADES DE CLÚSTER
  # ============================================================

  @doc """
  Retorna información del estado del clúster:

    - nodo local
    - lista de nodos conectados
    - si el sistema está distribuido o no
  """
  def estado_cluster do
    %{
      nodo_local: Node.self(),
      nodos_conectados: Node.list(),
      distribuido?: Node.list() != []
    }
  end
end

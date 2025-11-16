defmodule ProyectoFinalPrg3.Adapters.Network.NodeManager do
  @moduledoc """
  Adaptador encargado de gestionar la comunicación entre nodos del cluster BEAM.

  Este módulo permite enviar mensajes a nodos remotos mediante RPC, verificar el
  estado del cluster y establecer conexiones manuales entre nodos definidos por
  configuración. Constituye la base para la mensajería distribuida utilizada por
  `MessageBroadcast`.

  Es utilizado principalmente por:

    - `MessageBroadcast`
    - `ClusterConfig`
    - Servicios que requieren coordinación entre nodos

  ## Funciones principales
    - `enviar_a_nodos/2`: Difunde un mensaje a todos los nodos conectados.
    - `enviar_directo/2`: Envía un mensaje a un nodo específico mediante RPC.
    - `recibir_mensaje/1`: Maneja la recepción de mensajes remotos.
    - `estado_cluster/0`: Retorna el estado actual del cluster.
    - `conectarse_a_nodos/0`: Conecta a nodos definidos en configuración.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha: 2025-10-27
  Licencia: GNU GPLv3
  """

  @behaviour ProyectoFinalPrg3.Adapters.Network.NodeManagerBehaviour

  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # ============================================================
  # API PÚBLICA
  # ============================================================

  def enviar_a_nodos(evento, mensaje) do
    nodos = Node.list()

    if nodos == [] do
      LoggerService.registrar_evento("Difusión distribuida omitida: sin nodos", %{evento: evento})
      :sin_nodos
    else
      Enum.map(nodos, fn nodo ->
        enviar_directo(nodo, {evento, mensaje})
      end)

      :ok
    end
  end

  def enviar_directo(nodo, payload) when is_atom(nodo) do
    if nodo in Node.list() do
      respuesta =
        case :rpc.call(nodo, __MODULE__, :recibir_mensaje, [payload]) do
          {:badrpc, razon} ->
            LoggerService.registrar_evento("Error RPC", %{nodo: nodo, razon: inspect(razon)})
            {:error, :rpc_fallo}

          ok ->
            ok
        end

      LoggerService.registrar_evento("Mensaje enviado a nodo", %{
        destino: nodo,
        payload: payload,
        respuesta: respuesta
      })

      :ok
    else
      LoggerService.registrar_evento("Error: nodo no está conectado", %{destino: nodo})
      {:error, :nodo_no_conectado}
    end
  end

  def recibir_mensaje({evento, data}) do
    LoggerService.registrar_evento("Mensaje recibido desde otro nodo", %{
      evento: evento,
      data: data
    })

    {:ok, :recibido}
  end

  def estado_cluster do
    nodos = Node.list()

    %{
      nodo_local: Node.self(),
      nodos_conectados: nodos,
      distribuido?: nodos != []
    }
  end

  def conectarse_a_nodos do
    nodos = Application.get_env(:proyecto_final_prg3, :nodos, [])

    Enum.each(nodos, fn nodo ->
      case Node.connect(nodo) do
        true ->
          LoggerService.registrar_evento("Conectado a nodo", %{nodo: nodo})

        false ->
          LoggerService.registrar_evento("No se pudo conectar al nodo", %{
            nodo: nodo,
            estado: :rechazado
          })
      end
    end)

    :ok
  end
end

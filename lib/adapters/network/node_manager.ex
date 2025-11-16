defmodule ProyectoFinalPrg3.Adapters.Network.NodeManager do
  @moduledoc """
  (… igual que tu versión …)
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

          ok -> ok
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

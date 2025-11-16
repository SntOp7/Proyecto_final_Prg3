defmodule ProyectoFinalPrg3.Adapters.Network.NodeManager do
  @moduledoc """
  Implementación del adaptador encargado de gestionar la comunicación entre
  nodos del cluster BEAM.

  Este módulo sigue estrictamente el behaviour definido en
  `NodeManagerBehaviour`, lo que permite:

    • Pruebas unitarias con Mox
    • Simulación de nodos (mocks)
    • Garantizar consistencia en la API distribuida

  ## Funcionalidades principales
    - Inicialización del nodo local
    - Envío de mensajes RPC entre nodos
    - Difusión a todos los nodos
    - Conexión automática a nodos configurados
    - Inspección del estado del cluster

  Este módulo es utilizado por:
    • InitialBootService
    • MessageBroadcast
    • ClusterConfig
    • Servicios que requieren coordinación distribuida
  """

  @behaviour ProyectoFinalPrg3.Adapters.Network.NodeManagerBehaviour

  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # ============================================================
  # 1. INICIO DEL NODO LOCAL
  # ============================================================

  @doc """
  Inicia el nodo local si aún no tiene nombre (`:nonode@nohost`).

  Esto es requerido para permitir comunicación distribuida.
  """
  @spec iniciar_nodo_local() :: :ok | {:error, any()}
  def iniciar_nodo_local do
    case Node.self() do
      :nonode@nohost ->
        iniciar_nodo_con_nombre()

      _ ->
        :ok
    end
  end

  @doc false
  defp iniciar_nodo_con_nombre do
    hostname =
      :inet.gethostname()
      |> elem(1)
      |> to_string()

    nombre = :"proyecto_final@#{hostname}"

    case :net_kernel.start([nombre, :shortnames]) do
      {:ok, _pid} ->
        LoggerService.registrar_evento("Nodo BEAM iniciado", %{nodo: nombre})
        :ok

      {:error, razon} ->
        LoggerService.registrar_evento("Error iniciando nodo BEAM", %{razon: inspect(razon)})
        {:error, razon}
    end
  end

  # ============================================================
  # 2. ENVÍO A TODOS LOS NODOS
  # ============================================================

  @impl true
  def enviar_a_nodos(evento, mensaje) do
    nodos = Node.list()

    if nodos == [] do
      LoggerService.registrar_evento("Sin nodos para difusión", %{evento: evento})
      :sin_nodos
    else
      Enum.each(nodos, &enviar_directo(&1, {evento, mensaje}))
      :ok
    end
  end

  # ============================================================
  # 3. ENVÍO DIRECTO RPC
  # ============================================================

  @impl true
  def enviar_directo(nodo, payload) do
    if nodo not in Node.list() do
      LoggerService.registrar_evento("Nodo no conectado", %{destino: nodo})
      {:error, :nodo_no_conectado}
    else
      case :rpc.call(nodo, __MODULE__, :recibir_mensaje, [payload]) do
        {:badrpc, razon} ->
          LoggerService.registrar_evento("Error RPC", %{destino: nodo, razon: inspect(razon)})
          {:error, :rpc_fallo}

        respuesta ->
          LoggerService.registrar_evento("RPC enviado", %{destino: nodo, respuesta: respuesta})
          :ok
      end
    end
  end

  # ============================================================
  # 4. RECEPCIÓN DE MENSAJES
  # ============================================================

  @impl true
  def recibir_mensaje({evento, data}) do
    LoggerService.registrar_evento("Mensaje recibido desde nodo remoto", %{
      evento: evento,
      data: data
    })

    {:ok, :recibido}
  end

  # ============================================================
  # 5. ESTADO DEL CLUSTER
  # ============================================================

  @impl true
  def estado_cluster do
    nodos = Node.list()

    %{
      nodo_local: Node.self(),
      nodos_conectados: nodos,
      distribuido?: nodos != []
    }
  end

  # ============================================================
  # 6. CONEXIÓN A NODOS CONFIGURADOS
  # ============================================================

  @impl true
  def conectarse_a_nodos do
    nodos = Application.get_env(:proyecto_final_prg3, :nodos, [])

    Enum.each(nodos, fn nodo ->
      case Node.connect(nodo) do
        true ->
          LoggerService.registrar_evento("Conectado al nodo", %{nodo: nodo})

        false ->
          LoggerService.registrar_evento("Error conectando al nodo", %{
            nodo: nodo,
            razon: :rechazado
          })
      end
    end)

    :ok
  end
end

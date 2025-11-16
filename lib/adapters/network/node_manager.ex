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
    - `enviar_directo/2`: Envía un mensaje directamente a un nodo remoto.
    - `recibir_mensaje/1`: Maneja los mensajes entrantes desde otros nodos.
    - `estado_cluster/0`: Retorna el estado actual del cluster.
    - `conectarse_a_nodos/0`: Conecta el nodo local a otros nodos configurados.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha: 2025-10-27
  Licencia: GNU GPLv3
  """

  @behaviour ProyectoFinalPrg3.Adapters.Network.NodeManagerBehaviour

  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # ============================================================
  # ENVÍO A TODOS LOS NODOS
  # ============================================================

  @doc """
  Envía un mensaje a todos los nodos conectados del cluster.

  Este método implementa el mecanismo de difusión distribuida utilizado por
  `MessageBroadcast` para garantizar que un evento llegue a todos los nodos BEAM
  actualmente conectados.

  ## Flujo:
    1. Obtiene la lista de nodos conectados mediante `Node.list/0`.
    2. Si no hay nodos, registra un evento de omisión y finaliza.
    3. Si hay nodos, ejecuta `enviar_directo/2` para cada nodo.
    4. Retorna confirmación.

  ## Parámetros:
    - `evento`: Nombre del evento que identifica la transmisión.
    - `mensaje`: Información a enviar.

  ## Retorna:
    - `:ok` si el mensaje fue enviado a todos los nodos.
    - `:sin_nodos` si no existían nodos conectados.
  """
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

  # ============================================================
  # ENVÍO DIRECTO A UN SOLO NODO
  # ============================================================

  @doc """
  Envía un mensaje directamente a un nodo remoto mediante RPC.

  Utiliza `:rpc.call/4` para invocar la función `recibir_mensaje/1` en el nodo
  destino. Esta operación constituye la base del sistema de mensajería distribuida.

  ## Flujo:
    1. Verifica si el nodo está en `Node.list/0`.
    2. Si no está conectado, registra el error y retorna.
    3. Si está conectado:
       - Ejecuta `:rpc.call/4` para enviar el mensaje.
       - Maneja errores RPC (`{:badrpc, razón}`).
       - Registra el evento y la respuesta remota.
    4. Retorna confirmación.

  ## Parámetros:
    - `nodo`: Identificador del nodo (`:"nombre@ip"`).
    - `payload`: Datos a enviar.

  ## Retorna:
    - `:ok` si el RPC fue ejecutado sin errores.
    - `{:error, :nodo_no_conectado}` si el nodo no está disponible.
    - `{:error, :rpc_fallo}` en caso de error remoto.
  """
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

  # ============================================================
  # RECEPCIÓN DE MENSAJES REMOTOS
  # ============================================================

  @doc """
  Función invocada remotamente por otros nodos mediante RPC.

  Representa el punto de entrada estándar para recibir mensajes distribuidos
  desde otros nodos del cluster.

  ## Flujo:
    1. Recibe un tuple `{evento, data}` enviado desde otro nodo.
    2. Registra el evento con su contenido.
    3. Retorna confirmación.

  ## Parámetros:
    - `{evento, data}`: Payload enviado desde nodo remoto.

  ## Retorna:
    - `{:ok, :recibido}` indicando recepción exitosa.
  """
  def recibir_mensaje({evento, data}) do
    LoggerService.registrar_evento("Mensaje recibido desde otro nodo", %{
      evento: evento,
      data: data
    })

    {:ok, :recibido}
  end

  # ============================================================
  # ESTADO DEL CLUSTER
  # ============================================================

  @doc """
  Retorna un mapa con el estado actual del cluster BEAM.

  Este método es consultado por `ClusterConfig` y herramientas administrativas
  para verificar:

    - nodo local,
    - nodos conectados,
    - si el entorno es distribuido.

  ## Retorna:
    - `%{nodo_local: atom, nodos_conectados: list, distribuido?: boolean}`
  """
  def estado_cluster do
    nodos = Node.list()

    %{
      nodo_local: Node.self(),
      nodos_conectados: nodos,
      distribuido?: nodos != []
    }
  end

  # ============================================================
  # CONEXIÓN A NODOS CONFIGURADOS
  # ============================================================

  @doc """
  Conecta el nodo local a otros nodos definidos en `config.exs`.

  Este método es normalmente invocado por `ClusterConfig` durante el arranque
  del sistema.

  ## Flujo:
    1. Obtiene la lista de nodos configurados.
    2. Intenta conectar a cada uno usando `Node.connect/1`.
    3. Registra si la conexión fue exitosa o rechazada.

  ## Retorna:
    - `:ok` después de intentar conectar a todos los nodos.
  """
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

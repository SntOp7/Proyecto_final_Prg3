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

  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # ============================================================
  # 1. INICIO DEL NODO LOCAL
  # ============================================================

  @doc """
  Inicia el nodo local si aún no tiene nombre (`:nonode@nohost`).
  Esto es requerido para permitir comunicación distribuida.
  ## Flujo:
    1. Verifica el nombre actual del nodo.
    2. Si es `:nonode@nohost`, genera un nombre basado en el hostname.
    3. Inicia el nodo con el nombre generado.
    4. Registra eventos de inicio o error en logs.

  ##Parámetros: Ninguno.

  ## Retorna:
    - `:ok` — si el nodo ya estaba iniciado o se inició correctamente.
    - `{:error, razón}` — si hubo un error al iniciar el nodo.
  """
  @spec iniciar_nodo_local() :: :ok | {:error, any()}
  def iniciar_nodo_local do
    case Node.self() do
      :nonode@nohost -> iniciar_nodo_con_nombre()
      _ -> :ok
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

  @doc"""
  Función para enviar un mensaje a todos los nodos conectados mediante RPC distribuido.
  Este método representa la capa de comunicación distribuida del sistema,
  permitiendo que los mensajes lleguen a otros nodos BEAM conectados.

  ## Flujo:
    1. Obtiene la lista de nodos conectados.
    2. Si no hay nodos, registra el evento y retorna `:sin_nodos`.
    3. Si hay nodos, envía el mensaje a cada uno usando `enviar_directo/2`.
    4. Retorna `:ok` al finalizar el envío.

  ## Parámetros:
    - `evento`: Etiqueta o nombre del evento distribuido.
    - `mensaje`: Cualquier estructura de datos que represente el mensaje.

  ## Retorna:
    - `:ok` si el mensaje fue enviado a todos los nodos.
    - `:sin_nodos` si no hay nodos conectados.
  """
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

  @doc"""
  Función para enviar un mensaje directamente a un nodo específico mediante RPC.
  ## Flujo:
    1. Verifica si el nodo está conectado.
    2. Si no está conectado, registra el evento y retorna error.
    3. Si está conectado, realiza la llamada RPC a `recibir_mensaje/1`.
    4. Maneja errores de RPC y registra eventos correspondientes.
  ## Parámetros:
    - `nodo`: Átomo que representa el nombre del nodo destino.
    - `payload`: Cualquier estructura de datos que represente el mensaje.
  ## Retorna:
    - `:ok` si el mensaje fue enviado correctamente.
    - `{:error, :nodo_no_conectado}` si el nodo no está conectado.
    - `{:error, :rpc_fallo}` si hubo un error en la llamada RPC.
  """
def enviar_directo(nodo, payload) do
    if nodo not in Node.list() do
      LoggerService.registrar_evento("Nodo no conectado", %{destino: nodo})
      {:error, :nodo_no_conectado}

    else
      case :rpc.call(nodo, __MODULE__, :recibir_mensaje, [payload]) do
        {:badrpc, razon} ->
          LoggerService.registrar_evento("Error RPC", %{
            destino: nodo,
            razon: inspect(razon)
          })

          {:error, :rpc_fallo}

        {:ok, :recibido} ->
          # ← YA NO enviamos la tupla al logger
          LoggerService.registrar_evento("RPC enviado", %{
            destino: nodo,
            resultado: "OK",
            estado: "recibido"
          })

          :ok

        otra_respuesta ->
          # fallback: convertir cualquier cosa a string
          LoggerService.registrar_evento("RPC enviado (otros)", %{
            destino: nodo,
            respuesta: inspect(otra_respuesta)
          })

          :ok
      end
    end
  end

  # ============================================================
  # 4. RECEPCIÓN DE MENSAJES
  # ============================================================

  @doc """
  Función llamada remotamente por otros nodos para entregar mensajes.
  ## Flujo:
    1. Recibe el mensaje desde el nodo remoto.
    2. Registra el evento en logs.
  ## Parámetros:
    - `mensaje`: Cualquier estructura de datos que represente el mensaje.
  ## Retorna:
    - `{:ok, :recibido}` indicando que el mensaje fue recibido correctamente.
  """
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

  @doc"""
  Función para obtener el estado actual del cluster distribuido.
  El estado es retornado directamente desde `NodeManager`, lo que garantiza consistencia con el
  resto de componentes que consultan la topología distribuida.

  ## Flujo:
    1. Obtiene la lista de nodos conectados.
    2. Construye un mapa con el estado del cluster.

  ## Parámetros: Ninguno.

  ##Retorna:
    Un mapa con la siguiente estructura:

    ```
    %{
      nodo_local: <nombre del nodo>,
      nodos_conectados: [...],
      distribuido?: boolean
    }
    ```
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
  # 6. CONEXIÓN A NODOS CONFIGURADOS
  # ============================================================

  @doc"""
  Función para conectarse automáticamente a nodos remotos
  especificados en la configuración de la aplicación.
  ## Flujo:
    1. Lee la lista de nodos desde la configuración.
    2. Intenta conectar a cada nodo usando `Node.connect/1`.
    3. Registra eventos de éxito o error en logs.
  ## Parámetros: Ninguno.

  ##Retorna
    - `:ok` al finalizar las conexiones.
  """
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

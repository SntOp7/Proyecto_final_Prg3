defmodule ProyectoFinalPrg3.Adapters.Network.ClusterConfig do
  @moduledoc """
  Adaptador encargado de configurar la topología distribuida del sistema.

  Este módulo se ejecuta normalmente durante el arranque de la aplicación y se
  encarga de conectar nodos definidos en configuración, registrar el estado del
  cluster y preparar el entorno para mensajería distribuida a través de
  `NodeManager`.

  Es utilizado principalmente por:

    - Sistema de arranque (`Application`)
    - `NodeManager`
    - Servicios que dependen de la conectividad distribuida

  ## Funciones principales
    - `inicializar/0`: Ejecuta las rutinas de conexión a nodos remotos.
    - `estado/0`: Retorna el estado actual del cluster usando `NodeManager`.

  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  alias ProyectoFinalPrg3.Adapters.Network.NodeManager
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # ============================================================
  # INICIALIZACIÓN DEL CLUSTER
  # ============================================================

  @doc """
  Inicializa la topología del cluster al arranque del sistema.

  Este método ejecuta todas las rutinas necesarias para preparar la comunicación
  distribuida. Se encarga de conectar nodos remotos definidos en la configuración
  de la aplicación y registrar el estado final del cluster.

  ## Flujo:
    1. Registra un evento indicando el inicio del proceso de configuración.
    2. Conecta de manera manual a los nodos configurados.
    3. Consulta y registra el estado final del cluster.
    4. Deja el entorno distribuido listo para su uso.

  ##Parametros: Ninguno.

  ## Retorna:
    - `:ok` — cuando el proceso ha finalizado correctamente.
  """
  def inicializar do
    LoggerService.registrar_evento("ClusterConfig: inicializando cluster", %{
      nodo_local: Node.self()
    })

    conectar_nodos_estaticos()
    registrar_estado()

    :ok
  end

  # ============================================================
  # CONEXIÓN A NODOS REMOTOS
  # ============================================================

  @doc false
  @spec conectar_nodos_estaticos() :: :ok
  defp conectar_nodos_estaticos do
    nodos = Application.get_env(:proyecto_final_prg3, :nodos, [])

    Enum.each(nodos, fn nodo ->
      case Node.connect(nodo) do
        true ->
          LoggerService.registrar_evento("ClusterConfig: conexión exitosa", %{nodo: nodo})

        false ->
          LoggerService.registrar_evento("ClusterConfig: no se pudo conectar al nodo", %{
            nodo: nodo
          })
      end
    end)

    :ok
  end

  # ============================================================
  # ESTADO DEL CLUSTER
  # ============================================================

  @doc """
  Obtiene el estado actual del cluster.

  El estado es retornado directamente desde `NodeManager`, lo que garantiza
  consistencia con el resto de componentes que consultan la topología distribuida.

  Parámetros: Ninguno.

  ## Retorna:
    Un mapa con la siguiente estructura:

    ```
    %{
      nodo_local: <nombre del nodo>,
      nodos_conectados: [...],
      distribuido?: boolean
    }
    ```
  """
  def estado do
    NodeManager.estado_cluster()
  end

  # ============================================================
  # REGISTRO DE ESTADO
  # ============================================================

  @doc false
  @spec registrar_estado() :: :ok
  defp registrar_estado do
    estado = estado()

    LoggerService.registrar_evento("ClusterConfig: estado final", %{
      nodo_local: estado.nodo_local,
      nodos_conectados: estado.nodos_conectados,
      distribuido?: estado.distribuido?
    })

    :ok
  end
end

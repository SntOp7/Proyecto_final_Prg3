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

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Adapters.Network.NodeManager
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # -------------------------------------------------------
  # PUNTO DE ENTRADA PRINCIPAL
  # -------------------------------------------------------
  @doc """
  Inicializa la topología del cluster.

  Este método:
    1. Conecta nodos definidos en config.exs
    2. Registra el estado final del cluster
  """
  def inicializar do
    LoggerService.registrar_evento("ClusterConfig: inicializando cluster", %{
      nodo_local: Node.self()
    })

    conectar_nodos_estaticos()
    registrar_estado()

    :ok
  end

  # -------------------------------------------------------
  # CONEXIÓN MANUAL A NODOS
  # -------------------------------------------------------
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

  # -------------------------------------------------------
  # ESTADO DEL CLUSTER
  # -------------------------------------------------------
  @doc """
  Devuelve el estado del cluster vía NodeManager.
  """
  def estado do
    NodeManager.estado_cluster()
  end

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

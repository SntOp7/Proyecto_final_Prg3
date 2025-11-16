defmodule ProyectoFinalPrg3.Adapters.Network.NodeManagerBehaviour do
  @moduledoc """
  Behaviour que define la interfaz obligatoria para el adaptador de gestión
  de nodos distribuidos del sistema (`NodeManager`).

  Cubre estrictamente las funciones implementadas en:
  `ProyectoFinalPrg3.Adapters.Network.NodeManager`.

  Este behaviour permite:
    - Aplicar pruebas unitarias mediante Mox.
    - Garantizar consistencia entre adaptadores reales y simulados.
    - Estandarizar la API distribuida del sistema.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha: 2025-10-27
  Licencia: GNU GPLv3
  """

  @callback enviar_a_nodos(evento :: any(), mensaje :: any()) ::
              :sin_nodos | :ok

  @callback enviar_directo(nodo :: atom(), payload :: any()) ::
              :ok | {:error, :nodo_no_conectado} | {:error, :rpc_fallo}

  @callback recibir_mensaje(payload :: {any(), any()}) ::
              {:ok, :recibido}

  @callback estado_cluster() ::
              %{
                nodo_local: atom(),
                nodos_conectados: [atom()],
                distribuido?: boolean()
              }

  @callback conectarse_a_nodos() :: :ok
end

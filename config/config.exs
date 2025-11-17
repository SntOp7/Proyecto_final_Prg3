# -------------------------------------------------------------------
#  Configuración base del sistema ProyectoFinalPrg3
# -------------------------------------------------------------------

import Config

# ================================================================
# CONFIGURACIÓN DE LOGS
# ================================================================

config :logger, :console,
  format: "[$level] $message\n",
  metadata: [:module, :line],
  level: :info

# ================================================================
# PUBSUB
# ================================================================

config :proyecto_final_prg3, ProyectoFinalPrg3.PubSub, adapter: Phoenix.PubSub.PG2

# ================================================================
# CONFIGURACIÓN DE PERSISTENCIA
# ================================================================

config :proyecto_final_prg3, :persistencia,
  ruta_data: "data",
  ruta_logs: "logs"

# ================================================================
# CONFIGURACIÓN DE NODOS PARA CLUSTER DISTRIBUIDO
# ================================================================
# Estos nombres deben coincidir con los usados al levantar los nodos:
#   iex --sname persistencia -S mix
#   iex --sname central -S mix
#   mix run cli.exs
# ================================================================

config :proyecto_final_prg3,
  nodos: [
    :persistencia@localhost
  ]

config :proyecto_final_prg3,
  central_node: :central@localhost

# ================================================================
# TIPO DE NODO ACTUAL
# ================================================================

config :proyecto_final_prg3,
  tipo_nodo: :cli

# valores válidos: :central | :persistencia | :cli

# ================================================================
# BROADCAST
# ================================================================

config :proyecto_final_prg3, :broadcast, habilitado: true

# ================================================================
# EJEMPLOS DE EJECUCIÓN
# ================================================================
# iex --sname persistencia -S mix
# iex --sname central -S mix
# mix run cli.exs

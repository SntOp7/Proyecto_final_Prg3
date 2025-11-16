# -------------------------------------------------------------------
#  Configuración base del sistema ProyectoFinalPrg3
#  ÚNICO archivo de configuración para todo el proyecto.
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

config :proyecto_final_prg3, ProyectoFinalPrg3.PubSub,
  adapter: Phoenix.PubSub.PG2

# ================================================================
# CONFIGURACIÓN DE PERSISTENCIA
# ================================================================

config :proyecto_final_prg3, :persistencia,
  ruta_data: "data",
  ruta_logs: "logs"

# ================================================================
# CONFIGURACIÓN DE NODOS DISTRIBUIDOS
# Lista de nodos a los que se conectará el nodo CENTRAL
# ================================================================

config :proyecto_final_prg3,
  nodos: [
    :"persistencia@persistencia"
  ]

# ================================================================
# TIPO DE NODO ACTUAL
# Cambia este valor manualmente al iniciar cada nodo.
# ================================================================

config :proyecto_final_prg3,
  tipo_nodo: :central
# valores válidos: :central | :persistencia | :cli

# ================================================================
# BROADCAST
# ================================================================

config :proyecto_final_prg3, :broadcast,
  habilitado: true


#iex.bat --sname persistencia -S mix
#iex.bat --sname central -S mix
#mix run cli.exs

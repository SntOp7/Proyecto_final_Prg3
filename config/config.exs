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
# CONFIGURACIÓN DE NODOS PARA COMUNICACIÓN DISTRIBUIDA
# ================================================================

hostname = :inet.gethostname() |> elem(1) |> to_string()

# Nodo persistencia al que CENTRAL debe conectarse
config :proyecto_final_prg3,
  nodos: [
    :"persistencia@#{hostname}"
  ]

# Nodo central al que CLI debe conectarse
config :proyecto_final_prg3,
  central_node: :"central@#{hostname}"

# ================================================================
# TIPO DE NODO ACTUAL
# Cambia este valor manualmente antes de ejecutar cada nodo
# ================================================================

config :proyecto_final_prg3,
  tipo_nodo: :persistencia

# válidos: :central | :persistencia | :cli

# ================================================================
# BROADCAST
# ================================================================

config :proyecto_final_prg3, :broadcast, habilitado: true

# iex.bat --sname persistencia -S mix
# iex.bat --sname central -S mix
# iex.bat --sname cli -S mix run cli.exs

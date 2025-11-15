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
# CONFIGURACIÓN DE PUBSUB (para BroadcastService)
# Usamos el adaptador PG2 (compatible y sin warnings).
# ================================================================

config :proyecto_final_prg3, ProyectoFinalPrg3.PubSub,
  adapter: Phoenix.PubSub.PG2


# ================================================================
# CONFIGURACIÓN DE PERSISTENCIA
# Rutas usadas por ParticipantStore, TeamStore, ProjectStore, etc.
# ================================================================

config :proyecto_final_prg3, :persistencia,
  ruta_data: "data",
  ruta_logs: "logs"


# ================================================================
# CONFIGURACIÓN DE NODOS DISTRIBUIDOS (NodeManager)
# Puedes dejarlo vacío, no genera errores.
# ================================================================

config :proyecto_final_prg3,
  nodos: []


# ================================================================
# CONFIGURACIÓN DE BROADCAST Y NETWORK
# (No requiere valores adicionales por el momento)
# ================================================================

config :proyecto_final_prg3, :broadcast,
  habilitado: true


# ================================================================
# NOTA IMPORTANTE:
# NO se usa import_config "#{config_env()}.exs"
# porque NO trabajamos con entornos dev/prod/test.
# ================================================================

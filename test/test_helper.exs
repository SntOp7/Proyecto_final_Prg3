ExUnit.start()
ExUnit.configure(exclude: [:skip])

# ============================================================
#  🔹 Registro global de Mox
# ============================================================
# Los tests de tu proyecto usan Mox en modo global para evitar
# conflictos con procesos y tests async.
# ============================================================

Mox.set_mox_global()
Mox.defmock(
  ProyectoFinalPrg3.Mocks.CommandRegistryMock,
  for: ProyectoFinalPrg3.Adapters.CLI.CommandRegistryBehaviour
)

# ------------------------------------------------------------
# Si tu proyecto tiene otros behaviours mockeables, regístralos
# aquí siguiendo el mismo patrón:
Mox.defmock(CommandParserMock,
  for: ProyectoFinalPrg3.Behaviours.CommandParserBehaviour
)

#
Mox.defmock(ProyectoFinalPrg3.Mocks.LoggerServiceMock,
for: ProyectoFinalPrg3.Adapters.Logging.LoggerServiceBehaviour)
#
Mox.defmock(ProyectoFinalPrg3.Mocks.AuthServiceMock,
 for: ProyectoFinalPrg3.Services.AuthServiceBehaviour)
#
Mox.defmock(ProyectoFinalPrg3.Mocks.PermissionAdapterMock,
for: ProyectoFinalPrg3.Adapters.Security.PermissionAdapterBehaviour)

Mox.defmock(LoggerServiceMock,
  for: ProyectoFinalPrg3.Adapters.Logging.LoggerServiceBehaviour
)

Mox.defmock(AuthServiceMock,
  for: ProyectoFinalPrg3.Services.AuthServiceBehaviour
)


# ------------------------------------------------------------

# ============================================================
#  🔹 Configuración recomendada para evitar conflictos
# ============================================================

# Permite usar Mox en pruebas asincrónicas (solo si se usa stub_with)
Application.put_env(:mox, :verify_on_exit!, true)

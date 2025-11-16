ExUnit.start()

# ============================================================
# CLI
# ============================================================

Mox.defmock(CommandRegistryMock,
  for: ProyectoFinalPrg3.Adapters.CLI.CommandRegistryBehaviour
)

# ============================================================
# Persistencia
# ============================================================

Mox.defmock(ParticipantStoreMock,
  for: ProyectoFinalPrg3.Adapters.Persistence.ParticipantStoreBehaviour
)

Mox.defmock(ProjectStoreMock,
  for: ProyectoFinalPrg3.Adapters.Persistence.ProjectStoreBehaviour
)

Mox.defmock(TeamStoreMock,
  for: ProyectoFinalPrg3.Adapters.Persistence.TeamStoreBehaviour
)

Mox.defmock(CategoryStoreMock,
  for: ProyectoFinalPrg3.Adapters.Persistence.CategoryStoreBehaviour
)

Mox.defmock(FeedbackStoreMock,
  for: ProyectoFinalPrg3.Adapters.Persistence.FeedbackStoreBehaviour
)

Mox.defmock(ProgressStoreMock,
  for: ProyectoFinalPrg3.Adapters.Persistence.ProgressStoreBehaviour
)

# ============================================================
# Seguridad
# ============================================================

Mox.defmock(TokenManagerMock,
  for: ProyectoFinalPrg3.Adapters.Security.TokenManagerBehaviour
)

Mox.defmock(SessionManagerMock,
  for: ProyectoFinalPrg3.Adapters.Security.SessionManagerBehaviour
)

Mox.defmock(EncryptionAdapterMock,
  for: ProyectoFinalPrg3.Adapters.Security.EncryptionAdapterBehaviour
)

Mox.defmock(PermissionAdapterMock,
  for: ProyectoFinalPrg3.Adapters.Security.PermissionAdapterBehaviour
)

# ============================================================
# Servicios
# ============================================================

Mox.defmock(LoggerServiceMock,
  for: ProyectoFinalPrg3.Adapters.Logging.LoggerServiceBehaviour
)

Mox.defmock(AuthServiceMock,
  for: ProyectoFinalPrg3.Services.AuthServiceBehaviour
)

Mox.defmock(BroadcastServiceMock,
  for: ProyectoFinalPrg3.Services.BroadcastServiceBehaviour
)

# ============================================================
# Network / Cluster / Distributed
# ============================================================

Mox.defmock(NodeManagerMock,
  for: ProyectoFinalPrg3.Adapters.Network.NodeManagerBehaviour
)

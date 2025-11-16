ExUnit.start()
# Mox will be used for test-time mocks. Do NOT set global mode here; tests should call
# `setup :verify_on_exit!` and `import Mox` when needed.

# CLI
Mox.defmock(ProyectoFinalPrg3.MockCommandRegistry, for: ProyectoFinalPrg3.Adapters.CLI.CommandRegistryBehaviour)

# Persistencia
Mox.defmock(ProyectoFinalPrg3.MockParticipantStore, for: ProyectoFinalPrg3.Adapters.Persistence.ParticipantStoreBehaviour)
Mox.defmock(ProyectoFinalPrg3.MockProjectStore, for: ProyectoFinalPrg3.Adapters.Persistence.ProjectStoreBehaviour)
Mox.defmock(ProyectoFinalPrg3.MockTeamStore, for: ProyectoFinalPrg3.Adapters.Persistence.TeamStoreBehaviour)
Mox.defmock(ProyectoFinalPrg3.MockTeamStore,
  for: ProyectoFinalPrg3.Adapters.Persistence.TeamStoreBehaviour
)

Mox.defmock(ProyectoFinalPrg3.MockFeedbackStore, for: ProyectoFinalPrg3.Adapters.Persistence.FeedbackStoreBehaviour)
Mox.defmock(ProyectoFinalPrg3.MockProgressStore, for: ProyectoFinalPrg3.Adapters.Persistence.ProgressStoreBehaviour)

# Seguridad / Autenticación
Mox.defmock(ProyectoFinalPrg3.MockTokenManager, for: ProyectoFinalPrg3.Adapters.Security.TokenManagerBehaviour)
Mox.defmock(ProyectoFinalPrg3.MockSessionManager, for: ProyectoFinalPrg3.Adapters.Security.SessionManagerBehaviour)
Mox.defmock(ProyectoFinalPrg3.MockEncryptionAdapter, for: ProyectoFinalPrg3.Adapters.Security.EncryptionAdapterBehaviour)
Mox.defmock(ProyectoFinalPrg3.MockPermissionAdapter, for: ProyectoFinalPrg3.Adapters.Security.PermissionAdapterBehaviour)

# Servicios y logging
Mox.defmock(ProyectoFinalPrg3.MockLoggerService, for: ProyectoFinalPrg3.Adapters.Logging.LoggerServiceBehaviour)
Mox.defmock(ProyectoFinalPrg3.MockAuthService, for: ProyectoFinalPrg3.Services.AuthServiceBehaviour)
Mox.defmock(ProyectoFinalPrg3.MockBroadcastService, for: ProyectoFinalPrg3.Services.BroadcastServiceBehaviour)

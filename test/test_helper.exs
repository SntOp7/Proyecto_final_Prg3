ExUnit.start()
Mox.defmock(ProyectoFinalPrg3.MockCommandRegistry, for: ProyectoFinalPrg3.Adapters.CLI.CommandRegistryBehaviour)

# ============================
# Persistencia
# ============================
Mox.defmock(ProyectoFinalPrg3.MockParticipantStore,  for: ProyectoFinalPrg3.Adapters.Persistence.ParticipantStoreBehaviour)
Mox.defmock(ProyectoFinalPrg3.MockProjectStore,      for: ProyectoFinalPrg3.Adapters.Persistence.ProjectStoreBehaviour)
Mox.defmock(ProyectoFinalPrg3.MockCategoryStore,     for: ProyectoFinalPrg3.Adapters.Persistence.CategoryStoreBehaviour)
Mox.defmock(ProyectoFinalPrg3.MockFeedbackStore,     for: ProyectoFinalPrg3.Adapters.Persistence.FeedbackStoreBehaviour)
Mox.defmock(ProyectoFinalPrg3.MockProgressStore,     for: ProyectoFinalPrg3.Adapters.Persistence.ProgressStoreBehaviour)

# ============================
# Seguridad / Autenticación
# ============================
Mox.defmock(ProyectoFinalPrg3.MockTokenManager,      for: ProyectoFinalPrg3.Adapters.Security.TokenManagerBehaviour)
Mox.defmock(ProyectoFinalPrg3.MockSessionManager,    for: ProyectoFinalPrg3.Adapters.Security.SessionManagerBehaviour)
Mox.defmock(ProyectoFinalPrg3.MockEncryptionAdapter, for: ProyectoFinalPrg3.Adapters.Security.EncryptionAdapterBehaviour)

# ============================
# Servicios
# ============================
Mox.defmock(ProyectoFinalPrg3.MockLoggerService,     for: ProyectoFinalPrg3.Adapters.Logging.LoggerServiceBehaviour)
Mox.defmock(ProyectoFinalPrg3.MockAuthService,       for: ProyectoFinalPrg3.Services.AuthServiceBehaviour)

# Permitir que los mocks reciban llamadas asíncronas si usas Task o GenServer
Application.put_env(:mox, :global, true)

ExUnit.start()

# Mox: no establecer global aquí. En cada test use:
#   import Mox
#   setup :verify_on_exit!

# ----------------------------
# CLI
# ----------------------------
Mox.defmock(CommandRegistryMock,
  for: ProyectoFinalPrg3.Adapters.CLI.CommandRegistryBehaviour
)
Mox.defmock(ProyectoFinalPrg3.Mocks.CommandRegistryMock,
  for: ProyectoFinalPrg3.Adapters.CLI.CommandRegistryBehaviour
)

Mox.defmock(CommandParserMock,
  for: ProyectoFinalPrg3.Services.CommandParserBehaviour
)
Mox.defmock(ProyectoFinalPrg3.Mocks.CommandParserMock,
  for: ProyectoFinalPrg3.Services.CommandParserBehaviour
)

# ----------------------------
# Persistencia
# ----------------------------
for {name, behaviour} <- [
      {ParticipantStoreMock, ProyectoFinalPrg3.Adapters.Persistence.ParticipantStoreBehaviour},
      {ProjectStoreMock, ProyectoFinalPrg3.Adapters.Persistence.ProjectStoreBehaviour},
      {TeamStoreMock, ProyectoFinalPrg3.Adapters.Persistence.TeamStoreBehaviour},
      {CategoryStoreMock, ProyectoFinalPrg3.Adapters.Persistence.CategoryStoreBehaviour},
      {FeedbackStoreMock, ProyectoFinalPrg3.Adapters.Persistence.FeedbackStoreBehaviour},
      {ProgressStoreMock, ProyectoFinalPrg3.Adapters.Persistence.ProgressStoreBehaviour},
      {MentorStoreMock, ProyectoFinalPrg3.Adapters.Persistence.MentorStoreBehaviour}
    ] do
  Mox.defmock(name, for: behaviour)
  Mox.defmock(Module.concat(ProyectoFinalPrg3.Mocks, name), for: behaviour)
end

# ----------------------------
# Seguridad (security)
# ----------------------------
for {name, behaviour} <- [
      {TokenManagerMock, ProyectoFinalPrg3.Adapters.Security.TokenManagerBehaviour},
      {SessionManagerMock, ProyectoFinalPrg3.Adapters.Security.SessionManagerBehaviour},
      {EncryptionAdapterMock, ProyectoFinalPrg3.Adapters.Security.EncryptionAdapterBehaviour},
      {PermissionAdapterMock, ProyectoFinalPrg3.Adapters.Security.PermissionAdapterBehaviour}
    ] do
  Mox.defmock(name, for: behaviour)
  Mox.defmock(Module.concat(ProyectoFinalPrg3.Mocks, name), for: behaviour)
end

# ----------------------------
# Logging / Servicios
# ----------------------------
Mox.defmock(LoggerServiceMock,
  for: ProyectoFinalPrg3.Adapters.Logging.LoggerServiceBehaviour
)
Mox.defmock(ProyectoFinalPrg3.Mocks.LoggerServiceMock,
  for: ProyectoFinalPrg3.Adapters.Logging.LoggerServiceBehaviour
)

Mox.defmock(AuthServiceMock,
  for: ProyectoFinalPrg3.Services.AuthServiceBehaviour
)
Mox.defmock(ProyectoFinalPrg3.Mocks.AuthServiceMock,
  for: ProyectoFinalPrg3.Services.AuthServiceBehaviour
)

Mox.defmock(BroadcastServiceMock,
  for: ProyectoFinalPrg3.Services.BroadcastServiceBehaviour
)
Mox.defmock(ProyectoFinalPrg3.Mocks.BroadcastServiceMock,
  for: ProyectoFinalPrg3.Services.BroadcastServiceBehaviour
)

# ----------------------------
# Network / Cluster
# ----------------------------
Mox.defmock(NodeManagerMock,
  for: ProyectoFinalPrg3.Adapters.Network.NodeManagerBehaviour
)
Mox.defmock(ProyectoFinalPrg3.Mocks.NodeManagerMock,
  for: ProyectoFinalPrg3.Adapters.Network.NodeManagerBehaviour
)

Mox.defmock(PubSubAdapterMock,
  for: ProyectoFinalPrg3.Adapters.Network.PubSubAdapterBehaviour
)
Mox.defmock(ProyectoFinalPrg3.Mocks.PubSubAdapterMock,
  for: ProyectoFinalPrg3.Adapters.Network.PubSubAdapterBehaviour
)

Mox.defmock(ChannelManagerMock,
  for: ProyectoFinalPrg3.Adapters.Network.ChannelManagerBehaviour
)
Mox.defmock(ProyectoFinalPrg3.Mocks.ChannelManagerMock,
  for: ProyectoFinalPrg3.Adapters.Network.ChannelManagerBehaviour
)

# ----------------------------
# Otros mocks útiles (cubre casos)
# ----------------------------
Mox.defmock(ParticipantManagerMock,
  for: ProyectoFinalPrg3.Services.ParticipantManagerBehaviour
)
Mox.defmock(ProyectoFinalPrg3.Mocks.ParticipantManagerMock,
  for: ProyectoFinalPrg3.Services.ParticipantManagerBehaviour
)
Mox.defmock(ProjectManagerMock,
  for: ProyectoFinalPrg3.Services.ProjectManagerBehaviour
)
Mox.defmock(ProyectoFinalPrg3.Mocks.ProjectManagerMock,
  for: ProyectoFinalPrg3.Services.ProjectManagerBehaviour
)

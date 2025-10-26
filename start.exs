# start.exs
# ============================================================
# Punto de entrada principal del sistema de hackathon
# Inicializa los módulos base, crea las carpetas necesarias
# y prepara los servicios de logging, red y persistencia.
#
# Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
# Fecha de creación: 2025-10-27
# Licencia: GNU GPLv3
# ============================================================

alias ProyectoFinalPrg3.Adapters.Logging.{LoggerService, AuditService}
alias ProyectoFinalPrg3.Adapters.Persistence.{Repository, Datastore}
alias ProyectoFinalPrg3.Adapters.Network.{NodeManager, PubSubAdapter}

# ============================================================
# ETAPA 1: INICIALIZACIÓN DE ESTRUCTURA DE DIRECTORIOS
# ============================================================

IO.puts("\n🚀 Iniciando sistema ProyectoFinalPrg3...\n")

Enum.each(["data", "logs"], fn dir ->
  File.mkdir_p!(dir)
end)

# ============================================================
# ETAPA 2: CONFIGURACIÓN DE LOGGING Y AUDITORÍA
# ============================================================

IO.puts("🧾 Inicializando sistema de logs...")

LoggerService.limpiar_logs()

LoggerService.registrar_evento("Inicio del sistema de hackathon", %{tipo: :info, nodo: Node.self()})

# ============================================================
# ETAPA 3: INICIALIZACIÓN DE SERVICIOS DE RED Y NODOS
# ============================================================

IO.puts("🌐 Inicializando servicios de red...")

NodeManager.inicializar_nodo()
PubSubAdapter.inicializar()

LoggerService.registrar_evento("Servicios de red inicializados", %{tipo: :info})

# ============================================================
# ETAPA 4: CARGA DE DATOS DE PERSISTENCIA
# ============================================================

IO.puts("💾 Cargando datos persistentes (equipos, proyectos, participantes)...")

Repository.inicializar()
Datastore.verificar_integridad()

LoggerService.registrar_evento("Repositorios y datastores cargados", %{tipo: :info})

# ============================================================
# ETAPA 5: EJECUCIÓN Y MONITOREO
# ============================================================

IO.puts("✅ Sistema listo para recibir comandos o eventos.\n")

LoggerService.registrar_evento("Sistema listo", %{tipo: :info})

AuditService.exportar_a_txt("logs/audit_start_report.txt")

# ============================================================
# OPCIONAL: MANTENER SESIÓN ACTIVA
# ============================================================

IO.puts("⌛ Esperando comandos en la consola interactiva...\n")

Process.sleep(:infinity)

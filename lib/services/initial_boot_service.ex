defmodule ProyectoFinalPrg3.Services.InitialBootService do
  @moduledoc """
  Servicio de inicialización del sistema.
  Realiza todas las tareas que antes estaban en start.exs.
  """

  use GenServer

  alias ProyectoFinalPrg3.Adapters.Logging.{LoggerService, AuditService}
  alias ProyectoFinalPrg3.Adapters.Network.{NodeManager, PubSubAdapter}
  alias ProyectoFinalPrg3.Adapters.Persistence.PersistenceManager

  # -------------------------
  # INIT
  # -------------------------
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    inicializar_sistema()
    {:ok, state}
  end

  # -------------------------
  # LÓGICA DE ARRANQUE
  # -------------------------
  defp inicializar_sistema do
    IO.puts("\n🚀 Iniciando sistema ProyectoFinalPrg3...\n")

    # Crear directorios
    Enum.each(["data", "logs"], &File.mkdir_p!/1)

    # Logging
    LoggerService.limpiar_logs()
    LoggerService.registrar_evento("Inicio del sistema de hackathon", %{})

    # Redes
    NodeManager.inicializar_nodo()
    PubSubAdapter.inicializar()

    LoggerService.registrar_evento("Servicios de red inicializados", %{})

    # Persistencia
    PersistenceManager.inicializar()

    LoggerService.registrar_evento("Repositorios cargados", %{})

    AuditService.exportar_a_txt("logs/audit_start_report.txt")

    IO.puts("✔ Sistema listo.\n")
  end
end

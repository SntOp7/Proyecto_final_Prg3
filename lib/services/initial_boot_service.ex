defmodule ProyectoFinalPrg3.Services.InitialBootService do
  @moduledoc """
  Servicio de inicialización del sistema.
  Realiza todas las tareas que antes estaban en start.exs.
  """

  use GenServer

  alias ProyectoFinalPrg3.Adapters.Logging.{LoggerService, AuditService}
  alias ProyectoFinalPrg3.Adapters.Persistence.PersistenceManager

  # -------------------------
  # INIT
  # -------------------------

  def start_link(_args), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @impl true
  def init(:ok) do
    Process.send_after(self(), :boot, 10)
    {:ok, %{}}
  end

  # -------------------------
  # LÓGICA DE ARRANQUE
  # -------------------------

  @impl true
  def handle_info(:boot, state) do
    IO.puts("\n🚀 Iniciando sistema ProyectoFinalPrg3...\n")

    # Logging
    LoggerService.limpiar_logs()
    LoggerService.registrar_evento("Inicio del sistema de hackathon", %{})

    # Persistencia
    PersistenceManager.inicializar()
    LoggerService.registrar_evento("Repositorios cargados", %{})

    AuditService.exportar_a_txt()

    IO.puts("✔ Sistema listo.\n")

    {:noreply, state}
  end
end

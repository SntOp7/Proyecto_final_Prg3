defmodule ProyectoFinalPrg3.Services.InitialBootService do
  @moduledoc """
  Servicio encargado del proceso de arranque e inicialización del sistema.

  `InitialBootService` centraliza todas las tareas que anteriormente se realizaban
  en `start.exs`, garantizando un proceso de inicio ordenado, trazable y seguro.
  Este servicio se ejecuta al inicio de la aplicación y prepara los módulos
  críticos para el funcionamiento del sistema.

  Es utilizado principalmente por:

    - El sistema de arranque (`Application`)
    - Módulos que dependen de la carga inicial de repositorios
    - Servicios de auditoría y registro de eventos

  ## Funciones principales
    - `start_link/1`: Inicia el proceso supervisor de arranque.
    - `init/1`: Programa la ejecución diferida del proceso de boot.
    - `handle_info/2`: Ejecuta las tareas de inicialización del sistema, incluyendo:
        * Limpieza de logs
        * Inicialización de repositorios de persistencia
        * Registro del evento de inicio
        * Exportación de auditorías

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha: 2025-10-27
  Licencia: GNU GPLv3
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

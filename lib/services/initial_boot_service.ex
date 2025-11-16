defmodule ProyectoFinalPrg3.Services.InitialBootService do
  @moduledoc """
  Servicio de inicialización del sistema.
  """

  use GenServer

  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService
  alias ProyectoFinalPrg3.Adapters.Persistence.PersistenceManager

  def start_link(_args), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @impl true
  def init(:ok) do
    Process.send_after(self(), :boot, 10)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:boot, state) do
    LoggerService.registrar_evento("Inicio del sistema de hackathon")

    # Persistencia
    PersistenceManager.inicializar()

    LoggerService.registrar_evento("Sistema cargado")
    IO.puts("✔ Backend listo.")

    {:noreply, state}
  end
end

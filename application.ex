defmodule ProyectoFinalPrg3.Application do
  @moduledoc """
  Módulo principal de la aplicación ProyectoFinalPrg3.
  Se encarga de iniciar y supervisar los procesos y servicios base
  como PubSub, servicios internos (Logging, Audit, Broadcast, etc.)
  y cualquier otro componente que deba mantenerse activo
  durante la ejecución del sistema.
  """

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("🚀 Iniciando aplicación ProyectoFinalPrg3...")

    children = [
      # Servicio PubSub (comunicación interna entre módulos)
      {Phoenix.PubSub, name: ProyectoFinalPrg3.PubSub},

      # Ejemplo: procesos o supervisores internos
      # {ProyectoFinalPrg3.Services.BroadcastService, []},
      # {ProyectoFinalPrg3.Services.LoggingService, []},
      # {ProyectoFinalPrg3.Services.AuditService, []},

      # Ejemplo: registro global o manejador de equipos
      # {ProyectoFinalPrg3.Services.TeamManager, []}
    ]

    # Estrategia de reinicio de los procesos supervisados
    opts = [strategy: :one_for_one, name: ProyectoFinalPrg3.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

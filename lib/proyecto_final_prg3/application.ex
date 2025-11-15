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

    children =
      case Mix.env() do
        :test ->
          []

        _ ->
          [
            {Phoenix.PubSub, name: ProyectoFinalPrg3.PubSub},
            ProyectoFinalPrg3.Services.InitialBootService
          ]
      end

    opts = [strategy: :one_for_one, name: ProyectoFinalPrg3.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

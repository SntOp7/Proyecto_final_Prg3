defmodule ProyectoFinalPrg3.Application do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("🚀 Iniciando aplicación ProyectoFinalPrg3...")

    tipo_nodo = Application.get_env(:proyecto_final_prg3, :tipo_nodo, :central)

    children =
      case tipo_nodo do
        :central ->
          [
            {Phoenix.PubSub, name: ProyectoFinalPrg3.PubSub},
            ProyectoFinalPrg3.Services.InitialBootService
          ]

        :persistencia ->
          [
            ProyectoFinalPrg3.Services.InitialBootService
          ]

        :cli ->
          [
            ProyectoFinalPrg3.Services.InitialBootService
          ]
      end

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: ProyectoFinalPrg3.Supervisor
    )
  end
end

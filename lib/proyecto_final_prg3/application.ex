defmodule ProyectoFinalPrg3.Application do
  @moduledoc """
  Módulo principal de la aplicación ProyectoFinalPrg3.
  Proporciona la configuración y supervisión de los procesos principales según el tipo de nodo configurado.
  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  use Application
  require Logger

  @doc """
  Función que inicia la aplicación ProyectoFinalPrg3, configurando y supervisando los procesos principales según el tipo de nodo.
  """
  def start(_type, _args) do
    Logger.info("🚀 Iniciando aplicación ProyectoFinalPrg3...")

    tipo_nodo = Application.get_env(:proyecto_final_prg3, :tipo_nodo, :central)

    children =
      case tipo_nodo do
        :central ->
          [
            {Phoenix.PubSub, name: ProyectoFinalPrg3.PubSub},
            ProyectoFinalPrg3.Adapters.Network.AnnouncementChannel,
            ProyectoFinalPrg3.Adapters.Network.ChannelManager,
            ProyectoFinalPrg3.Adapters.Network.MentorshipChannel,
            ProyectoFinalPrg3.Services.ChatService,
            ProyectoFinalPrg3.Services.InitialBootService
          ]

        # -----------------------------
        # 🟩 NODO PERSISTENCIA
        # -----------------------------
        :persistencia ->
          [
            ProyectoFinalPrg3.Services.InitialBootService
          ]

        # -----------------------------
        # 🟨 NODO CLI
        # -----------------------------
        :cli ->
          [
            ProyectoFinalPrg3.Services.InitialBootService
          ]
      end

    Supervisor.start_link(
      children,
      strategy: :one_for_one,
      name: ProyectoFinalPrg3.Supervisor
    )
  end
end

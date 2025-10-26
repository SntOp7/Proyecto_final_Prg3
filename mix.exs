defmodule ProyectoFinalPrg3.MixProject do
  use Mix.Project

  def project do
    [
      app: :proyecto_final_prg3,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:elixir_uuid, "~> 1.2"}
    ]
  end
end

defmodule ProyectoFinalPrg3.MixProject do
  use Mix.Project

  def project do
    [
      app: :proyecto_final_prg3,
      version: "1.0.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {ProyectoFinalPrg3.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:uuid, "~> 1.1"},             # UUIDs únicos
      {:jason, "~> 1.4"},            # JSON encoding
      {:phoenix_pubsub, "~> 2.1"},   # Comunicación PubSub
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},  # Documentación
      {:ex_unit_notifier, "~> 1.2", only: :test},        # Notificaciones de test
      {:csv, "~> 3.0"},                                  # Para manejo de archivos CSV
      {:mox, "~> 1.1", only: :test},                     # Mocking en tests
      {:excoveralls, "~> 0.17", only: :test},            # Cobertura de test
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}, # Linter
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false}      # Analizador de tipos
    ]
  end
end

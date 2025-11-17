defmodule ProyectoFinalPrg3.MixProject do
  @moduledoc """
  ProyectoFinalPrg3 es una aplicación desarrollada en Elixir que gestiona equipos, proyectos, participantes y mentores.
  Proporciona funcionalidades para la administración y seguimiento de estos elementos en un entorno colaborativo.
  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """
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
      # UUIDs únicos
      {:uuid, "~> 1.1"},
      # JSON encoding
      {:jason, "~> 1.4"},
      # Comunicación PubSub
      {:phoenix_pubsub, "~> 2.1"},
      # Documentación
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      # Notificaciones de test
      {:ex_unit_notifier, "~> 1.2", only: :test},
      # Para manejo de archivos CSV
      {:csv, "~> 3.0"},
      # Mocking en tests
      {:mox, "~> 1.1", only: :test},
      # Cobertura de test
      {:excoveralls, "~> 0.17", only: :test},
      # Linter
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      # Analizador de tipos
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false}
    ]
  end
end

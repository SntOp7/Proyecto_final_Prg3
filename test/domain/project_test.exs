defmodule Proyecto_final_Prg3.Test.Domain.ProjectTest do
  use ExUnit.Case, async: true
  alias Proyecto_final_Prg3.Domain.Project

  @moduledoc """
  Pruebas unitarias del dominio `Project`.

  Validan:
    - Integridad de la estructura `Project`.
    - Correcta inicialización de atributos.
    - Coherencia entre categorías, estado y relaciones con avances o feedbacks.
    - Compatibilidad con valores nulos o listas vacías.
  """

  describe "Estructura base del proyecto" do
    test "contiene todos los campos esperados" do
      campos = Map.keys(%Project{})
      esperados = [
        :id,
        :nombre,
        :descripcion,
        :categoria,
        :estado,
        :avances,
        :feedbacks
      ]

      assert Enum.sort(campos) == Enum.sort(esperados)
    end
  end

  describe "Creación e inicialización" do
    setup do
      project = %Project{
        id: 1,
        nombre: "EcoFuture",
        descripcion: "Plataforma para reciclaje inteligente con IA",
        categoria: "Sostenibilidad",
        estado: "En desarrollo",
        avances: [
          %{id: 1, descripcion: "Diseño UI completado"},
          %{id: 2, descripcion: "Integración API iniciada"}
        ],
        feedbacks: [
          %{id: 1, comentario: "Buen progreso"},
          %{id: 2, comentario: "Revisar optimización"}
        ]
      }

      %{project: project}
    end

    test "se inicializa correctamente con todos los campos", %{project: project} do
      assert project.id == 1
      assert project.nombre == "EcoFuture"
      assert String.contains?(project.descripcion, "reciclaje")
      assert project.categoria == "Sostenibilidad"
      assert project.estado == "En desarrollo"
      assert is_list(project.avances)
      assert is_list(project.feedbacks)
      assert Enum.count(project.avances) == 2
      assert Enum.count(project.feedbacks) == 2
    end

    test "permite listas vacías o valores nulos" do
      p = %Project{
        id: 2,
        nombre: "SinFeedback",
        descripcion: "Proyecto de prueba sin avances",
        categoria: nil,
        estado: "Pendiente",
        avances: [],
        feedbacks: []
      }

      assert p.categoria == nil
      assert p.avances == []
      assert p.feedbacks == []
    end
  end

  describe "Validaciones básicas de datos" do
    test "nombre y descripción deben ser cadenas válidas" do
      p = %Project{id: 3, nombre: "HealthApp", descripcion: "App de monitoreo de salud", categoria: "Salud", estado: "Activo", avances: [], feedbacks: []}
      assert is_binary(p.nombre)
      assert String.length(p.descripcion) > 5
    end

    test "estado debe ser cadena o átomo" do
      p1 = %Project{estado: "En desarrollo"}
      p2 = %Project{estado: :activo}
      assert is_binary(p1.estado) or is_atom(p1.estado)
      assert is_atom(p2.estado) or is_binary(p2.estado)
    end

    test "avances y feedbacks son listas" do
      p = %Project{avances: [], feedbacks: []}
      assert is_list(p.avances)
      assert is_list(p.feedbacks)
    end
  end
end

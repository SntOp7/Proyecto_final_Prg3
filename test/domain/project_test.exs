defmodule ProyectofinalPrg3.Test.Domain.ProjectTest do
  use ExUnit.Case, async: true
  alias ProyectofinalPrg3.Domain.Project

  @moduledoc """
  Pruebas unitarias del dominio `Project`.

  Validan:
    - Integridad de la estructura `Project`.
    - Correcto funcionamiento del constructor `nuevo/15`.
    - Coherencia de fechas, estado, visibilidad y campos relacionados.
    - Manejo de listas, nulos y tipos de datos.
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
        :fecha_creacion,
        :fecha_actualizacion,
        :equipo_id,
        :mentor_id,
        :avances,
        :retroalimentaciones,
        :repositorio_url,
        :puntaje,
        :visibilidad,
        :tags
      ]

      assert Enum.sort(campos) == Enum.sort(esperados)
    end
  end

  describe "Función nuevo/15" do
    setup do
      fecha_creacion = ~D[2025-10-25]
      fecha_actualizacion = ~D[2025-10-26]

      proyecto = Project.nuevo(
        1,
        "EcoFuture",
        "Plataforma para reciclaje inteligente con IA",
        "Sostenibilidad",
        :en_desarrollo,
        fecha_creacion,
        fecha_actualizacion,
        4,
        2,
        [%{id: 1, titulo: "Inicio del backend"}],
        [%{id: 1, comentario: "Buen progreso"}],
        "https://github.com/ecofuture/repo",
        4.8,
        :publico,
        ["IA", "reciclaje", "sostenible"]
      )

      %{proyecto: proyecto, fecha_creacion: fecha_creacion, fecha_actualizacion: fecha_actualizacion}
    end

    test "se inicializa correctamente con todos los campos", %{proyecto: p, fecha_creacion: fc, fecha_actualizacion: fa} do
      assert p.id == 1
      assert p.nombre == "EcoFuture"
      assert String.contains?(p.descripcion, "reciclaje")
      assert p.categoria == "Sostenibilidad"
      assert p.estado == :en_desarrollo
      assert p.fecha_creacion == fc
      assert p.fecha_actualizacion == fa
      assert p.equipo_id == 4
      assert p.mentor_id == 2
      assert is_list(p.avances)
      assert is_list(p.retroalimentaciones)
      assert String.starts_with?(p.repositorio_url, "https://")
      assert is_float(p.puntaje)
      assert p.visibilidad in [:publico, :privado]
      assert Enum.member?(p.tags, "IA")
    end

    test "permite valores nulos y listas vacías" do
      p = Project.nuevo(
        2,
        "HealthTrack",
        "Aplicación para monitorear la salud física y mental.",
        "Salud",
        :pausado,
        ~D[2025-10-24],
        nil,
        nil,
        nil,
        [],
        [],
        nil,
        nil,
        :privado,
        []
      )

      assert p.fecha_actualizacion == nil
      assert p.equipo_id == nil
      assert p.retroalimentaciones == []
      assert p.repositorio_url == nil
      assert p.puntaje == nil
      assert p.visibilidad == :privado
    end
  end

  describe "Validaciones básicas de datos" do
    test "el nombre y descripción deben ser cadenas válidas" do
      p = Project.nuevo(3, "EduConnect", "Plataforma educativa colaborativa", "Educación", :en_desarrollo, ~D[2025-10-25], nil, 1, 1, [], [], nil, nil, :publico, [])
      assert is_binary(p.nombre)
      assert String.length(p.descripcion) > 5
    end

    test "las fechas deben ser tipo Date" do
      p = Project.nuevo(4, "AgroTech", "IA para cultivos", "Tecnología", :completado, ~D[2025-10-25], ~D[2025-10-26], 1, 2, [], [], nil, nil, :publico, [])
      assert match?(%Date{}, p.fecha_creacion)
      assert match?(%Date{}, p.fecha_actualizacion)
    end

    test "el puntaje puede ser número o nil" do
      p1 = Project.nuevo(5, "Test1", "", "", :pausado, ~D[2025-10-25], nil, nil, nil, [], [], nil, 4.5, :privado, [])
      p2 = Project.nuevo(6, "Test2", "", "", :pausado, ~D[2025-10-25], nil, nil, nil, [], [], nil, nil, :privado, [])
      assert is_float(p1.puntaje)
      assert is_nil(p2.puntaje)
    end

    test "tags debe ser una lista" do
      p = Project.nuevo(7, "TestTags", "", "", :en_desarrollo, ~D[2025-10-25], nil, nil, nil, [], [], nil, nil, :publico, ["Elixir", "Hackathon"])
      assert is_list(p.tags)
      assert Enum.member?(p.tags, "Elixir")
    end
  end
end

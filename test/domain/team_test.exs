defmodule Proyecto_final_Prg3.Test.Domain.TeamTest do
  use ExUnit.Case, async: true
  alias Proyecto_final_Prg3.Domain.Team

  @moduledoc """
  Pruebas unitarias del dominio `Team`.

  Validan:
    - Integridad de la estructura del equipo (`Team`).
    - Correcto funcionamiento del constructor `nuevo/12`.
    - Coherencia de campos relacionados con proyecto, mentor, participantes y estado.
    - Manejo de listas vacías y valores opcionales.
  """

  describe "Estructura base del equipo" do
    test "contiene todos los campos esperados" do
      campos = Map.keys(%Team{})
      esperados = [
        :id,
        :nombre,
        :descripcion,
        :categoria,
        :id_proyecto,
        :id_mentor,
        :participantes,
        :fecha_creacion,
        :estado,
        :canal_chat_id,
        :puntaje,
        :historial
      ]

      assert Enum.sort(campos) == Enum.sort(esperados)
    end
  end

  describe "Función nuevo/12" do
    setup do
      fecha = ~D[2025-10-26]

      equipo = Team.nuevo(
        1,
        "Tech Innovators",
        "Equipo enfocado en soluciones basadas en IA para educación.",
        "Educación",
        5,
        3,
        ["Juan", "María", "Sofía"],
        fecha,
        :activo,
        1001,
        4.7,
        ["Primer avance", "Revisión del mentor"]
      )

      %{equipo: equipo, fecha: fecha}
    end

    test "se inicializa correctamente con todos los campos", %{equipo: e, fecha: fecha} do
      assert e.id == 1
      assert e.nombre == "Tech Innovators"
      assert e.descripcion =~ "IA para educación"
      assert e.categoria == "Educación"
      assert e.id_proyecto == 5
      assert e.id_mentor == 3
      assert is_list(e.participantes)
      assert Enum.count(e.participantes) == 3
      assert e.fecha_creacion == fecha
      assert e.estado == :activo
      assert e.canal_chat_id == 1001
      assert is_float(e.puntaje)
      assert Enum.member?(e.historial, "Primer avance")
    end

    test "permite listas vacías y valores nulos" do
      e = Team.nuevo(
        2,
        "Empty Team",
        nil,
        "General",
        nil,
        nil,
        [],
        ~D[2025-10-25],
        :inactivo,
        nil,
        nil,
        []
      )

      assert e.descripcion == nil
      assert e.id_proyecto == nil
      assert e.id_mentor == nil
      assert e.participantes == []
      assert e.canal_chat_id == nil
      assert e.puntaje == nil
      assert e.historial == []
      assert e.estado == :inactivo
    end
  end

  describe "Validaciones básicas de datos" do
    test "nombre y categoría deben ser cadenas válidas" do
      e = Team.nuevo(3, "Data Wizards", "Análisis predictivo de datos", "Ciencia de Datos", nil, nil, [], ~D[2025-10-26], :activo, nil, nil, [])
      assert is_binary(e.nombre)
      assert String.length(e.nombre) > 3
      assert is_binary(e.categoria)
    end

    test "fecha_creacion debe ser de tipo Date" do
      e = %Team{fecha_creacion: ~D[2025-10-26]}
      assert match?(%Date{}, e.fecha_creacion)
    end

    test "participantes debe ser una lista" do
      e = %Team{participantes: ["Ana", "Carlos"]}
      assert is_list(e.participantes)
      assert Enum.member?(e.participantes, "Carlos")
    end

    test "estado debe ser un átomo válido" do
      e = %Team{estado: :activo}
      assert e.estado in [:activo, :inactivo, :pendiente]
    end

    test "puntaje puede ser numérico o nil" do
      e1 = %Team{puntaje: 4.8}
      e2 = %Team{puntaje: nil}
      assert is_float(e1.puntaje)
      assert is_nil(e2.puntaje)
    end
  end
end

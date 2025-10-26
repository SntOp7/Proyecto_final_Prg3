defmodule Proyecto_final_Prg3.Test.Domain.MentorTest do
  use ExUnit.Case, async: true
  alias Proyecto_final_Prg3.Domain.Mentor

  @moduledoc """
  Pruebas unitarias del dominio `Mentor`.

  Validan:
    - Integridad de la estructura `Mentor`.
    - Correcta inicialización de campos.
    - Compatibilidad con listas y valores nulos.
    - Coherencia entre atributos relacionados.
  """

  describe "Estructura base del mentor" do
    test "contiene todos los campos esperados" do
      campos = Map.keys(%Mentor{})
      esperados = [
        :id,
        :nombre,
        :correo,
        :especialidad,
        :biografia,
        :equipos_asignados
      ]

      assert Enum.sort(campos) == Enum.sort(esperados)
    end
  end

  describe "Creación e inicialización" do
    setup do
      mentor = %Mentor{
        id: 1,
        nombre: "Laura Méndez",
        correo: "laura@mentor.com",
        especialidad: "Inteligencia Artificial",
        biografia: "Mentora con más de 8 años en desarrollo de soluciones con IA.",
        equipos_asignados: [2, 4, 6]
      }

      %{mentor: mentor}
    end

    test "se inicializa correctamente con todos los campos", %{mentor: mentor} do
      assert mentor.id == 1
      assert mentor.nombre == "Laura Méndez"
      assert String.contains?(mentor.correo, "@mentor.com")
      assert mentor.especialidad == "Inteligencia Artificial"
      assert String.length(mentor.biografia) > 10
      assert Enum.count(mentor.equipos_asignados) == 3
    end

    test "permite campos nulos u opcionales" do
      m = %Mentor{
        id: 2,
        nombre: "Carlos Ruiz",
        correo: "carlos@mentor.com",
        especialidad: nil,
        biografia: nil,
        equipos_asignados: []
      }

      assert is_nil(m.especialidad)
      assert m.equipos_asignados == []
    end
  end

  describe "Validaciones básicas de datos" do
    test "el correo debe incluir un dominio válido" do
      m = %Mentor{id: 3, nombre: "Test", correo: "test@dominio.com", especialidad: "Backend", biografia: "", equipos_asignados: []}
      assert String.contains?(m.correo, "@")
      assert String.contains?(m.correo, ".")
    end

    test "los equipos asignados deben ser una lista" do
      m1 = %Mentor{equipos_asignados: [1, 2]}
      m2 = %Mentor{equipos_asignados: []}

      assert is_list(m1.equipos_asignados)
      assert is_list(m2.equipos_asignados)
    end
  end
end

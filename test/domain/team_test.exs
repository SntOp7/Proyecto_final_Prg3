defmodule Proyecto_final_Prg3.Test.Domain.TeamTest do
  use ExUnit.Case, async: true
  alias Proyecto_final_Prg3.Domain.Team

  @moduledoc """
  Pruebas unitarias del dominio `Team`.

  Validan:
    - Integridad de la estructura `Team`.
    - Correcta inicialización de los campos.
    - Compatibilidad con valores opcionales.
    - Consistencia de datos entre campos relacionados.
  """

  describe "Estructura base del equipo" do
    test "contiene todos los campos esperados" do
      campos = Map.keys(%Team{})
      esperados = [
        :id,
        :nombre,
        :descripcion,
        :participantes,
        :proyecto_id
      ]

      assert Enum.sort(campos) == Enum.sort(esperados)
    end
  end

  describe "Creación de equipos" do
    setup do
      team = %Team{
        id: 1,
        nombre: "Innovadores del Futuro",
        descripcion: "Equipo enfocado en soluciones educativas con IA",
        participantes: [1, 2, 3],
        proyecto_id: 5
      }

      %{team: team}
    end

    test "se inicializa correctamente con todos los campos", %{team: team} do
      assert team.id == 1
      assert team.nombre == "Innovadores del Futuro"
      assert String.contains?(team.descripcion, "educativas")
      assert is_list(team.participantes)
      assert Enum.count(team.participantes) == 3
      assert team.proyecto_id == 5
    end

    test "permite listas vacías o nil en participantes" do
      t1 = %Team{id: 2, nombre: "Sin miembros", descripcion: "", participantes: [], proyecto_id: nil}
      t2 = %Team{id: 3, nombre: "Pendiente", descripcion: nil, participantes: nil, proyecto_id: nil}

      assert t1.participantes == []
      assert t2.participantes == nil
      assert t2.descripcion == nil
    end
  end

  describe "Validaciones básicas de datos" do
    test "el nombre del equipo es una cadena no vacía" do
      t = %Team{id: 10, nombre: "CodeMasters", descripcion: "Desarrollo backend", participantes: [], proyecto_id: 1}
      assert is_binary(t.nombre)
      assert String.length(t.nombre) > 0
    end

    test "participantes es siempre una lista o nil" do
      t1 = %Team{participantes: [1, 2]}
      t2 = %Team{participantes: nil}

      assert is_list(t1.participantes)
      assert is_nil(t2.participantes)
    end
  end
end

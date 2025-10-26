defmodule Proyecto_final_Prg3.Test.Domain.CategoryTest do
  use ExUnit.Case, async: true
  alias Proyecto_final_Prg3.Domain.Category

  @moduledoc """
  Pruebas unitarias del dominio `Category`.

  Validan:
    - Integridad de la estructura `Category`.
    - Funcionamiento correcto del constructor `nuevo/7`.
    - Coherencia de los campos relacionados con proyectos, creación y estado.
    - Compatibilidad con listas vacías y valores nulos.
  """

  describe "Estructura base de categoría" do
    test "contiene todos los campos esperados" do
      campos = Map.keys(%Category{})
      esperados = [
        :id,
        :nombre,
        :descripcion,
        :proyectos,
        :fecha_creacion,
        :creador_id,
        :activo
      ]

      assert Enum.sort(campos) == Enum.sort(esperados)
    end
  end

  describe "Función nuevo/7" do
    setup do
      fecha = ~D[2025-10-26]

      categoria = Category.nuevo(
        1,
        "Innovación Social",
        "Proyectos enfocados en resolver problemáticas sociales mediante tecnología.",
        [10, 12, 15],
        fecha,
        2,
        true
      )

      %{categoria: categoria, fecha: fecha}
    end

    test "se inicializa correctamente con todos los campos", %{categoria: c, fecha: fecha} do
      assert c.id == 1
      assert c.descripcion =~ "problemáticas sociales"
      assert is_list(c.proyectos)
      assert Enum.count(c.proyectos) == 3
      assert c.fecha_creacion == fecha
      assert c.creador_id == 2
      assert c.activo == true
    end

    test "permite valores nulos o listas vacías" do
      c = Category.nuevo(
        2,
        "Salud",
        nil,
        [],
        ~D[2025-10-25],
        nil,
        false
      )

      assert c.descripcion == nil
      assert c.proyectos == []
      assert c.creador_id == nil
      assert c.activo == false
    end
  end

  describe "Validaciones básicas de datos" do
    test "el nombre debe ser una cadena válida" do
      c = %Category{nombre: "Educación", descripcion: "Proyectos de mejora educativa"}
      assert is_binary(c.nombre)
      assert String.length(c.nombre) > 3
    end

    test "la fecha de creación debe ser de tipo Date" do
      c = %Category{fecha_creacion: ~D[2025-10-26]}
      assert match?(%Date{}, c.fecha_creacion)
    end

    test "proyectos debe ser una lista" do
      c = %Category{proyectos: [1, 2, 3]}
      assert is_list(c.proyectos)
    end

    test "activo debe ser un valor booleano" do
      c1 = %Category{activo: true}
      c2 = %Category{activo: false}

      assert is_boolean(c1.activo)
      assert is_boolean(c2.activo)
    end
  end
end

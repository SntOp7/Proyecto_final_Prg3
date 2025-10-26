defmodule Proyecto_final_Prg3.Test.Domain.ProgressTest do
  use ExUnit.Case, async: true
  alias Proyecto_final_Prg3.Domain.Progress

  @moduledoc """
  Pruebas unitarias del dominio `Progress`.

  Validan:
    - Integridad de la estructura `Progress`.
    - Correcto funcionamiento del constructor `nuevo/11`.
    - Coherencia de tipos, fechas y estados.
    - Compatibilidad con listas, valores nulos y versiones.
  """

  describe "Estructura base del avance" do
    test "contiene todos los campos esperados" do
      campos = Map.keys(%Progress{})
      esperados = [
        :id,
        :proyecto_id,
        :equipo_id,
        :titulo,
        :descripcion,
        :fecha_registro,
        :autor_id,
        :estado,
        :retroalimentacion,
        :adjuntos,
        :version
      ]

      assert Enum.sort(campos) == Enum.sort(esperados)
    end
  end

  describe "Función nuevo/11" do
    setup do
      fecha = ~N[2025-10-25 14:30:00]

      avance = Progress.nuevo(
        1,
        101,
        12,
        "Integración del chat en tiempo real",
        "Se completó la implementación de Phoenix Channels para la mensajería de equipo.",
        fecha,
        5,
        "aprobado",
        "Excelente trabajo, integración fluida.",
        ["https://repo.com/commit/abc123", "https://image.com/demo.png"],
        "v1.2"
      )

      %{avance: avance, fecha: fecha}
    end

    test "se inicializa correctamente con todos los campos", %{avance: avance, fecha: fecha} do
      assert avance.id == 1
      assert avance.proyecto_id == 101
      assert avance.equipo_id == 12
      assert avance.titulo == "Integración del chat en tiempo real"
      assert String.contains?(avance.descripcion, "Phoenix Channels")
      assert avance.fecha_registro == fecha
      assert avance.autor_id == 5
      assert avance.estado == "aprobado"
      assert String.contains?(avance.retroalimentacion, "Excelente")
      assert length(avance.adjuntos) == 2
      assert avance.version == "v1.2"
    end

    test "permite campos nulos u opcionales" do
      a = Progress.nuevo(
        2,
        200,
        nil,
        "Estructura inicial creada",
        "Se definieron los módulos base.",
        ~D[2025-10-24],
        8,
        "pendiente",
        nil,
        [],
        nil
      )

      assert a.equipo_id == nil
      assert a.retroalimentacion == nil
      assert a.adjuntos == []
      assert a.version == nil
    end
  end

  describe "Validaciones básicas de datos" do
    test "la fecha debe ser tipo Date o NaiveDateTime" do
      a1 = Progress.nuevo(1, 1, 1, "Test", "desc", ~D[2025-10-26], 1, "pendiente", nil, [], "v1.0")
      a2 = Progress.nuevo(2, 1, 1, "Test", "desc", ~N[2025-10-26 12:00:00], 1, "pendiente", nil, [], "v1.0")

      assert match?(%Date{}, a1.fecha_registro)
      assert match?(%NaiveDateTime{}, a2.fecha_registro)
    end

    test "estado debe ser una cadena válida" do
      a = Progress.nuevo(1, 1, 1, "Título", "desc", ~D[2025-10-26], 2, "en revisión", nil, [], "v1.0")
      assert a.estado in ["pendiente", "en revisión", "aprobado"]
    end

    test "los adjuntos deben ser una lista" do
      a = Progress.nuevo(3, 1, 2, "Adjuntos", "desc", ~D[2025-10-26], 3, "pendiente", nil, ["link1"], "v1.0")
      assert is_list(a.adjuntos)
    end

    test "version puede ser cadena o nil" do
      a1 = Progress.nuevo(4, 1, 1, "Versión", "desc", ~D[2025-10-26], 3, "pendiente", nil, [], "v2.0")
      a2 = Progress.nuevo(5, 1, 1, "Versión", "desc", ~D[2025-10-26], 3, "pendiente", nil, [], nil)

      assert is_binary(a1.version)
      assert is_nil(a2.version)
    end
  end
end

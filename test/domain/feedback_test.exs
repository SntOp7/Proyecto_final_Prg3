defmodule ProyectofinalPrg3.Test.Domain.FeedbackTest do
  use ExUnit.Case, async: true
  alias ProyectofinalPrg3.Domain.Feedback

  @moduledoc """
  Pruebas unitarias del dominio `Feedback`.

  Validan:
    - Integridad de la estructura `Feedback`.
    - Correcto funcionamiento del constructor `nuevo/10`.
    - Coherencia entre los campos relacionados (mentor, proyecto, avance).
    - Manejo adecuado de niveles, visibilidad y estados.
  """

  describe "Estructura base de feedback" do
    test "contiene todos los campos esperados" do
      campos = Map.keys(%Feedback{})
      esperados = [
        :id,
        :mentor_id,
        :proyecto_id,
        :equipo_id,
        :avance_id,
        :contenido,
        :fecha_creacion,
        :nivel,
        :visibilidad,
        :estado
      ]

      assert Enum.sort(campos) == Enum.sort(esperados)
    end
  end

  describe "Función nuevo/10" do
    setup do
      fecha = ~N[2025-10-26 16:45:00]

      feedback = Feedback.nuevo(
        1,
        2,
        10,
        5,
        7,
        "Buen trabajo en la integración del módulo, revisar documentación.",
        fecha,
        "corrección",
        "privado",
        "pendiente"
      )

      %{feedback: feedback, fecha: fecha}
    end

    test "se inicializa correctamente con todos los campos", %{feedback: f, fecha: fecha} do
      assert f.id == 1
      assert f.mentor_id == 2
      assert f.proyecto_id == 10
      assert f.equipo_id == 5
      assert f.avance_id == 7
      assert String.contains?(f.contenido, "integración")
      assert f.fecha_creacion == fecha
      assert f.nivel == "corrección"
      assert f.visibilidad == "privado"
      assert f.estado == "pendiente"
    end

    test "permite campos nulos u opcionales" do
      f = Feedback.nuevo(
        2,
        3,
        8,
        nil,
        nil,
        "Retroalimentación general para el proyecto.",
        ~N[2025-10-25 10:00:00],
        "informativo",
        "público",
        "revisado"
      )

      assert is_nil(f.equipo_id)
      assert is_nil(f.avance_id)
      assert f.visibilidad == "público"
      assert f.estado == "revisado"
    end
  end

  describe "Validaciones básicas de datos" do
    test "el contenido debe ser una cadena válida" do
      f = Feedback.nuevo(1, 2, 3, nil, nil, "Comentario de prueba", ~N[2025-10-25 11:00:00], "elogio", "privado", "pendiente")
      assert is_binary(f.contenido)
      assert String.length(f.contenido) > 5
    end

    test "el nivel debe pertenecer a los valores válidos" do
      f = Feedback.nuevo(2, 1, 2, nil, nil, "Test", ~N[2025-10-26 12:00:00], "informativo", "público", "aplicado")
      assert f.nivel in ["informativo", "corrección", "elogio"]
    end

    test "la visibilidad debe ser 'privado' o 'público'" do
      f1 = Feedback.nuevo(3, 1, 1, nil, nil, "Comentario 1", ~N[2025-10-26 09:00:00], "informativo", "privado", "pendiente")
      f2 = Feedback.nuevo(4, 1, 1, nil, nil, "Comentario 2", ~N[2025-10-26 09:00:00], "informativo", "público", "pendiente")

      assert f1.visibilidad in ["privado", "público"]
      assert f2.visibilidad in ["privado", "público"]
    end

    test "el estado debe ser uno de los definidos" do
      f = Feedback.nuevo(5, 1, 1, nil, nil, "Comentario", ~N[2025-10-26 09:00:00], "informativo", "privado", "aplicado")
      assert f.estado in ["pendiente", "revisado", "aplicado"]
    end

    test "la fecha debe ser tipo NaiveDateTime" do
      f = Feedback.nuevo(6, 1, 1, nil, nil, "Comentario", ~N[2025-10-26 14:00:00], "informativo", "público", "pendiente")
      assert match?(%NaiveDateTime{}, f.fecha_creacion)
    end
  end
end

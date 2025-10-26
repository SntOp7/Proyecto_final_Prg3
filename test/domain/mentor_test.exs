defmodule Proyecto_final_Prg3.Test.Domain.MentorTest do
  use ExUnit.Case, async: true
  alias Proyecto_final_Prg3.Domain.Mentor

  @moduledoc """
  Pruebas unitarias del dominio `Mentor`.

  Validan:
    - Integridad de la estructura `Mentor`.
    - Correcto funcionamiento del constructor `nuevo/12`.
    - Coherencia entre los campos de disponibilidad, rol y estado activo.
    - Soporte para listas, fechas y valores opcionales.
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
        :equipos_asignados,
        :disponibilidad,
        :canal_mentoria_id,
        :fecha_registro,
        :retroalimentaciones,
        :rol,
        :activo
      ]

      assert Enum.sort(campos) == Enum.sort(esperados)
    end
  end

  describe "Función nuevo/12" do
    setup do
      fecha = ~N[2025-10-26 09:30:00]

      mentor = Mentor.nuevo(
        1,
        "Laura Méndez",
        "laura@mentor.com",
        "Inteligencia Artificial",
        "Mentora con 10 años de experiencia en desarrollo de IA.",
        [1, 2, 3],
        :disponible,
        101,
        fecha,
        ["Feedback positivo", "Revisión técnica"],
        "técnico",
        true
      )

      %{mentor: mentor, fecha: fecha}
    end

    test "se inicializa correctamente con todos los campos", %{mentor: m, fecha: fecha} do
      assert m.id == 1
      assert m.nombre == "Laura Méndez"
      assert m.correo == "laura@mentor.com"
      assert m.especialidad == "Inteligencia Artificial"
      assert String.contains?(m.biografia, "IA")
      assert Enum.count(m.equipos_asignados) == 3
      assert m.disponibilidad == :disponible
      assert m.canal_mentoria_id == 101
      assert m.fecha_registro == fecha
      assert Enum.member?(m.retroalimentaciones, "Feedback positivo")
      assert m.rol == "técnico"
      assert m.activo == true
    end

    test "permite valores nulos u opcionales" do
      m = Mentor.nuevo(
        2,
        "Carlos Ruiz",
        "carlos@mentor.com",
        nil,
        nil,
        [],
        :ocupado,
        nil,
        ~N[2025-10-25 10:00:00],
        [],
        "metodológico",
        false
      )

      assert is_nil(m.especialidad)
      assert is_nil(m.canal_mentoria_id)
      assert is_list(m.retroalimentaciones)
      assert m.activo == false
    end
  end

  describe "Validaciones básicas de datos" do
    test "el correo debe contener '@'" do
      m = Mentor.nuevo(3, "Ana", "ana@correo.com", "UX/UI", "", [], :disponible, 10, ~N[2025-10-26 09:00:00], [], "general", true)
      assert String.contains?(m.correo, "@")
    end

    test "disponibilidad debe ser un átomo válido" do
      m = Mentor.nuevo(4, "José", "jose@mentor.com", "Backend", "", [], :ocupado, 20, ~N[2025-10-26 09:00:00], [], "técnico", true)
      assert m.disponibilidad in [:disponible, :ocupado, :desconectado]
    end

    test "activo debe ser booleano" do
      m1 = Mentor.nuevo(5, "Sofía", "sofia@mentor.com", "", "", [], :disponible, nil, ~N[2025-10-26 09:00:00], [], "técnico", true)
      m2 = Mentor.nuevo(6, "Diego", "diego@mentor.com", "", "", [], :ocupado, nil, ~N[2025-10-26 09:00:00], [], "técnico", false)
      assert is_boolean(m1.activo)
      assert is_boolean(m2.activo)
    end

    test "la fecha debe ser tipo NaiveDateTime" do
      m = Mentor.nuevo(7, "María", "maria@mentor.com", "", "", [], :disponible, nil, ~N[2025-10-26 08:00:00], [], "general", true)
      assert match?(%NaiveDateTime{}, m.fecha_registro)
    end
  end
end

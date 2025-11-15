defmodule ProyectoFinalPrg3.Adapters.Persistence.MentorStoreTest do
  use ExUnit.Case, async: true

  alias ProyectoFinalPrg3.Adapters.Persistence.MentorStore
  alias ProyectoFinalPrg3.Domain.Mentor

  @csv_file "data/mentores.csv"

  @encabezado "id,nombre,correo,especialidad,biografia,equipos_asignados,disponibilidad,canal_mentoria_id,fecha_registro,retroalimentaciones,rol,activo"

  setup do
    File.rm_rf!("data")
    File.mkdir_p!("data")

    File.write!(@csv_file, @encabezado <> "\n")
    :ok
  end

  describe "listar_mentores/0" do
    test "retorna lista vacía si el archivo está vacío" do
      # El archivo ya está creado con solo encabezado
      assert MentorStore.listar_mentores() == []
    end
  end

  describe "guardar_mentor/1" do
    test "guarda un mentor correctamente" do
      mentor = %Mentor{
        id: "M1",
        nombre: "Carlos Mentor",
        correo: "mentor@mail.com",
        especialidad: "Backend",
        biografia: "Senior dev",
        equipos_asignados: ["E1", "E2"],
        disponibilidad: "alta",
        canal_mentoria_id: "C10",
        fecha_registro: DateTime.utc_now(),
        retroalimentaciones: ["F1"],
        rol: "mentor",
        activo: true
      }

      assert {:ok, _} = MentorStore.guardar_mentor(mentor)

      contenido = File.read!(@csv_file)
      assert String.contains?(contenido, "Carlos Mentor")
      assert String.contains?(contenido, "Backend")
    end
  end
end

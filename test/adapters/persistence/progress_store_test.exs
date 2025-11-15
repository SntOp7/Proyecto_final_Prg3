defmodule ProyectoFinalPrg3.Adapters.Persistence.ProgressStoreTest do
  use ExUnit.Case, async: true

  alias ProyectoFinalPrg3.Adapters.Persistence.ProgressStore
  alias ProyectoFinalPrg3.Domain.Progress

  @ruta "data/progress.csv"

  setup do
    File.rm_rf!("data")
    File.mkdir_p!("data")

    encabezado =
      "id,proyecto_id,equipo_id,titulo,descripcion,fecha_registro,autor_id,estado,retroalimentacion,adjuntos,version"

    File.write!(@ruta, encabezado <> "\n")

    :ok
  end

  describe "guardar_progreso/1" do
    test "guarda correctamente un nuevo avance" do
      progreso = %Progress{
        id: "PR1",
        proyecto_id: "P1",
        equipo_id: "E1",
        titulo: "Primer avance",
        descripcion: "Descripción del avance",
        fecha_registro: DateTime.utc_now(),
        autor_id: "U1",
        estado: :abierto,
        retroalimentacion: ["Bien"],
        adjuntos: ["file.png"],
        version: 1
      }

      assert {:ok, _} = ProgressStore.guardar_progreso(progreso)

      contenido = File.read!(@ruta)
      assert String.contains?(contenido, "Primer avance")
    end
  end
end

defmodule ProyectoFinalPrg3.Adapters.Persistence.ProgressStoreTest do
  use ExUnit.Case, async: true
  alias ProyectoFinalPrg3.Adapters.Persistence.ProgressStore
  alias ProyectoFinalPrg3.Domain.Progress

  @temp_file Path.join(["tmp", "progress_test.csv"])

  setup do
    File.rm_rf!("tmp")
    File.mkdir_p!("tmp")
    put_in(Process.get(:progress_store_path), @temp_file)
    :ok
  end

  describe "guardar_avance/1" do
    test "guarda correctamente un nuevo avance" do
      avance = %Progress{
        id: "A1",
        proyecto_id: "P1",
        autor_id: "U1",
        titulo: "Diseño de interfaz",
        descripcion: "Primer mockup de la UI del sistema",
        fecha: DateTime.utc_now(),
        estado: :en_revision,
        metadatos: %{archivo: "ui.png"}
      }

      assert ProgressStore.guardar_avance(avance) == :ok
      contenido = File.read!("data/progress.csv")
      assert String.contains?(contenido, "Diseño de interfaz")
      assert String.contains?(contenido, "ui.png")
    end

    test "reemplaza un avance existente si el ID coincide" do
      a1 = %Progress{id: "A2", proyecto_id: "P1", autor_id: "U1", titulo: "Test 1", descripcion: "x", fecha: DateTime.utc_now(), estado: :completado, metadatos: %{}}
      a2 = %Progress{id: "A2", proyecto_id: "P1", autor_id: "U1", titulo: "Actualizado", descripcion: "Nueva desc", fecha: DateTime.utc_now(), estado: :en_revision, metadatos: %{}}

      ProgressStore.guardar_avance(a1)
      ProgressStore.guardar_avance(a2)

      contenido = File.read!("data/progress.csv")
      refute String.contains?(contenido, "Test 1")
      assert String.contains?(contenido, "Actualizado")
    end
  end

  describe "listar_avances/0" do
    test "retorna lista vacía si no existe el archivo" do
      File.rm_rf!("data")
      assert ProgressStore.listar_avances() == []
    end

    test "retorna todos los avances correctamente" do
      a1 = %Progress{id: "A3", proyecto_id: "PX", autor_id: "U1", titulo: "Análisis", descripcion: "Se analizó...", fecha: DateTime.utc_now(), estado: :en_progreso, metadatos: %{}}
      a2 = %Progress{id: "A4", proyecto_id: "PY", autor_id: "U2", titulo: "Diseño", descripcion: "Se diseñó...", fecha: DateTime.utc_now(), estado: :en_revision, metadatos: %{}}

      ProgressStore.guardar_avance(a1)
      ProgressStore.guardar_avance(a2)

      lista = ProgressStore.listar_avances()
      assert length(lista) >= 2
      assert Enum.any?(lista, &(&1.titulo == "Análisis"))
    end
  end

  describe "obtener_avance/1" do
    test "obtiene correctamente un avance existente" do
      id = "A5"
      avance = %Progress{id: id, proyecto_id: "P5", autor_id: "U1", titulo: "Backend", descripcion: "Implementación API", fecha: DateTime.utc_now(), estado: :en_progreso, metadatos: %{test: true}}
      ProgressStore.guardar_avance(avance)

      encontrado = ProgressStore.obtener_avance(id)
      assert encontrado.id == id
      assert encontrado.titulo == "Backend"
    end

    test "retorna nil si no existe el avance" do
      assert ProgressStore.obtener_avance("XYZ") == nil
    end
  end

  describe "listar_por_proyecto/1" do
    test "filtra avances por ID de proyecto" do
      a1 = %Progress{id: "A6", proyecto_id: "PROJ1", autor_id: "U1", titulo: "Doc", descripcion: "Se escribió doc", fecha: DateTime.utc_now(), estado: :en_revision, metadatos: %{}}
      a2 = %Progress{id: "A7", proyecto_id: "PROJ2", autor_id: "U1", titulo: "API", descripcion: "Endpoints", fecha: DateTime.utc_now(), estado: :en_revision, metadatos: %{}}

      ProgressStore.guardar_avance(a1)
      ProgressStore.guardar_avance(a2)

      resultado = ProgressStore.listar_por_proyecto("PROJ1")
      assert Enum.all?(resultado, &(&1.proyecto_id == "PROJ1"))
    end
  end

  describe "eliminar_avance/1" do
    test "elimina correctamente un avance por ID" do
      avance = %Progress{id: "DEL1", proyecto_id: "PX", autor_id: "U1", titulo: "Eliminar", descripcion: "x", fecha: DateTime.utc_now(), estado: :en_revision, metadatos: %{}}
      ProgressStore.guardar_avance(avance)
      assert :ok = ProgressStore.eliminar_avance("DEL1")

      lista = ProgressStore.listar_avances()
      refute Enum.any?(lista, fn a -> a.id == "DEL1" end)
    end
  end

  describe "funciones privadas de serialización" do
    test "serializar_avance convierte un struct a línea CSV" do
      avance = %Progress{id: "PX1", proyecto_id: "P", autor_id: "U", titulo: "Título", descripcion: "Descripción", fecha: DateTime.utc_now(), estado: :en_progreso, metadatos: %{x: 1}}
      csv = :erlang.apply(ProgressStore, :serializar_avance, [avance])
      assert String.contains?(csv, "Título")
      assert String.contains?(csv, "x")
    end

    test "parsear_linea convierte línea CSV en estructura Progress" do
      fecha = DateTime.utc_now() |> DateTime.to_iso8601()
      json = Jason.encode!(%{archivo: "test.txt"})
      linea = "1,PROJX,USER1,Titulo,Descripcion,#{fecha},en_revision,#{json}"

      result = :erlang.apply(ProgressStore, :parsear_linea, [linea])
      assert result.id == "1"
      assert result.estado == :en_revision
      assert result.metadatos["archivo"] == "test.txt"
    end

    test "serialize_json convierte mapa a JSON y viceversa" do
      mapa = %{a: 1}
      json = :erlang.apply(ProgressStore, :serialize_json, [mapa])
      assert is_binary(json)

      mapa2 = :erlang.apply(ProgressStore, :parse_json, [json])
      assert mapa2["a"] == 1
    end
  end
end

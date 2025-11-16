defmodule ProyectoFinalPrg3.Adapters.Persistence.ProgressStoreTest do
  use ExUnit.Case, async: true

  alias ProyectoFinalPrg3.Adapters.Persistence.ProgressStore
  alias ProyectoFinalPrg3.Domain.Progress

  @ruta "data/progress.csv"

  setup do
    File.rm_rf!("data")
    File.mkdir_p!("data")

    # Crear archivo con encabezados oficiales del módulo
    File.write!(@ruta, Enum.join(ProgressStore.obtener_headers(), ",") <> "\n")

    :ok
  end

  # ============================================================
  # 1. guardar_progreso/1
  # ============================================================

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
      assert contenido =~ "Primer avance"
      assert contenido =~ "Descripción del avance"
    end

    test "actualiza un avance existente sin duplicarlo" do
      p1 = %Progress{
        id: "PR2",
        proyecto_id: "P1",
        equipo_id: "E1",
        titulo: "Versión 1",
        descripcion: "Desc 1",
        fecha_registro: DateTime.utc_now(),
        autor_id: "U2",
        estado: :abierto,
        retroalimentacion: [],
        adjuntos: [],
        version: 1
      }

      p2 = %Progress{p1 | titulo: "Versión 2", descripcion: "Desc actualizada", version: 2}

      ProgressStore.guardar_progreso(p1)
      ProgressStore.guardar_progreso(p2)

      contenido = File.read!(@ruta)

      assert contenido =~ "Versión 2"
      refute contenido =~ "Versión 1"
    end
  end

  # ============================================================
  # 2. listar/obtener
  # ============================================================

  describe "consultas" do
    test "listar_avances/0 retorna vacía si no hay registros" do
      File.write!(@ruta, Enum.join(ProgressStore.obtener_headers(), ",") <> "\n")
      assert ProgressStore.listar_avances() == []
    end

    test "obtener_progreso/1 retorna {:ok, progreso} si existe" do
      p = %Progress{
        id: "PZ10",
        proyecto_id: "PRJ9",
        equipo_id: "EX",
        titulo: "Avance X",
        descripcion: "Contenido",
        fecha_registro: DateTime.utc_now(),
        autor_id: "U77",
        estado: :abierto,
        retroalimentacion: [],
        adjuntos: [],
        version: 1
      }

      ProgressStore.guardar_progreso(p)

      {:ok, encontrado} = ProgressStore.obtener_progreso("PZ10")
      assert encontrado.id == "PZ10"
      assert encontrado.titulo == "Avance X"
    end

    test "obtener_progreso/1 retorna :no_encontrado si no existe" do
      assert ProgressStore.obtener_progreso("NOPE") == {:error, :no_encontrado}
    end
  end

  # ============================================================
  # 3. pruebas internas (serialización y parseo)
  # ============================================================

  describe "serialización y parseo" do
    test "parse_csv_line construye correctamente un struct Progress" do
      dt = DateTime.utc_now() |> DateTime.to_iso8601()

      linea =
        "10,PX,EX,Titulo,Desc,#{dt},U1,abierto,Bien;Muy bien,image.png,3"

      r = :erlang.apply(ProgressStore, :parse_csv_line, [linea])

      assert r.id == "10"
      assert r.proyecto_id == "PX"
      assert r.titulo == "Titulo"
      assert r.estado == "abierto"
      assert r.version == 3
    end

    test "sanitize elimina comas y saltos de línea" do
      input = "Hola, prueba\notro"
      result = :erlang.apply(ProgressStore, :sanitize, [input])
      assert result == "Hola; prueba otro"
    end

    test "parse_list convierte cadena a lista" do
      assert :erlang.apply(ProgressStore, :parse_list, ["a;b;c"]) == ["a", "b", "c"]
      assert :erlang.apply(ProgressStore, :parse_list, [""]) == []
    end

    test "parse_int retorna entero o nil" do
      assert :erlang.apply(ProgressStore, :parse_int, ["10"]) == 10
      assert :erlang.apply(ProgressStore, :parse_int, [""]) == nil
    end
  end
end

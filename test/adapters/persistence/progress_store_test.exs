defmodule ProyectoFinalPrg3.Adapters.Persistence.ProgressStoreTest do
  use ExUnit.Case, async: false

  alias ProyectoFinalPrg3.Adapters.Persistence.ProgressStore
  alias ProyectoFinalPrg3.Domain.Progress

  @data_dir Path.join([File.cwd!(), "data"])
  @csv_path Path.join(@data_dir, "progress.csv")

  setup do
    File.rm_rf!(@data_dir)
    File.mkdir_p!(@data_dir)

    File.write!(@csv_path, ProgressStore.@headers)

    :ok
  end

  # ============================================================
  # UTILIDAD DE CREACIÓN DE AVANCES
  # ============================================================

  defp avance(attrs \\ %{}) do
    %Progress{
      id: Map.get(attrs, :id, "A1"),
      proyecto_id: Map.get(attrs, :proyecto_id, "P1"),
      equipo_id: Map.get(attrs, :equipo_id, nil),
      titulo: Map.get(attrs, :titulo, "Titulo Test"),
      descripcion: Map.get(attrs, :descripcion, "Descripcion Test"),
      fecha_registro: Map.get(attrs, :fecha_registro, DateTime.utc_now()),
      autor_id: Map.get(attrs, :autor_id, "U1"),
      estado: Map.get(attrs, :estado, "en_revision"),
      retroalimentacion: Map.get(attrs, :retroalimentacion, "Ninguna"),
      adjuntos: Map.get(attrs, :adjuntos, ["archivo1.png"]),
      version: Map.get(attrs, :version, "v1")
    }
  end

  # ============================================================
  # TEST CRUD
  # ============================================================

  describe "guardar_avance/1" do
    test "guarda un nuevo avance correctamente" do
      a = avance(titulo: "Diseño de UI", descripcion: "Primer mockup")

      {:ok, _} = ProgressStore.guardar_avance(a)

      contenido = File.read!(@csv_path)
      assert contenido =~ "Diseño de UI"
      assert contenido =~ "Primer mockup"
    end

    test "reemplaza un avance existente" do
      a1 = avance(id: "A10", titulo: "Borrador", descripcion: "v1")
      a2 = avance(id: "A10", titulo: "Final", descripcion: "v2")

      ProgressStore.guardar_avance(a1)
      ProgressStore.guardar_avance(a2)

      contenido = File.read!(@csv_path)

      refute contenido =~ "Borrador"
      assert contenido =~ "Final"
    end
  end

  describe "listar_avances/0" do
    test "retorna lista vacía si no existe archivo" do
      File.rm_rf!(@data_dir)
      assert ProgressStore.listar_avances() == []
    end

    test "retorna todos los avances registrados" do
      a1 = avance(id: "A3", titulo: "Analisis")
      a2 = avance(id: "A4", titulo: "Diseño")

      ProgressStore.guardar_avance(a1)
      ProgressStore.guardar_avance(a2)

      lista = ProgressStore.listar_avances()
      assert length(lista) == 2
      assert Enum.any?(lista, &(&1.titulo == "Analisis"))
    end
  end

  describe "obtener_avance/1" do
    test "retorna un avance existente" do
      a = avance(id: "AX1", titulo: "Backend API")
      ProgressStore.guardar_avance(a)

      {:ok, encontrado} = ProgressStore.obtener_avance("AX1")
      assert encontrado.titulo == "Backend API"
    end

    test "retorna error cuando no existe" do
      assert ProgressStore.obtener_avance("XYZ") == {:error, :no_encontrado}
    end
  end

  describe "listar_por_proyecto/1" do
    test "filtra correctamente por proyecto" do
      a1 = avance(id: "A6", proyecto_id: "PROJ1")
      a2 = avance(id: "A7", proyecto_id: "PROJ2")

      ProgressStore.guardar_avance(a1)
      ProgressStore.guardar_avance(a2)

      lista = ProgressStore.listar_por_proyecto("PROJ1")

      assert length(lista) == 1
      assert Enum.all?(lista, &(&1.proyecto_id == "PROJ1"))
    end
  end

  describe "eliminar_avance/1" do
    test "elimina correctamente un avance" do
      a = avance(id: "DEL1")
      ProgressStore.guardar_avance(a)

      :ok = ProgressStore.eliminar_avance("DEL1")

      lista = ProgressStore.listar_avances()
      refute Enum.any?(lista, &(&1.id == "DEL1"))
    end
  end

  # ============================================================
  # TEST DE SERIALIZACIÓN / PARSEO
  # ============================================================

  describe "serializar_avance/parsear_linea" do
    test "serializar_avance genera una línea CSV válida" do
      a = avance(titulo: "Título X", adjuntos: ["a.png", "b.png"])
      csv = :erlang.apply(ProgressStore, :serializar_avance, [a])

      assert csv =~ "Título X"
      assert csv =~ "a.png|b.png"
    end

    test "parsear_linea reconstruye correctamente un struct Progress" do
      fecha = DateTime.utc_now() |> DateTime.to_iso8601()
      linea =
        "1,PROJ1,EQ1,Titulo,Descripcion,#{fecha},AUTORX,en_revision,Retro,adj1|adj2,v1"

      p = :erlang.apply(ProgressStore, :parsear_linea, [linea])

      assert p.id == "1"
      assert p.proyecto_id == "PROJ1"
      assert p.equipo_id == "EQ1"
      assert p.estado == "en_revision"
      assert p.adjuntos == ["adj1", "adj2"]
      assert p.version == "v1"
    end
  end

  describe "funciones auxiliares" do
    test "limpiar elimina comas y saltos de línea" do
      result = :erlang.apply(ProgressStore, :limpiar, ["Texto, con\nsaltos"])
      assert result == "Texto; con saltos"
    end

    test "parse_datetime interpreta DateTime ISO8601" do
      fecha = DateTime.utc_now() |> DateTime.to_iso8601()
      dt = :erlang.apply(ProgressStore, :parse_datetime, [fecha])
      assert %DateTime{} = dt
    end

    test "serialize_list concatena lista con |" do
      lista = ["a", "b", "c"]
      res = :erlang.apply(ProgressStore, :serialize_list, [lista])
      assert res == "a|b|c"
    end

    test "parse_list separa correctamente por |" do
      res = :erlang.apply(ProgressStore, :parse_list, ["x|y|z"])
      assert res == ["x", "y", "z"]
    end
  end
end

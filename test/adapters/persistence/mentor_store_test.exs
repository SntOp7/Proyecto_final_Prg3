defmodule ProyectoFinalPrg3.Adapters.Persistence.MentorStoreTest do
  use ExUnit.Case, async: false

  alias ProyectoFinalPrg3.Adapters.Persistence.MentorStore
  alias ProyectoFinalPrg3.Domain.Mentor

  @data_dir Path.join([File.cwd!(), "data"])
  @csv_file Path.join(@data_dir, "mentores.csv")

  # ───────────────────────────────────────────────────────────────
  # ENTORNO DE PRUEBAS AISLADO
  # ───────────────────────────────────────────────────────────────

  setup do
    # El store REAL escribe siempre en data/mentores.csv
    File.rm_rf!(@data_dir)
    File.mkdir_p!(@data_dir)

    # Crear encabezado obligatorio
    File.write!(@csv_file, MentorStore.@headers)

    :ok
  end

  # ───────────────────────────────────────────────────────────────
  # UTILIDAD PARA CREAR ESTRUCTURAS
  # ───────────────────────────────────────────────────────────────

  defp mentor(attrs \\ %{}) do
    %Mentor{
      id: Map.get(attrs, :id, "M1"),
      nombre: Map.get(attrs, :nombre, "Nombre Mentor"),
      correo: Map.get(attrs, :correo, "mentor@test.com"),
      especialidad: Map.get(attrs, :especialidad, "IA"),
      biografia: Map.get(attrs, :biografia, "Bio example"),
      equipos_asignados: Map.get(attrs, :equipos_asignados, ["Team1"]),
      disponibilidad: Map.get(attrs, :disponibilidad, :activo),
      canal_mentoria_id: Map.get(attrs, :canal_mentoria_id, "CH001"),
      fecha_registro: Map.get(attrs, :fecha_registro, DateTime.utc_now()),
      retroalimentaciones: Map.get(attrs, :retroalimentaciones, ["FB1"]),
      rol: Map.get(attrs, :rol, "mentor"),
      activo: Map.get(attrs, :activo, true)
    }
  end

  # ───────────────────────────────────────────────────────────────
  # PRUEBAS CRUD
  # ───────────────────────────────────────────────────────────────

  describe "guardar_mentor/1" do
    test "guarda un nuevo mentor correctamente" do
      m = mentor(nombre: "Carlos Ruiz")

      {:ok, resultado} = MentorStore.guardar_mentor(m)
      assert resultado.nombre == "Carlos Ruiz"

      contenido = File.read!(@csv_file)
      assert contenido =~ "Carlos Ruiz"
      assert contenido =~ "activo"
    end

    test "actualiza un mentor existente sin duplicarlo" do
      m1 = mentor(id: "X1", biografia: "Bio A")
      m2 = mentor(id: "X1", biografia: "Bio B")

      MentorStore.guardar_mentor(m1)
      MentorStore.guardar_mentor(m2)

      contenido = File.read!(@csv_file)

      assert contenido =~ "Bio B"
      refute contenido =~ "Bio A"
    end
  end

  describe "obtener_por_id/1" do
    test "retorna mentor si existe" do
      m = mentor(id: "M10", nombre: "Laura Gómez")
      MentorStore.guardar_mentor(m)

      encontrado = MentorStore.obtener_por_id("M10")

      assert encontrado.nombre == "Laura Gómez"
      assert encontrado.id == "M10"
    end

    test "retorna nil si no existe" do
      assert MentorStore.obtener_por_id("NOPE") == nil
    end
  end

  # ───────────────────────────────────────────────────────────────
  # BÚSQUEDAS POR CAMPOS
  # ───────────────────────────────────────────────────────────────

  describe "obtener_por_nombre/1 y buscar_por_correo/1" do
    setup do
      m =
        mentor(
          id: "M20",
          nombre: "Pedro Torres",
          correo: "pedro@hackathon.com",
          especialidad: "Frontend"
        )

      MentorStore.guardar_mentor(m)

      {:ok, mentor: m}
    end

    test "buscar_por_correo encuentra el mentor correcto", %{mentor: m} do
      encontrado = MentorStore.buscar_por_correo("pedro@hackathon.com")
      assert encontrado.id == m.id
    end

    test "obtener_por_nombre encuentra el mentor correcto", %{mentor: m} do
      encontrado = MentorStore.obtener_por_nombre("Pedro Torres")
      assert encontrado.correo == m.correo
    end
  end

  # ───────────────────────────────────────────────────────────────
  # LISTADO GENERAL
  # ───────────────────────────────────────────────────────────────

  describe "listar_mentores/0" do
    test "retorna lista vacía si el archivo está vacío" do
      File.write!(@csv_file, MentorStore.@headers)
      assert MentorStore.listar_mentores() == []
    end

    test "lista correctamente los mentores guardados" do
      m1 = mentor(id: "A")
      m2 = mentor(id: "B")

      MentorStore.guardar_mentor(m1)
      MentorStore.guardar_mentor(m2)

      lista = MentorStore.listar_mentores()
      assert length(lista) == 2
    end
  end

  # ───────────────────────────────────────────────────────────────
  # ELIMINACIÓN
  # ───────────────────────────────────────────────────────────────

  describe "eliminar_mentor/1" do
    test "elimina un mentor existente" do
      m = mentor(id: "DEL", nombre: "Eliminar")
      MentorStore.guardar_mentor(m)

      assert :ok = MentorStore.eliminar_mentor("DEL")

      lista = MentorStore.listar_mentores()
      refute Enum.any?(lista, fn x -> x.id == "DEL" end)
    end
  end

  # ───────────────────────────────────────────────────────────────
  # VALIDACIÓN DE SERIALIZACIÓN Y PARSEO
  # ───────────────────────────────────────────────────────────────

  describe "funciones internas de parseo" do
    test "parse_csv_line convierte correctamente el CSV a struct Mentor" do
      linea =
        "1,Camila,camila@x.com,UX,Bio text,TeamX;TeamY,activo,CH01,2025-10-27T00:00:00Z,FB1;FB2,mentor,true"

      resultado = :erlang.apply(MentorStore, :parse_csv_line, [linea])

      assert resultado.id == "1"
      assert resultado.nombre == "Camila"
      assert resultado.correo == "camila@x.com"
      assert resultado.disponibilidad == :activo
      assert resultado.activo == true
      assert resultado.retroalimentaciones == ["FB1", "FB2"]
    end

    test "sanitize reemplaza comas y saltos de línea" do
      input = "Hola, mundo\notro"
      result = :erlang.apply(MentorStore, :sanitize, [input])
      assert result == "Hola; mundo otro"
    end

    test "parse_nil convierte cadena vacía en nil" do
      assert :erlang.apply(MentorStore, :parse_nil, [""]) == nil
      assert :erlang.apply(MentorStore, :parse_nil, ["valor"]) == "valor"
    end

    test "parse_bool convierte correctamente" do
      assert :erlang.apply(MentorStore, :parse_bool, ["true"]) == true
      assert :erlang.apply(MentorStore, :parse_bool, ["false"]) == false
      assert :erlang.apply(MentorStore, :parse_bool, ["algo"]) == false
    end

    test "parse_list convierte cadenas separadas por ;" do
      assert :erlang.apply(MentorStore, :parse_list, ["A;B;C"]) == ["A", "B", "C"]
      assert :erlang.apply(MentorStore, :parse_list, [""]) == []
    end

    test "parse_atom convierte cadena en átomo y vacía en default" do
      assert :erlang.apply(MentorStore, :parse_atom, ["activo", :desconectado]) == :activo
      assert :erlang.apply(MentorStore, :parse_atom, ["", :desconectado]) == :desconectado
    end

    test "parse_datetime convierte ISO8601 y devuelve nil si es inválida" do
      assert :erlang.apply(MentorStore, :parse_datetime, [""]) == nil
      assert :erlang.apply(MentorStore, :parse_datetime, ["invalido"]) == nil

      dt = DateTime.utc_now() |> DateTime.to_iso8601()
      assert %DateTime{} = :erlang.apply(MentorStore, :parse_datetime, [dt])
    end
  end
end

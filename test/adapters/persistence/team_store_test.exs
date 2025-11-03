defmodule ProyectoFinalPrg3.Adapters.Persistence.TeamStoreTest do
  use ExUnit.Case, async: true
  alias ProyectoFinalPrg3.Adapters.Persistence.TeamStore
  alias ProyectoFinalPrg3.Domain.Team

  @ruta "data/equipos.csv"

  setup do
    File.rm_rf!("data")
    File.mkdir_p!("data")
    :ok
  end

  describe "guardar_equipo/1" do
    test "guarda correctamente un nuevo equipo" do
      equipo = %Team{
        id: "T1",
        nombre: "Innovadores",
        descripcion: "Equipo de IA aplicada",
        categoria: "Tecnología",
        id_proyecto: "P1",
        id_mentor: "M1",
        participantes: ["U1", "U2"],
        fecha_creacion: DateTime.utc_now(),
        estado: :activo,
        canal_chat_id: "C1",
        puntaje: 95,
        historial: [%{detalle: "Inicio de proyecto", timestamp: nil}]
      }

      assert {:ok, _} = TeamStore.guardar_equipo(equipo)
      contenido = File.read!(@ruta)
      assert String.contains?(contenido, "Innovadores")
      assert String.contains?(contenido, "Equipo de IA aplicada")
    end

    test "reemplaza correctamente un equipo existente con el mismo ID" do
      e1 = %Team{id: "T2", nombre: "Alpha", descripcion: "Versión 1", categoria: "Test", estado: :activo}
      e2 = %Team{id: "T2", nombre: "Alpha", descripcion: "Versión 2", categoria: "Test", estado: :activo}

      TeamStore.guardar_equipo(e1)
      TeamStore.guardar_equipo(e2)

      contenido = File.read!(@ruta)
      refute String.contains?(contenido, "Versión 1")
      assert String.contains?(contenido, "Versión 2")
    end
  end

  describe "obtener_equipo/1" do
    setup do
      equipo = %Team{
        id: "T3",
        nombre: "CodeWarriors",
        descripcion: "Equipo backend",
        categoria: "Software",
        id_proyecto: "P3",
        id_mentor: "M2",
        participantes: ["P1", "P2"],
        fecha_creacion: DateTime.utc_now(),
        estado: :activo,
        canal_chat_id: "C3",
        puntaje: 85,
        historial: [%{detalle: "Primera reunión", timestamp: nil}]
      }

      TeamStore.guardar_equipo(equipo)
      %{equipo: equipo}
    end

    test "retorna el equipo por nombre", %{equipo: e} do
      encontrado = TeamStore.obtener_equipo("CodeWarriors")
      assert encontrado.id == e.id
      assert encontrado.nombre == "CodeWarriors"
    end

    test "retorna nil si el equipo no existe" do
      assert TeamStore.obtener_equipo("Inexistente") == nil
    end
  end

  describe "listar_equipos/0" do
    test "retorna lista vacía si el archivo no existe" do
      File.rm_rf!("data")
      assert TeamStore.listar_equipos() == []
    end

    test "retorna lista con equipos cargados del CSV" do
      equipo = %Team{id: "TX", nombre: "DevHackers", descripcion: "Fullstack", categoria: "Software", estado: :activo}
      TeamStore.guardar_equipo(equipo)
      equipos = TeamStore.listar_equipos()
      assert Enum.any?(equipos, &(&1.nombre == "DevHackers"))
    end
  end

  describe "eliminar_equipo/1" do
    test "elimina el equipo por nombre correctamente" do
      e = %Team{id: "DEL", nombre: "Eliminar", descripcion: "Prueba", categoria: "QA", estado: :activo}
      TeamStore.guardar_equipo(e)
      :ok = TeamStore.eliminar_equipo("Eliminar")

      lista = TeamStore.listar_equipos()
      refute Enum.any?(lista, fn eq -> eq.nombre == "Eliminar" end)
    end
  end

  describe "funciones privadas de serialización" do
    test "parse_csv_line convierte una línea CSV a Team correctamente" do
      fecha = DateTime.utc_now() |> DateTime.to_iso8601()
      linea = "T4,Test,Desc,Cat,P1,M1,U1;U2,#{fecha},activo,C1,100,Evento1|Evento2"

      equipo = :erlang.apply(TeamStore, :parse_csv_line, [linea])
      assert equipo.id == "T4"
      assert equipo.nombre == "Test"
      assert equipo.estado == :activo
      assert Enum.member?(equipo.participantes, "U1")
      assert Enum.count(equipo.historial) == 2
    end

    test "to_csv_line convierte un Team en línea CSV correctamente" do
      eq = %Team{
        id: "T5",
        nombre: "CSVTeam",
        descripcion: "CSV test",
        categoria: "Data",
        id_proyecto: "P9",
        id_mentor: "M9",
        participantes: ["X1", "X2"],
        fecha_creacion: DateTime.utc_now(),
        estado: :activo,
        canal_chat_id: "C9",
        puntaje: 50,
        historial: [%{detalle: "Inicio", timestamp: nil}]
      }

      csv = :erlang.apply(TeamStore, :to_csv_line, [eq])
      assert String.contains?(csv, "CSVTeam")
      assert String.contains?(csv, "activo")
    end

    test "sanitize reemplaza caracteres problemáticos" do
      assert :erlang.apply(TeamStore, :sanitize, ["Hola, mundo"]) == "Hola; mundo"
    end

    test "parse_estado convierte correctamente los estados" do
      assert :erlang.apply(TeamStore, :parse_estado, ["activo"]) == :activo
      assert :erlang.apply(TeamStore, :parse_estado, ["inactivo"]) == :inactivo
      assert :erlang.apply(TeamStore, :parse_estado, ["otro"]) == :activo
    end

    test "serialize_historial y parse_historial son complementarios" do
      hist = [%{detalle: "Test1"}, %{detalle: "Test2"}]
      serializado = :erlang.apply(TeamStore, :serialize_historial, [hist])
      parseado = :erlang.apply(TeamStore, :parse_historial, [serializado])

      assert length(parseado) == 2
      assert Enum.all?(parseado, fn h -> is_map(h) end)
    end
  end
end

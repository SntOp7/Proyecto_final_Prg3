defmodule ProyectoFinalPrg3.Adapters.Persistence.ProjectStoreTest do
  use ExUnit.Case, async: false

  alias ProyectoFinalPrg3.Adapters.Persistence.ProjectStore
  alias ProyectoFinalPrg3.Domain.Project

  @ruta Path.join(["data", "proyectos.csv"])

  setup do
    File.rm_rf!("data")
    File.mkdir_p!("data")
    :ok
  end

  # ============================================================
  # GUARDAR PROYECTO
  # ============================================================

  describe "guardar_proyecto/1" do
    test "guarda correctamente un nuevo proyecto" do
      proyecto = %Project{
        id: "P1",
        nombre: "SmartCity",
        descripcion: "Gestión inteligente de ciudades",
        categoria: "Tecnología",
        estado: :en_desarrollo,
        fecha_creacion: DateTime.utc_now() |> DateTime.to_iso8601(),
        fecha_actualizacion: DateTime.utc_now() |> DateTime.to_iso8601(),
        equipo_id: "E1",
        mentor_id: "M1",
        avances: ["A1"],
        retroalimentaciones: ["F1"],
        repositorio_url: "https://github.com/smartcity",
        puntaje: 95,
        visibilidad: :publico,
        tags: ["iot", "ciudades"]
      }

      assert :ok = ProjectStore.guardar_proyecto(proyecto)
      contenido = File.read!(@ruta)

      assert contenido =~ "SmartCity"
      assert contenido =~ "Tecnología"
    end

    test "reemplaza un proyecto existente con mismo id o nombre" do
      p1 = %Project{
        id: "P2",
        nombre: "HealthAI",
        descripcion: "v1",
        categoria: "Salud",
        estado: :en_revision,
        fecha_creacion: "",
        fecha_actualizacion: "",
        equipo_id: nil,
        mentor_id: nil,
        avances: [],
        retroalimentaciones: [],
        repositorio_url: nil,
        puntaje: 0,
        visibilidad: :privado,
        tags: []
      }

      p2 = %Project{
        id: "P2",
        nombre: "HealthAI",
        descripcion: "v2",
        categoria: "Salud",
        estado: :completado,
        fecha_creacion: "",
        fecha_actualizacion: "",
        equipo_id: nil,
        mentor_id: nil,
        avances: [],
        retroalimentaciones: [],
        repositorio_url: nil,
        puntaje: 0,
        visibilidad: :privado,
        tags: []
      }

      ProjectStore.guardar_proyecto(p1)
      ProjectStore.guardar_proyecto(p2)

      contenido = File.read!(@ruta)
      refute contenido =~ "v1"
      assert contenido =~ "v2"
    end
  end

  # ============================================================
  # OBTENER PROYECTOS
  # ============================================================

  describe "obtener_proyecto/1 y obtener_por_id/1" do
    setup do
      proyecto = %Project{
        id: "P3",
        nombre: "GreenTech",
        descripcion: "Energía sostenible",
        categoria: "Medioambiente",
        estado: :activo,
        fecha_creacion: DateTime.utc_now() |> DateTime.to_iso8601(),
        fecha_actualizacion: DateTime.utc_now() |> DateTime.to_iso8601(),
        equipo_id: "E2",
        mentor_id: "M2",
        avances: [],
        retroalimentaciones: [],
        repositorio_url: nil,
        puntaje: 80,
        visibilidad: :privado,
        tags: ["eco"]
      }

      ProjectStore.guardar_proyecto(proyecto)
      %{proyecto: proyecto}
    end

    test "retorna el proyecto por nombre", %{proyecto: p} do
      encontrado = ProjectStore.obtener_proyecto("GreenTech")

      assert encontrado.id == p.id
      assert encontrado.nombre == "GreenTech"
    end

    test "retorna el proyecto por id", %{proyecto: p} do
      encontrado = ProjectStore.obtener_por_id("P3")
      assert encontrado.nombre == "GreenTech"
    end

    test "retorna nil si no existe" do
      assert ProjectStore.obtener_por_id("NO_EXISTE") == nil
    end
  end

  # ============================================================
  # LISTAR PROYECTOS
  # ============================================================

  describe "listar_proyectos/0" do
    test "retorna lista vacía si no existe archivo" do
      File.rm_rf!("data")
      assert ProjectStore.listar_proyectos() == []
    end

    test "retorna lista con proyectos cargados del CSV" do
      proyecto = %Project{
        id: "PX",
        nombre: "AIHub",
        descripcion: "Centro IA",
        categoria: "Tecnología",
        estado: :activo,
        fecha_creacion: "",
        fecha_actualizacion: "",
        equipo_id: nil,
        mentor_id: nil,
        avances: [],
        retroalimentaciones: [],
        repositorio_url: nil,
        puntaje: 0,
        visibilidad: :publico,
        tags: []
      }

      ProjectStore.guardar_proyecto(proyecto)

      lista = ProjectStore.listar_proyectos()
      assert Enum.any?(lista, &(&1.nombre == "AIHub"))
    end
  end

  # ============================================================
  # ELIMINAR PROYECTOS
  # ============================================================

  describe "eliminar_proyecto/1" do
    test "elimina el proyecto correctamente" do
      p = %Project{
        id: "DEL1",
        nombre: "Borrar",
        descripcion: "Eliminar",
        categoria: "Test",
        estado: :activo,
        fecha_creacion: "",
        fecha_actualizacion: "",
        equipo_id: nil,
        mentor_id: nil,
        avances: [],
        retroalimentaciones: [],
        repositorio_url: nil,
        puntaje: 0,
        visibilidad: :publico,
        tags: []
      }

      ProjectStore.guardar_proyecto(p)

      :ok = ProjectStore.eliminar_proyecto("Borrar")

      lista = ProjectStore.listar_proyectos()
      refute Enum.any?(lista, fn pr -> pr.nombre == "Borrar" end)
    end
  end

  # ============================================================
  # FUNCIONES PRIVADAS
  # ============================================================

  describe "funciones privadas" do
    test "mapear_a_struct convierte datos CSV en struct Project" do
      fecha = DateTime.utc_now() |> DateTime.to_iso8601()

      row = %{
        "id" => "1",
        "nombre" => "Prueba",
        "descripcion" => "Desc",
        "categoria" => "Tech",
        "estado" => "activo",
        "fecha_creacion" => fecha,
        "fecha_actualizacion" => fecha,
        "equipo_id" => "E1",
        "mentor_id" => "M1",
        "avances" => "A1|A2",
        "retroalimentaciones" => "F1|F2",
        "repositorio_url" => "url",
        "puntaje" => "88",
        "visibilidad" => "publico",
        "tags" => "tag1|tag2"
      }

      p = :erlang.apply(ProjectStore, :mapear_a_struct, [row])

      assert p.nombre == "Prueba"
      assert p.estado == :activo
      assert p.visibilidad == :publico
      assert p.avances == ["A1", "A2"]
      assert p.puntaje == 88
      assert p.tags == ["tag1", "tag2"]
    end

    test "escape_csv produce un string seguro" do
      result = :erlang.apply(ProjectStore, :escape_csv, ["Hola, \"Mundo\""])
      assert result |> String.starts_with?("\"")
      assert result |> String.ends_with?("\"")
    end

    test "parse_list, parse_integer, parse_atom, parse_datetime funcionan" do
      assert :erlang.apply(ProjectStore, :parse_list, ["a|b"]) == ["a", "b"]
      assert :erlang.apply(ProjectStore, :parse_integer, ["42"]) == 42
      assert :erlang.apply(ProjectStore, :parse_atom, ["activo"]) == :activo

      dt = DateTime.utc_now() |> DateTime.to_iso8601()
      assert %DateTime{} = :erlang.apply(ProjectStore, :parse_datetime, [dt])
    end

    test "nilify convierte string vacío a nil" do
      assert :erlang.apply(ProjectStore, :nilify, [""]) == nil
      assert :erlang.apply(ProjectStore, :nilify, ["valor"]) == "valor"
    end
  end
end

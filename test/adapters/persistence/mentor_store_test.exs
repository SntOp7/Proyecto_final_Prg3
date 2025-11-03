defmodule ProyectoFinalPrg3.Adapters.Persistence.MentorStoreTest do
  use ExUnit.Case, async: true
  alias ProyectoFinalPrg3.Adapters.Persistence.MentorStore
  alias ProyectoFinalPrg3.Domain.Mentor

  @temp_file Path.join(["tmp", "mentores_test.csv"])

  setup do
    File.rm_rf!("tmp")
    File.mkdir_p!("tmp")

    # Sobrescribimos la ruta de archivo para no alterar los datos reales
    put_in(Process.get(:mentor_store_path), @temp_file)

    :ok
  end

  describe "guardar_mentor/1" do
    test "guarda un nuevo mentor correctamente" do
      mentor = %Mentor{
        id: "1",
        nombre: "Carlos Ruiz",
        correo: "carlos@ejemplo.com",
        especialidad: "Backend",
        biografia: "Mentor con experiencia en Elixir",
        equipos_asignados: ["Team Alpha"],
        disponibilidad: :activo,
        canal_mentoria_id: "CH001",
        fecha_registro: DateTime.utc_now(),
        retroalimentaciones: ["Excelente desempeño"],
        rol: "mentor",
        activo: true
      }

      {:ok, resultado} = MentorStore.guardar_mentor(mentor)
      assert resultado.nombre == "Carlos Ruiz"

      contenido = File.read!(@temp_file)
      assert String.contains?(contenido, "Carlos Ruiz")
    end
  end

  describe "obtener_por_id/1" do
    test "devuelve el mentor correspondiente al id" do
      mentor = %Mentor{
        id: "M01",
        nombre: "Laura Gómez",
        correo: "laura@ejemplo.com",
        especialidad: "IA",
        biografia: "Mentora en Inteligencia Artificial",
        equipos_asignados: ["E1"],
        disponibilidad: :activo,
        canal_mentoria_id: "C01",
        fecha_registro: DateTime.utc_now(),
        retroalimentaciones: [],
        rol: "mentor",
        activo: true
      }

      MentorStore.guardar_mentor(mentor)
      encontrado = MentorStore.obtener_por_id("M01")

      assert encontrado.nombre == "Laura Gómez"
    end

    test "retorna nil si el mentor no existe" do
      assert MentorStore.obtener_por_id("999") == nil
    end
  end

  describe "buscar_por_correo/1 y obtener_por_nombre/1" do
    setup do
      mentor = %Mentor{
        id: "M02",
        nombre: "Pedro Torres",
        correo: "pedro@hackathon.com",
        especialidad: "Frontend",
        biografia: "Experto en interfaces reactivas",
        equipos_asignados: [],
        disponibilidad: :activo,
        canal_mentoria_id: "CHAT_12",
        fecha_registro: DateTime.utc_now(),
        retroalimentaciones: [],
        rol: "mentor",
        activo: true
      }

      MentorStore.guardar_mentor(mentor)
      {:ok, mentor: mentor}
    end

    test "encuentra mentor por correo", %{mentor: mentor} do
      encontrado = MentorStore.buscar_por_correo("pedro@hackathon.com")
      assert encontrado.id == mentor.id
    end

    test "encuentra mentor por nombre", %{mentor: mentor} do
      encontrado = MentorStore.obtener_por_nombre("Pedro Torres")
      assert encontrado.correo == mentor.correo
    end
  end

  describe "listar_mentores/0" do
    test "devuelve lista vacía si no hay archivo" do
      File.rm(@temp_file)
      assert MentorStore.listar_mentores() == []
    end

    test "lista todos los mentores correctamente" do
      mentor1 = %Mentor{id: "A", nombre: "A", correo: "a@x.com", especialidad: "IA", biografia: "", equipos_asignados: [], disponibilidad: :activo, canal_mentoria_id: nil, fecha_registro: DateTime.utc_now(), retroalimentaciones: [], rol: "mentor", activo: true}
      mentor2 = %Mentor{id: "B", nombre: "B", correo: "b@x.com", especialidad: "Backend", biografia: "", equipos_asignados: [], disponibilidad: :inactivo, canal_mentoria_id: nil, fecha_registro: DateTime.utc_now(), retroalimentaciones: [], rol: "mentor", activo: false}

      MentorStore.guardar_mentor(mentor1)
      MentorStore.guardar_mentor(mentor2)

      lista = MentorStore.listar_mentores()
      assert length(lista) >= 2
    end
  end

  describe "eliminar_mentor/1" do
    test "elimina un mentor existente correctamente" do
      mentor = %Mentor{id: "DEL", nombre: "Eliminar", correo: "x@x.com", especialidad: "", biografia: "", equipos_asignados: [], disponibilidad: :activo, canal_mentoria_id: nil, fecha_registro: DateTime.utc_now(), retroalimentaciones: [], rol: "mentor", activo: true}

      MentorStore.guardar_mentor(mentor)
      assert :ok = MentorStore.eliminar_mentor("DEL")

      lista = MentorStore.listar_mentores()
      refute Enum.any?(lista, fn m -> m.id == "DEL" end)
    end
  end

  describe "funciones privadas" do
    test "parse_csv_line convierte correctamente una línea a struct" do
      linea = "1,Camila,camila@x.com,UX,Bio text,TeamX;TeamY,activo,CH01,2025-10-27T00:00:00Z,FB1;FB2,mentor,true"
      resultado = :erlang.apply(MentorStore, :parse_csv_line, [linea])
      assert resultado.nombre == "Camila"
      assert resultado.disponibilidad == :activo
      assert resultado.activo == true
    end
  end
end

defmodule ProyectoFinalPrg3.Adapters.Persistence.ParticipantStoreTest do
  use ExUnit.Case, async: true
  alias ProyectoFinalPrg3.Adapters.Persistence.ParticipantStore
  alias ProyectoFinalPrg3.Domain.Participant

  @temp_file Path.join(["tmp", "participantes_test.csv"])

  setup do
    File.rm_rf!("tmp")
    File.mkdir_p!("tmp")
    put_in(Process.get(:participant_store_path), @temp_file)
    :ok
  end

  describe "guardar_participante/1" do
    test "guarda un nuevo participante correctamente" do
      participante = %Participant{
        id: "P1",
        nombre: "Ana Gómez",
        correo: "ana@correo.com",
        username: "anag",
        rol: "participante",
        equipo_id: "E01",
        experiencia: "Desarrollo en Elixir",
        fecha_registro: DateTime.utc_now(),
        estado: :activo,
        ultima_conexion: DateTime.utc_now(),
        mensajes: [%{mensaje: "Hola!", timestamp: DateTime.utc_now()}],
        canales_asignados: ["general", "equipo1"],
        token_sesion: "123token",
        perfil_url: "https://foto.com/ana.png"
      }

      {:ok, res} = ParticipantStore.guardar_participante(participante)
      assert res.nombre == "Ana Gómez"

      contenido = File.read!(@temp_file)
      assert String.contains?(contenido, "Ana Gómez")
      assert String.contains?(contenido, "correo.com")
    end
  end

  describe "obtener_participante/1" do
    test "devuelve el participante correspondiente al id" do
      participante = %Participant{
        id: "P02",
        nombre: "Carlos Ruiz",
        correo: "carlos@hackathon.com",
        username: "carlosr",
        rol: "participante",
        equipo_id: nil,
        experiencia: "Frontend",
        fecha_registro: DateTime.utc_now(),
        estado: :activo,
        ultima_conexion: nil,
        mensajes: [],
        canales_asignados: [],
        token_sesion: nil,
        perfil_url: nil
      }

      ParticipantStore.guardar_participante(participante)
      encontrado = ParticipantStore.obtener_participante("P02")
      assert encontrado.nombre == "Carlos Ruiz"
    end

    test "retorna nil si el participante no existe" do
      assert ParticipantStore.obtener_participante("999") == nil
    end
  end

  describe "buscar_por_correo/1" do
    test "encuentra participante por correo" do
      participante = %Participant{
        id: "P03",
        nombre: "Laura Martínez",
        correo: "laura@test.com",
        username: "lauram",
        rol: "participante",
        equipo_id: nil,
        experiencia: "",
        fecha_registro: DateTime.utc_now(),
        estado: :activo,
        ultima_conexion: nil,
        mensajes: [],
        canales_asignados: [],
        token_sesion: nil,
        perfil_url: nil
      }

      ParticipantStore.guardar_participante(participante)
      encontrado = ParticipantStore.buscar_por_correo("laura@test.com")
      assert encontrado.id == "P03"
    end
  end

  describe "listar_participantes/0" do
    test "retorna lista vacía si no existe archivo" do
      File.rm_rf!("tmp")
      assert ParticipantStore.listar_participantes() == []
    end

    test "lista todos los participantes correctamente" do
      p1 = %Participant{id: "A", nombre: "A", correo: "a@test.com", username: "a", rol: "participante", equipo_id: nil, experiencia: "", fecha_registro: DateTime.utc_now(), estado: :activo, ultima_conexion: nil, mensajes: [], canales_asignados: [], token_sesion: nil, perfil_url: nil}
      p2 = %Participant{id: "B", nombre: "B", correo: "b@test.com", username: "b", rol: "mentor", equipo_id: "E1", experiencia: "", fecha_registro: DateTime.utc_now(), estado: :pendiente, ultima_conexion: nil, mensajes: [], canales_asignados: [], token_sesion: nil, perfil_url: nil}

      ParticipantStore.guardar_participante(p1)
      ParticipantStore.guardar_participante(p2)

      lista = ParticipantStore.listar_participantes()
      assert length(lista) >= 2
    end
  end

  describe "eliminar_participante/1" do
    test "elimina un participante existente correctamente" do
      participante = %Participant{id: "DEL", nombre: "Eliminar", correo: "x@x.com", username: "x", rol: "participante", equipo_id: nil, experiencia: "", fecha_registro: DateTime.utc_now(), estado: :activo, ultima_conexion: nil, mensajes: [], canales_asignados: [], token_sesion: nil, perfil_url: nil}
      ParticipantStore.guardar_participante(participante)

      assert :ok = ParticipantStore.eliminar_participante("DEL")

      lista = ParticipantStore.listar_participantes()
      refute Enum.any?(lista, fn p -> p.id == "DEL" end)
    end
  end

  describe "funciones privadas" do
    test "parse_csv_line convierte una línea CSV en un struct válido" do
      fecha = "2025-10-27T00:00:00Z"
      linea = "1,Pedro,pedro@x.com,pedrox,participante,,Backend,#{fecha},activo,#{fecha},msg~#{fecha}|msg2~#{fecha},canal1;canal2,token123,https://x.com/img.png"

      resultado = :erlang.apply(ParticipantStore, :parse_csv_line, [linea])

      assert resultado.nombre == "Pedro"
      assert resultado.estado == :activo
      assert length(resultado.mensajes) == 2
      assert resultado.canales_asignados == ["canal1", "canal2"]
    end

    test "serialize_json_list genera correctamente la cadena serializada" do
      mensajes = [%{mensaje: "Hola", timestamp: DateTime.utc_now()}]
      result = :erlang.apply(ParticipantStore, :serialize_json_list, [mensajes])
      assert String.contains?(result, "Hola~")
    end
  end
end

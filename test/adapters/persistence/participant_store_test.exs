defmodule ProyectoFinalPrg3.Adapters.Persistence.ParticipantStoreTest do
  use ExUnit.Case, async: false

  alias ProyectoFinalPrg3.Adapters.Persistence.ParticipantStore
  alias ProyectoFinalPrg3.Domain.Participant

  @data_dir Path.join([File.cwd!(), "data"])
  @csv_file Path.join(@data_dir, "participantes.csv")

  # ============================================================
  # ENTORNO AISLADO DE PRUEBAS
  # ============================================================

  setup do
    File.rm_rf!(@data_dir)
    File.mkdir_p!(@data_dir)

    # Crear archivo con encabezado
    File.write!(@csv_file, ParticipantStore.@headers)

    :ok
  end

  # ============================================================
  # UTILIDAD PARA CREAR PARTICIPANTES DE PRUEBA
  # ============================================================

  defp p(attrs \\ %{}) do
    %Participant{
      id: Map.get(attrs, :id, "P1"),
      nombre: Map.get(attrs, :nombre, "Nombre Test"),
      correo: Map.get(attrs, :correo, "correo@test.com"),
      username: Map.get(attrs, :username, "user_test"),
      rol: Map.get(attrs, :rol, "participante"),
      equipo_id: Map.get(attrs, :equipo_id, nil),
      experiencia: Map.get(attrs, :experiencia, "Algo"),
      fecha_registro: Map.get(attrs, :fecha_registro, DateTime.utc_now()),
      estado: Map.get(attrs, :estado, :activo),
      ultima_conexion: Map.get(attrs, :ultima_conexion, DateTime.utc_now()),
      mensajes: Map.get(attrs, :mensajes, [%{mensaje: "Hola!", timestamp: DateTime.utc_now()}]),
      canales_asignados: Map.get(attrs, :canales_asignados, ["general"]),
      token_sesion: Map.get(attrs, :token_sesion, "token123"),
      perfil_url: Map.get(attrs, :perfil_url, "https://x.com/img.png")
    }
  end

  # ============================================================
  # PRUEBAS CRUD
  # ============================================================

  describe "guardar_participante/1" do
    test "guarda correctamente un participante nuevo" do
      participante = p(nombre: "Ana Gómez", correo: "ana@correo.com")

      {:ok, res} = ParticipantStore.guardar_participante(participante)
      assert res.nombre == "Ana Gómez"

      contenido = File.read!(@csv_file)
      assert contenido =~ "Ana Gómez"
      assert contenido =~ "correo.com"
    end

    test "actualiza un participante existente sin duplicarlo" do
      p1 = p(id: "PX", experiencia: "Nivel 1")
      p2 = p(id: "PX", experiencia: "Nivel 2")

      ParticipantStore.guardar_participante(p1)
      ParticipantStore.guardar_participante(p2)

      contenido = File.read!(@csv_file)
      assert contenido =~ "Nivel 2"
      refute contenido =~ "Nivel 1"
    end
  end

  describe "obtener_participante/1" do
    test "retorna un participante existente" do
      participante = p(id: "P02", nombre: "Carlos Ruiz")
      ParticipantStore.guardar_participante(participante)

      encontrado = ParticipantStore.obtener_participante("P02")
      assert encontrado.nombre == "Carlos Ruiz"
    end

    test "retorna nil cuando no existe" do
      assert ParticipantStore.obtener_participante("NOPE") == nil
    end
  end

  describe "buscar_por_correo/1" do
    test "encuentra un participante por correo" do
      participante = p(id: "P03", correo: "laura@test.com")
      ParticipantStore.guardar_participante(participante)

      encontrado = ParticipantStore.buscar_por_correo("laura@test.com")
      assert encontrado.id == "P03"
    end
  end

  describe "listar_participantes/0" do
    test "retorna lista vacía cuando no hay participantes" do
      File.write!(@csv_file, ParticipantStore.@headers)
      assert ParticipantStore.listar_participantes() == []
    end

    test "lista correctamente todos los participantes" do
      p1 = p(id: "A")
      p2 = p(id: "B")

      ParticipantStore.guardar_participante(p1)
      ParticipantStore.guardar_participante(p2)

      lista = ParticipantStore.listar_participantes()
      assert length(lista) == 2
    end
  end

  describe "eliminar_participante/1" do
    test "elimina correctamente un participante" do
      participante = p(id: "DEL", nombre: "Eliminar")
      ParticipantStore.guardar_participante(participante)

      assert :ok = ParticipantStore.eliminar_participante("DEL")

      lista = ParticipantStore.listar_participantes()
      refute Enum.any?(lista, fn x -> x.id == "DEL" end)
    end

    test "retorna error si el participante no existe" do
      assert ParticipantStore.eliminar_participante("NOPE") == {:error, :no_encontrado}
    end
  end

  # ============================================================
  # PARSEO Y SERIALIZACIÓN
  # ============================================================

  describe "funciones internas: parseo y serialización" do
    test "parse_csv_line convierte línea CSV a struct Participant" do
      fecha = "2025-10-27T00:00:00Z"
      linea =
        "1,Pedro,pedro@x.com,pedrox,participante,,Backend,#{fecha},activo,#{fecha},msg~#{fecha}|msg2~#{fecha},canal1;canal2,token123,https://x.com/img.png"

      resultado = :erlang.apply(ParticipantStore, :parse_csv_line, [linea])

      assert resultado.nombre == "Pedro"
      assert resultado.estado == :activo
      assert length(resultado.mensajes) == 2
      assert resultado.canales_asignados == ["canal1", "canal2"]
      assert resultado.token_sesion == "token123"
    end

    test "serialize_json_list serializa correctamente mensajes" do
      mensajes = [%{mensaje: "Hola", timestamp: DateTime.utc_now()}]
      result = :erlang.apply(ParticipantStore, :serialize_json_list, [mensajes])

      assert String.contains?(result, "Hola~")
    end

    test "parse_json_list transforma cadenas a lista de mapas correctamente" do
      fecha = DateTime.utc_now() |> DateTime.to_iso8601()
      str = "Hola~#{fecha}|Adios~#{fecha}"

      result = :erlang.apply(ParticipantStore, :parse_json_list, [str])

      assert length(result) == 2
      assert Enum.all?(result, &is_map/1)
    end

    test "parse_estado interpreta correctamente los estados" do
      assert :erlang.apply(ParticipantStore, :parse_estado, ["activo"]) == :activo
      assert :erlang.apply(ParticipantStore, :parse_estado, ["pendiente"]) == :pendiente
      assert :erlang.apply(ParticipantStore, :parse_estado, ["desconectado"]) == :desconectado
      assert :erlang.apply(ParticipantStore, :parse_estado, ["otro"]) == :activo
    end

    test "sanitize elimina comas y saltos de línea" do
      input = "Hola, mundo\notro"
      result = :erlang.apply(ParticipantStore, :sanitize, [input])
      assert result == "Hola; mundo otro"
    end
  end
end

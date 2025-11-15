defmodule ProyectoFinalPrg3.Adapters.Persistence.ParticipantStoreTest do
  use ExUnit.Case, async: true

  alias ProyectoFinalPrg3.Adapters.Persistence.ParticipantStore
  alias ProyectoFinalPrg3.Domain.Participant

  @csv_file "data/participantes.csv"

  @encabezado """
  id,nombre,correo,username,rol,equipo_id,experiencia,fecha_registro,estado,ultima_conexion,mensajes,canales_asignados,token_sesion,perfil_url
  """

  setup do
    # Reiniciar carpeta data/
    File.rm_rf!("data")
    File.mkdir_p!("data")

    # Crear archivo con encabezado válido
    File.write!(@csv_file, @encabezado)

    :ok
  end

  # -------------------------------------------------------------
  #   TEST listar_participantes/0
  # -------------------------------------------------------------
  describe "listar_participantes/0" do
    test "retorna lista vacía cuando no hay participantes" do
      File.rm_rf!("data")
      File.mkdir_p!("data")
      File.write!(@csv_file, @encabezado)

      assert ParticipantStore.listar_participantes() == []
    end
  end

  # -------------------------------------------------------------
  #   TEST guardar_participante/1
  # -------------------------------------------------------------
  describe "guardar_participante/1" do
    test "guarda correctamente un participante" do
      participante = %Participant{
        id: "U1",
        nombre: "Carlos",
        correo: "carlos@mail.com",
        username: "carlitos",
        rol: "estudiante",
        equipo_id: nil,
        experiencia: "novato",
        fecha_registro: DateTime.utc_now(),
        estado: "activo",
        ultima_conexion: nil,
        mensajes: [],
        canales_asignados: [],
        token_sesion: nil,
        perfil_url: nil
      }

      assert {:ok, _} = ParticipantStore.guardar_participante(participante)

      contenido = File.read!(@csv_file)

      assert String.contains?(contenido, "Carlos")
      assert String.contains?(contenido, "carlitos")
      assert String.contains?(contenido, "carlos@mail.com")
    end
  end
end

defmodule ProyectoFinalPrg3.Test.Services.ParticipantManagerTest do
  use ExUnit.Case, async: true
  import Mox

  alias ProyectoFinalPrg3.Services.ParticipantManager
  alias ProyectoFinalPrg3.Domain.Participant

  @moduledoc """
  Pruebas unitarias completas para `ParticipantManager`.

  Se prueban todos los flujos relacionados con la gestión de participantes,
  asegurando la cobertura total de los campos definidos en el struct:

  - id
  - nombre
  - correo
  - username
  - rol
  - equipo_id
  - experiencia
  - fecha_registro
  - estado
  - ultima_conexion
  - mensajes
  - canales_asignados
  - token_sesion
  - perfil_url
  """

  setup :verify_on_exit!

  # ============================================================
  # REGISTRO DE PARTICIPANTE
  # ============================================================

  describe "registrar_participante/5" do
    test "crea un participante con todos los campos correctamente definidos" do
      expect(ParticipantStoreMock, :buscar_por_correo, fn _ -> nil end)
      expect(ParticipantStoreMock, :guardar_participante, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :participante_registrado, _ -> :ok end)

      {:ok, participante} =
        ParticipantManager.registrar_participante(
          "Sharif Giraldo",
          "sharif@example.com",
          "sharif_dev",
          "participante",
          "Full Stack Developer"
        )

      assert %Participant{} = participante
      assert participante.id != nil
      assert participante.nombre == "Sharif Giraldo"
      assert participante.correo == "sharif@example.com"
      assert participante.username == "sharif_dev"
      assert participante.rol == "participante"
      assert participante.equipo_id == nil
      assert participante.experiencia == "Full Stack Developer"
      assert participante.fecha_registro != nil
      assert participante.estado == :activo
      assert participante.ultima_conexion == nil
      assert participante.mensajes == []
      assert participante.canales_asignados == []
      assert participante.token_sesion == nil
      assert participante.perfil_url == nil
    end

    test "retorna error si el correo ya existe" do
      expect(ParticipantStoreMock, :buscar_por_correo, fn _ -> %{correo: "existe@example.com"} end)
      assert {:error, :correo_ya_registrado} =
               ParticipantManager.registrar_participante("Juan", "existe@example.com", "juan_dev")
    end
  end

  # ============================================================
  # CONSULTA Y VALIDACIÓN
  # ============================================================

  describe "obtener_participante/1" do
    test "retorna correctamente un participante existente" do
      participante = %Participant{id: "p1", nombre: "Laura", correo: "l@example.com"}
      expect(ParticipantStoreMock, :obtener_participante, fn "p1" -> participante end)

      {:ok, result} = ParticipantManager.obtener_participante("p1")
      assert result.nombre == "Laura"
      assert result.correo == "l@example.com"
    end

    test "retorna error si el participante no existe" do
      expect(ParticipantStoreMock, :obtener_participante, fn _ -> nil end)
      assert {:error, :no_encontrado} = ParticipantManager.obtener_participante("invalido")
    end
  end

  describe "buscar_por_correo/1" do
    test "encuentra un participante por correo" do
      participante = %Participant{id: "p2", correo: "x@example.com"}
      expect(ParticipantStoreMock, :buscar_por_correo, fn _ -> participante end)
      assert {:ok, result} = ParticipantManager.buscar_por_correo("x@example.com")
      assert result.id == "p2"
    end
  end

  # ============================================================
  # ACTUALIZACIÓN DE DATOS GENERALES
  # ============================================================

  describe "actualizar_datos/2" do
    test "actualiza varios campos y conserva los demás intactos" do
      participante = %Participant{
        id: "p3",
        nombre: "Santiago",
        correo: "santi@example.com",
        username: "santi_dev",
        rol: "participante",
        equipo_id: nil,
        experiencia: "Backend",
        fecha_registro: ~N[2025-10-25 12:00:00],
        estado: :activo,
        ultima_conexion: nil,
        mensajes: [],
        canales_asignados: [],
        token_sesion: nil,
        perfil_url: nil
      }

      expect(ParticipantStoreMock, :obtener_participante, fn "p3" -> participante end)
      expect(ParticipantStoreMock, :guardar_participante, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :participante_actualizado, _ -> :ok end)

      {:ok, actualizado} =
        ParticipantManager.actualizar_datos("p3", %{
          nombre: "Santiago Ospina",
          experiencia: "DevOps"
        })

      assert actualizado.nombre == "Santiago Ospina"
      assert actualizado.experiencia == "DevOps"
      assert actualizado.correo == "santi@example.com"
      assert actualizado.estado == :activo
      assert actualizado.fecha_registro == ~N[2025-10-25 12:00:00]
    end
  end

  describe "actualizar_perfil/2" do
    test "modifica correctamente la URL del perfil" do
      participante = %Participant{id: "p4", perfil_url: nil}
      expect(ParticipantStoreMock, :obtener_participante, fn "p4" -> participante end)
      expect(ParticipantStoreMock, :guardar_participante, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :participante_actualizado, _ -> :ok end)

      {:ok, actualizado} = ParticipantManager.actualizar_perfil("p4", "https://img/perfil.png")
      assert actualizado.perfil_url == "https://img/perfil.png"
    end
  end

  describe "asignar_token/2" do
    test "actualiza el token de sesión correctamente" do
      participante = %Participant{id: "p5", token_sesion: nil}
      expect(ParticipantStoreMock, :obtener_participante, fn "p5" -> participante end)
      expect(ParticipantStoreMock, :guardar_participante, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :participante_actualizado, _ -> :ok end)

      {:ok, actualizado} = ParticipantManager.asignar_token("p5", "token-xyz")
      assert actualizado.token_sesion == "token-xyz"
    end
  end

  # ============================================================
  # CANALES Y EQUIPOS
  # ============================================================

  describe "asignar_canal/2" do
    test "añade un nuevo canal sin duplicar" do
      participante = %Participant{id: "p6", canales_asignados: ["general"]}
      expect(ParticipantStoreMock, :obtener_participante, fn "p6" -> participante end)
      expect(ParticipantStoreMock, :guardar_participante, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :participante_actualizado, _ -> :ok end)

      {:ok, actualizado} = ParticipantManager.asignar_canal("p6", "soporte")
      assert "soporte" in actualizado.canales_asignados
      assert length(actualizado.canales_asignados) == 2
    end
  end

  describe "remover_canal/2" do
    test "elimina correctamente un canal asignado" do
      participante = %Participant{id: "p7", canales_asignados: ["general", "soporte"]}
      expect(ParticipantStoreMock, :obtener_participante, fn "p7" -> participante end)
      expect(ParticipantStoreMock, :guardar_participante, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :participante_actualizado, _ -> :ok end)

      {:ok, actualizado} = ParticipantManager.remover_canal("p7", "soporte")
      refute "soporte" in actualizado.canales_asignados
      assert actualizado.canales_asignados == ["general"]
    end
  end

  # ============================================================
  # MENSAJES Y CONEXIÓN
  # ============================================================

  describe "registrar_mensaje/2" do
    test "agrega un mensaje correctamente al historial" do
      participante = %Participant{id: "p8", mensajes: []}
      expect(ParticipantStoreMock, :obtener_participante, fn "p8" -> participante end)
      expect(ParticipantStoreMock, :guardar_participante, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :participante_actualizado, _ -> :ok end)

      {:ok, actualizado} = ParticipantManager.registrar_mensaje("p8", "Hola Hackathon!")
      [mensaje | _] = actualizado.mensajes
      assert mensaje.mensaje == "Hola Hackathon!"
      assert mensaje.timestamp != nil
    end
  end

  describe "registrar_conexion/1" do
    test "actualiza la última conexión y estado activo" do
      participante = %Participant{id: "p9", ultima_conexion: nil, estado: :desconectado}
      expect(ParticipantStoreMock, :obtener_participante, fn "p9" -> participante end)
      expect(ParticipantStoreMock, :guardar_participante, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :participante_actualizado, _ -> :ok end)

      {:ok, actualizado} = ParticipantManager.registrar_conexion("p9")
      assert actualizado.estado == :activo
      assert actualizado.ultima_conexion != nil
    end
  end

  # ============================================================
  # ELIMINACIÓN Y FILTRADO
  # ============================================================

  describe "eliminar_participante/1" do
    test "elimina correctamente un participante y difunde evento" do
      expect(ParticipantStoreMock, :eliminar_participante, fn "p10" -> :ok end)
      expect(BroadcastServiceMock, :notificar, fn :participante_eliminado, _ -> :ok end)

      assert {:ok, :eliminado} = ParticipantManager.eliminar_participante("p10")
    end
  end
end

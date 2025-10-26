defmodule ProyectoFinalPrg3.Test.Services.ParticipantManagerTest do
  use ExUnit.Case, async: true
  import Mox

  alias ProyectoFinalPrg3.Services.ParticipantManager

  @moduledoc """
  Pruebas unitarias para `ParticipantManager`.

  Se validan los flujos esenciales de gestión de participantes:
  - Registro, actualización y eliminación.
  - Asignación de canales y equipos.
  - Envío de mensajes, cambio de estado y token de sesión.
  - Difusión de eventos mediante `BroadcastService`.

  Todas las dependencias externas (`ParticipantStore`, `BroadcastService`)
  son simuladas con `Mox` para garantizar aislamiento.
  """

  setup :verify_on_exit!

  # ============================================================
  # REGISTRO DE PARTICIPANTES
  # ============================================================

  describe "registrar_participante/5" do
    test "crea un nuevo participante correctamente" do
      expect(ParticipantStoreMock, :buscar_por_correo, fn _ -> nil end)
      expect(ParticipantStoreMock, :guardar_participante, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :participante_registrado, _ -> :ok end)

      {:ok, participante} =
        ParticipantManager.registrar_participante(
          "Sharif",
          "sharif@example.com",
          "sharif_dev",
          "participante",
          "Backend"
        )

      assert participante.nombre == "Sharif"
      assert participante.rol == "participante"
      assert participante.estado == :activo
      assert participante.experiencia == "Backend"
    end

    test "retorna error si el correo ya está registrado" do
      expect(ParticipantStoreMock, :buscar_por_correo, fn _ -> %{nombre: "Existente"} end)
      assert {:error, :correo_ya_registrado} =
               ParticipantManager.registrar_participante("Laura", "l@x.com", "laura", "participante")
    end
  end

  # ============================================================
  # CONSULTAS BÁSICAS
  # ============================================================

  describe "obtener_participante/1" do
    test "retorna correctamente un participante existente" do
      participante = %{id: "p1", nombre: "Juan"}
      expect(ParticipantStoreMock, :obtener_participante, fn "p1" -> participante end)

      assert {:ok, result} = ParticipantManager.obtener_participante("p1")
      assert result.id == "p1"
    end

    test "retorna error si el participante no existe" do
      expect(ParticipantStoreMock, :obtener_participante, fn _ -> nil end)
      assert {:error, :no_encontrado} = ParticipantManager.obtener_participante("desconocido")
    end
  end

  # ============================================================
  # ACTUALIZACIONES GENERALES
  # ============================================================

  describe "actualizar_datos/2" do
    test "actualiza datos correctamente y difunde evento" do
      participante = %{id: "p1", nombre: "Laura", experiencia: "Básica"}
      expect(ParticipantStoreMock, :obtener_participante, fn "p1" -> participante end)
      expect(ParticipantStoreMock, :guardar_participante, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :participante_actualizado, _ -> :ok end)

      {:ok, actualizado} =
        ParticipantManager.actualizar_datos("p1", %{experiencia: "Avanzada"})

      assert actualizado.experiencia == "Avanzada"
    end
  end

  describe "actualizar_experiencia/2" do
    test "cambia la experiencia correctamente" do
      participante = %{id: "p2", experiencia: "Junior"}
      expect(ParticipantStoreMock, :obtener_participante, fn "p2" -> participante end)
      expect(ParticipantStoreMock, :guardar_participante, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :participante_actualizado, _ -> :ok end)

      {:ok, result} = ParticipantManager.actualizar_experiencia("p2", "Senior")
      assert result.experiencia == "Senior"
    end
  end

  describe "actualizar_rol/2" do
    test "modifica el rol correctamente" do
      participante = %{id: "p3", rol: "participante"}
      expect(ParticipantStoreMock, :obtener_participante, fn "p3" -> participante end)
      expect(ParticipantStoreMock, :guardar_participante, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :participante_actualizado, _ -> :ok end)

      {:ok, result} = ParticipantManager.actualizar_rol("p3", "mentor")
      assert result.rol == "mentor"
    end
  end

  describe "actualizar_estado/2" do
    test "cambia el estado correctamente" do
      participante = %{id: "p4", estado: :activo}
      expect(ParticipantStoreMock, :obtener_participante, fn "p4" -> participante end)
      expect(ParticipantStoreMock, :guardar_participante, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :participante_actualizado, _ -> :ok end)

      {:ok, actualizado} = ParticipantManager.actualizar_estado("p4", :desconectado)
      assert actualizado.estado == :desconectado
    end
  end

  # ============================================================
  # CANALES Y EQUIPOS
  # ============================================================

  describe "asignar_canal/2" do
    test "añade un canal al participante" do
      participante = %{id: "p5", canales_asignados: []}
      expect(ParticipantStoreMock, :obtener_participante, fn "p5" -> participante end)
      expect(ParticipantStoreMock, :guardar_participante, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :participante_actualizado, _ -> :ok end)

      {:ok, actualizado} = ParticipantManager.asignar_canal("p5", "canal-general")
      assert "canal-general" in actualizado.canales_asignados
    end
  end

  describe "remover_canal/2" do
    test "elimina un canal correctamente" do
      participante = %{id: "p6", canales_asignados: ["canal-x", "canal-y"]}
      expect(ParticipantStoreMock, :obtener_participante, fn "p6" -> participante end)
      expect(ParticipantStoreMock, :guardar_participante, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :participante_actualizado, _ -> :ok end)

      {:ok, actualizado} = ParticipantManager.remover_canal("p6", "canal-x")
      refute "canal-x" in actualizado.canales_asignados
    end
  end

  describe "actualizar_equipo/2" do
    test "asigna un equipo correctamente" do
      participante = %{id: "p7", equipo_id: nil}
      expect(ParticipantStoreMock, :obtener_participante, fn "p7" -> participante end)
      expect(ParticipantStoreMock, :guardar_participante, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :participante_actualizado, _ -> :ok end)

      {:ok, actualizado} = ParticipantManager.actualizar_equipo("p7", "equipo-01")
      assert actualizado.equipo_id == "equipo-01"
    end
  end

  # ============================================================
  # MENSAJES Y TOKENS
  # ============================================================

  describe "registrar_mensaje/2" do
    test "agrega un mensaje nuevo correctamente" do
      participante = %{id: "p8", mensajes: []}
      expect(ParticipantStoreMock, :obtener_participante, fn "p8" -> participante end)
      expect(ParticipantStoreMock, :guardar_participante, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :participante_actualizado, _ -> :ok end)

      {:ok, actualizado} = ParticipantManager.registrar_mensaje("p8", "Hola equipo")
      [mensaje | _] = actualizado.mensajes
      assert mensaje.mensaje == "Hola equipo"
    end
  end

  describe "asignar_token/2" do
    test "asigna token de sesión correctamente" do
      participante = %{id: "p9", token_sesion: nil}
      expect(ParticipantStoreMock, :obtener_participante, fn "p9" -> participante end)
      expect(ParticipantStoreMock, :guardar_participante, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :participante_actualizado, _ -> :ok end)

      {:ok, actualizado} = ParticipantManager.asignar_token("p9", "token-123")
      assert actualizado.token_sesion == "token-123"
    end
  end

  # ============================================================
  # ELIMINACIÓN Y FILTRADO
  # ============================================================

  describe "eliminar_participante/1" do
    test "elimina correctamente un participante existente" do
      expect(ParticipantStoreMock, :eliminar_participante, fn "p10" -> :ok end)
      expect(BroadcastServiceMock, :notificar, fn :participante_eliminado, _ -> :ok end)

      assert {:ok, :eliminado} = ParticipantManager.eliminar_participante("p10")
    end
  end

  describe "filtrar_por_rol/1" do
    test "filtra participantes por rol correctamente" do
      participantes = [
        %{nombre: "A", rol: "mentor"},
        %{nombre: "B", rol: "participante"},
        %{nombre: "C", rol: "mentor"}
      ]

      expect(ParticipantStoreMock, :listar_participantes, fn -> participantes end)
      result = ParticipantManager.filtrar_por_rol("mentor")
      assert Enum.all?(result, &(&1.rol == "mentor"))
    end
  end

  describe "sin_equipo/0" do
    test "devuelve participantes sin equipo asignado" do
      participantes = [
        %{nombre: "A", equipo_id: nil},
        %{nombre: "B", equipo_id: "E1"},
        %{nombre: "C", equipo_id: nil}
      ]

      expect(ParticipantStoreMock, :listar_participantes, fn -> participantes end)
      result = ParticipantManager.sin_equipo()
      assert Enum.count(result) == 2
    end
  end
end

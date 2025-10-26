defmodule ProyectoFinalPrg3.Test.Services.CommandServiceTest do
  use ExUnit.Case, async: true
  import Mox

  alias ProyectoFinalPrg3.Services.CommandService

  @moduledoc """
  Pruebas unitarias para `CommandService`.

  Se validan los principales comportamientos del servicio de comandos CLI:
  - Ejecución y respuesta de comandos reconocidos.
  - Manejo de errores y casos no reconocidos.
  - Interacción con servicios dependientes (`TeamManager`, `ProjectManager`, `ChatService`, etc.).
  - Registro de eventos en `LoggerService`.

  Todas las dependencias externas son simuladas mediante Mox.
  """

  setup :verify_on_exit!

  # ============================================================
  # COMANDOS NO RECONOCIDOS
  # ============================================================

  describe "ejecutar_comando/2 - comando no reconocido" do
    test "devuelve error cuando el comando no existe" do
      assert {:error, mensaje} = CommandService.ejecutar_comando(%{service: :desconocido}, [])
      assert String.contains?(mensaje, "Comando no reconocido")
    end
  end

  # ============================================================
  # LISTAR EQUIPOS
  # ============================================================

  describe "listar_equipos/2" do
    test "retorna lista de equipos correctamente" do
      equipos = [%{nombre: "Team Alpha"}, %{nombre: "Team Beta"}]

      expect(TeamManagerMock, :listar_equipos, fn -> equipos end)
      expect(LoggerServiceMock, :registrar_evento, fn "Comando ejecutado", _ -> :ok end)

      {:ok, resultado} =
        CommandService.ejecutar_comando(%{service: :command_service, action: :listar_equipos}, [])

      assert length(resultado) == 2
      assert Enum.any?(resultado, &(&1.nombre == "Team Alpha"))
    end
  end

  # ============================================================
  # MOSTRAR PROYECTO DE UN EQUIPO
  # ============================================================

  describe "mostrar_proyecto/2" do
    test "muestra el proyecto asociado correctamente" do
      equipo = %{id_proyecto: "proj-123", nombre: "TeamX"}
      proyecto = %{id: "proj-123", nombre: "SmartHub"}

      expect(TeamManagerMock, :obtener_equipo, fn "TeamX" -> {:ok, equipo} end)
      expect(ProjectManagerMock, :obtener_proyecto_por_id, fn "proj-123" -> {:ok, proyecto} end)
      expect(LoggerServiceMock, :registrar_evento, fn "Comando ejecutado", _ -> :ok end)

      {:ok, resultado} =
        CommandService.ejecutar_comando(%{service: :command_service, action: :mostrar_proyecto}, ["TeamX"])

      assert resultado.nombre == "SmartHub"
    end

    test "retorna error si el equipo no existe" do
      expect(TeamManagerMock, :obtener_equipo, fn _ -> {:error, :no_encontrado} end)

      assert {:error, mensaje} =
               CommandService.ejecutar_comando(%{service: :command_service, action: :mostrar_proyecto}, ["TeamX"])

      assert mensaje == "No se encontró el equipo o proyecto indicado."
    end
  end

  # ============================================================
  # UNIRSE A UN EQUIPO
  # ============================================================

  describe "unirse_a_equipo/2" do
    test "permite unirse a un equipo exitosamente" do
      participante_id = "user-123"
      equipo = %{nombre: "Team Phoenix"}

      expect(SessionManagerMock, :obtener_participante_actual, fn -> participante_id end)
      expect(TeamManagerMock, :unirse_a_equipo, fn "Team Phoenix", "user-123" -> {:ok, equipo} end)
      expect(LoggerServiceMock, :registrar_evento, fn "Comando ejecutado", _ -> :ok end)

      {:ok, mensaje} =
        CommandService.ejecutar_comando(%{service: :command_service, action: :unirse_a_equipo}, ["Team Phoenix"])

      assert mensaje =~ "Te uniste exitosamente"
    end

    test "retorna error si ya pertenece al equipo" do
      expect(SessionManagerMock, :obtener_participante_actual, fn -> "user-001" end)
      expect(TeamManagerMock, :unirse_a_equipo, fn _, _ -> {:error, :ya_es_miembro} end)

      assert {:error, msg} =
               CommandService.ejecutar_comando(%{service: :command_service, action: :unirse_a_equipo}, ["Team Alpha"])

      assert msg == "Ya perteneces a este equipo."
    end

    test "retorna error si el equipo no existe" do
      expect(SessionManagerMock, :obtener_participante_actual, fn -> "user-001" end)
      expect(TeamManagerMock, :unirse_a_equipo, fn _, _ -> {:error, :no_encontrado} end)

      assert {:error, msg} =
               CommandService.ejecutar_comando(%{service: :command_service, action: :unirse_a_equipo}, ["Team Ghost"])

      assert msg == "No se encontró el equipo indicado."
    end
  end

  # ============================================================
  # INGRESAR CHAT EQUIPO
  # ============================================================

  describe "ingresar_chat_equipo/2" do
    test "permite ingresar correctamente al chat del equipo" do
      expect(ChatServiceMock, :ingresar_chat_equipo, fn "TeamX" -> :ok end)
      expect(LoggerServiceMock, :registrar_evento, fn "Comando ejecutado", _ -> :ok end)

      {:ok, mensaje} =
        CommandService.ejecutar_comando(%{service: :command_service, action: :ingresar_chat_equipo}, ["TeamX"])

      assert mensaje =~ "Has ingresado al chat del equipo TeamX"
    end
  end

  # ============================================================
  # MOSTRAR AYUDA
  # ============================================================

  describe "mostrar_ayuda/0" do
    test "muestra la lista de comandos disponibles" do
      comandos = %{
        "/listar_equipos" => %{description: "Lista todos los equipos"},
        "/unirse_a_equipo" => %{description: "Unirse a un equipo existente"}
      }

      expect(CommandRegistryMock, :all, fn -> comandos end)

      capture_io(fn ->
        assert {:ok, :help_mostrado} =
                 CommandService.ejecutar_comando(%{service: :command_service, action: :mostrar_ayuda}, [])
      end)
    end
  end
end

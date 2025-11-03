defmodule ProyectoFinalPrg3.Test.Services.TeamManagerTest do
  use ExUnit.Case, async: true
  import Mox

  alias ProyectoFinalPrg3.Services.TeamManager
  alias ProyectoFinalPrg3.Domain.{Team, Participant}
  alias ProyectoFinalPrg3.Adapters.Persistence.TeamStore
  alias ProyectoFinalPrg3.Services.{AuthService, BroadcastService, ParticipantManager}

  @moduledoc """
  Pruebas unitarias para `TeamManager`.

  Se validan operaciones clave:
  - Creación, actualización y disolución de equipos.
  - Gestión de participantes (agregar, remover, unirse).
  - Asignación de mentores, proyectos y canales.
  - Filtrado, historial y notificaciones de equipo.

  Cobertura total de campos del struct Team:
  id, nombre, descripcion, categoria, id_proyecto, id_mentor,
  participantes, fecha_creacion, estado, canal_chat_id, puntaje, historial.
  """

  setup :verify_on_exit!

  # ============================================================
  # CREACIÓN DE EQUIPOS
  # ============================================================

  describe "crear_equipo/3" do
    test "crea correctamente un nuevo equipo" do
      expect(TeamStoreMock, :obtener_equipo, fn _ -> nil end)
      expect(TeamStoreMock, :guardar_equipo, fn equipo -> equipo end)
      expect(BroadcastServiceMock, :notificar, fn :equipo_creado, _ -> :ok end)

      {:ok, equipo} = TeamManager.crear_equipo("Team Phoenix", "IA", "Equipo especializado en ML")

      assert %Team{} = equipo
      assert equipo.nombre == "Team Phoenix"
      assert equipo.categoria == "IA"
      assert equipo.descripcion =~ "ML"
      assert equipo.estado == :activo
      assert equipo.puntaje == 0
      assert equipo.historial == []
      assert equipo.participantes == []
    end

    test "retorna error si el equipo ya existe" do
      expect(TeamStoreMock, :obtener_equipo, fn _ -> %Team{nombre: "Team Phoenix"} end)
      assert {:error, :equipo_ya_existente} =
               TeamManager.crear_equipo("Team Phoenix", "IA", "Equipo duplicado")
    end
  end

  # ============================================================
  # ACTUALIZACIÓN Y DISOLUCIÓN
  # ============================================================

  describe "actualizar_equipo/1" do
    test "actualiza correctamente un equipo existente" do
      equipo = %Team{nombre: "Team Alpha", categoria: "IA"}
      expect(TeamStoreMock, :guardar_equipo, fn t -> t end)
      expect(BroadcastServiceMock, :notificar, fn :equipo_actualizado, _ -> :ok end)

      {:ok, actualizado} = TeamManager.actualizar_equipo(equipo)
      assert actualizado.nombre == "Team Alpha"
    end
  end

  describe "disolver_equipo/1" do
    test "marca un equipo como inactivo" do
      equipo = %Team{nombre: "Team Alpha", estado: :activo}
      expect(TeamStoreMock, :obtener_equipo, fn _ -> equipo end)
      expect(TeamStoreMock, :guardar_equipo, fn e -> e end)
      expect(BroadcastServiceMock, :notificar, fn :equipo_disuelto, _ -> :ok end)

      {:ok, :equipo_disuelto} = TeamManager.disolver_equipo("Team Alpha")
    end
  end

  # ============================================================
  # PARTICIPANTES
  # ============================================================

  describe "agregar_participante/2" do
    test "agrega un participante a un equipo correctamente" do
      equipo = %Team{id: "t1", nombre: "Team Beta", participantes: []}
      participante = %Participant{id: "p1", nombre: "Alice"}

      expect(TeamStoreMock, :obtener_equipo, fn _ -> equipo end)
      expect(TeamStoreMock, :guardar_equipo, fn e -> e end)
      expect(ParticipantManagerMock, :actualizar_equipo, fn _, _ -> :ok end)
      expect(BroadcastServiceMock, :notificar, fn :equipo_actualizado, _ -> :ok end)

      {:ok, actualizado} = TeamManager.agregar_participante("Team Beta", participante)
      assert Enum.any?(actualizado.participantes, &(&1.id == "p1"))
    end

    test "retorna error si el participante ya está en el equipo" do
      participante = %Participant{id: "p1", nombre: "Alice"}
      equipo = %Team{id: "t1", nombre: "Team Beta", participantes: [participante]}
      expect(TeamStoreMock, :obtener_equipo, fn _ -> equipo end)
      assert {:error, :ya_en_equipo} = TeamManager.agregar_participante("Team Beta", participante)
    end
  end

  describe "unirse_a_equipo/2" do
    test "permite a un usuario autenticado unirse a un equipo existente" do
      participante = %Participant{id: "p2", nombre: "Bob", equipo_id: nil}
      equipo = %Team{id: "t2", nombre: "Team Gamma", participantes: []}

      expect(AuthServiceMock, :obtener_participante, fn _ -> {:ok, participante} end)
      expect(TeamStoreMock, :obtener_equipo, fn _ -> equipo end)
      expect(TeamStoreMock, :guardar_equipo, fn e -> e end)
      expect(ParticipantManagerMock, :actualizar_equipo, fn _, _ -> :ok end)
      expect(BroadcastServiceMock, :notificar, fn :miembro_unido, _ -> :ok end)

      {:ok, actualizado} = TeamManager.unirse_a_equipo("Team Gamma", "p2")
      assert Enum.any?(actualizado.participantes, &(&1.id == "p2"))
    end
  end

  describe "remover_participante/2" do
    test "remueve correctamente un participante" do
      equipo = %Team{
        nombre: "Team Zeta",
        participantes: [%Participant{id: "p1", nombre: "Alice"}]
      }

      expect(TeamStoreMock, :obtener_equipo, fn _ -> equipo end)
      expect(TeamStoreMock, :guardar_equipo, fn e -> e end)
      expect(ParticipantManagerMock, :actualizar_equipo, fn _, _ -> :ok end)
      expect(BroadcastServiceMock, :notificar, fn :equipo_actualizado, _ -> :ok end)

      {:ok, actualizado} = TeamManager.remover_participante("Team Zeta", "p1")
      refute Enum.any?(actualizado.participantes, &(&1.id == "p1"))
    end
  end

  # ============================================================
  # FILTRADO Y CONSULTA
  # ============================================================

  describe "obtener_equipo/1 y filtrar_equipos/2" do
    test "obtiene correctamente un equipo existente" do
      equipo = %Team{nombre: "Team Omega"}
      expect(TeamStoreMock, :obtener_equipo, fn _ -> equipo end)
      {:ok, result} = TeamManager.obtener_equipo("Team Omega")
      assert result.nombre == "Team Omega"
    end

    test "filtra equipos por categoría" do
      equipos = [
        %Team{nombre: "Alpha", categoria: "IA"},
        %Team{nombre: "Beta", categoria: "Salud"}
      ]

      expect(TeamStoreMock, :listar_equipos, fn -> equipos end)
      result = TeamManager.filtrar_equipos(:categoria, "IA")
      assert Enum.count(result) == 1
      assert hd(result).nombre == "Alpha"
    end
  end

  # ============================================================
  # MENTOR Y PROYECTO
  # ============================================================

  describe "asignar_mentor/2 y vincular_proyecto/2" do
    test "asigna correctamente un mentor a un equipo" do
      equipo = %Team{nombre: "Team Delta", id_mentor: nil}
      expect(TeamStoreMock, :obtener_equipo, fn _ -> equipo end)
      expect(TeamStoreMock, :guardar_equipo, fn e -> e end)
      expect(BroadcastServiceMock, :notificar, fn :mentor_asignado, _ -> :ok end)

      {:ok, actualizado} = TeamManager.asignar_mentor("Team Delta", "mentor-1")
      assert actualizado.id_mentor == "mentor-1"
    end

    test "vincula un proyecto al equipo" do
      equipo = %Team{nombre: "Team Sigma", id_proyecto: nil}
      expect(TeamStoreMock, :obtener_equipo, fn _ -> equipo end)
      expect(TeamStoreMock, :guardar_equipo, fn e -> e end)
      expect(BroadcastServiceMock, :notificar, fn :proyecto_vinculado, _ -> :ok end)

      {:ok, actualizado} = TeamManager.vincular_proyecto("Team Sigma", "proj-1")
      assert actualizado.id_proyecto == "proj-1"
    end
  end

  # ============================================================
  # PUNTAJE, HISTORIAL Y COMUNICACIÓN
  # ============================================================

  describe "actualizar_puntaje/2" do
    test "modifica el puntaje de un equipo" do
      equipo = %Team{nombre: "Team Orion", puntaje: 0}
      expect(TeamStoreMock, :obtener_equipo, fn _ -> equipo end)
      expect(TeamStoreMock, :guardar_equipo, fn e -> e end)
      expect(BroadcastServiceMock, :notificar, fn :puntaje_actualizado, _ -> :ok end)

      {:ok, actualizado} = TeamManager.actualizar_puntaje("Team Orion", 95)
      assert actualizado.puntaje == 95
    end
  end

  describe "registrar_evento/2 y obtener_historial/1" do
    test "registra un evento en el historial del equipo" do
      equipo = %Team{nombre: "Team Phoenix", historial: []}
      expect(TeamStoreMock, :obtener_equipo, fn _ -> equipo end)
      expect(TeamStoreMock, :guardar_equipo, fn e -> e end)

      {:ok, actualizado} = TeamManager.registrar_evento("Team Phoenix", "Proyecto completado")
      assert length(actualizado.historial) == 1
      assert hd(actualizado.historial).detalle == "Proyecto completado"
    end

    test "obtiene el historial correctamente" do
      historial = [%{detalle: "Registro"}]
      equipo = %Team{nombre: "Team Phoenix", historial: historial}
      expect(TeamStoreMock, :obtener_equipo, fn _ -> equipo end)
      {:ok, lista} = TeamManager.obtener_historial("Team Phoenix")
      assert lista == historial
    end
  end

  describe "asignar_canal_chat/2 y notificar_equipo/2" do
    test "asigna un canal de chat al equipo" do
      equipo = %Team{nombre: "Team Nova", canal_chat_id: nil}
      expect(TeamStoreMock, :obtener_equipo, fn _ -> equipo end)
      expect(TeamStoreMock, :guardar_equipo, fn e -> e end)
      expect(BroadcastServiceMock, :notificar, fn :canal_chat_asignado, _ -> :ok end)

      {:ok, actualizado} = TeamManager.asignar_canal_chat("Team Nova", "channel-99")
      assert actualizado.canal_chat_id == "channel-99"
    end

    test "envía un mensaje de notificación al equipo" do
      equipo = %Team{nombre: "Team Nova"}
      expect(BroadcastServiceMock, :notificar, fn :mensaje_equipo, _ -> :ok end)

      {:ok, :mensaje_enviado} = TeamManager.notificar_equipo(equipo, "Bienvenidos al hackathon!")
    end
  end
end

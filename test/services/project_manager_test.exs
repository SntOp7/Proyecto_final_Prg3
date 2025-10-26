defmodule ProyectoFinalPrg3.Test.Services.ProjectManagerTest do
  use ExUnit.Case, async: true
  import Mox

  alias ProyectoFinalPrg3.Services.ProjectManager
  alias ProyectoFinalPrg3.Domain.{Project, Progress}
  alias ProyectoFinalPrg3.Adapters.Persistence.{ProjectStore, ProgressStore, FeedbackStore}
  alias ProyectoFinalPrg3.Services.{BroadcastService, TeamManager, CategoryService}

  @moduledoc """
  Pruebas unitarias para `ProjectManager`.

  Se validan todas las operaciones principales:
  - Creación, actualización, eliminación y archivado de proyectos.
  - Registro de avances y retroalimentaciones.
  - Filtrado y consultas por equipo, mentor o categoría.
  - Actualización de atributos individuales (tags, visibilidad, repositorio, etc.).

  Cobertura total de campos del struct Project:
  id, nombre, descripcion, categoria, estado, fecha_creacion,
  fecha_actualizacion, equipo_id, mentor_id, avances, retroalimentaciones,
  repositorio_url, puntaje, visibilidad, tags.
  """

  setup :verify_on_exit!

  # ============================================================
  # CREACIÓN DE PROYECTOS
  # ============================================================

  describe "crear_proyecto/5" do
    test "crea un nuevo proyecto correctamente con todos los campos" do
      expect(ProjectStoreMock, :obtener_proyecto, fn _ -> nil end)
      expect(ProjectStoreMock, :guardar_proyecto, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :proyecto_creado, _ -> :ok end)
      expect(CategoryServiceMock, :agregar_proyecto_a_categoria, fn _, _ -> :ok end)

      {:ok, proyecto} =
        ProjectManager.crear_proyecto(
          "HackVision",
          "Plataforma de IA para análisis de video en tiempo real",
          "IA",
          "team-123",
          "mentor-99"
        )

      assert %Project{} = proyecto
      assert proyecto.nombre == "HackVision"
      assert proyecto.descripcion =~ "video"
      assert proyecto.categoria == "IA"
      assert proyecto.estado == :en_desarrollo
      assert is_list(proyecto.avances)
      assert proyecto.retroalimentaciones == []
      assert proyecto.repositorio_url == nil
      assert proyecto.visibilidad == :privado
      assert proyecto.tags == []
      assert is_binary(proyecto.id)
      assert proyecto.puntaje == 0
    end

    test "retorna error si ya existe un proyecto con el mismo nombre" do
      expect(ProjectStoreMock, :obtener_proyecto, fn _ -> %{nombre: "HackVision"} end)
      assert {:error, :proyecto_ya_existente} =
               ProjectManager.crear_proyecto("HackVision", "Duplicado", "IA", nil)
    end
  end

  # ============================================================
  # ACTUALIZACIÓN DE PROYECTOS
  # ============================================================

  describe "actualizar_proyecto/2" do
    test "modifica la descripción y estado de un proyecto existente" do
      proyecto = %Project{
        id: "proj1",
        nombre: "HackVision",
        descripcion: "Versión inicial",
        categoria: "IA",
        estado: :en_desarrollo,
        fecha_creacion: ~N[2025-10-25 00:00:00],
        fecha_actualizacion: ~N[2025-10-25 00:00:00],
        equipo_id: "team-123",
        mentor_id: nil,
        avances: [],
        retroalimentaciones: [],
        repositorio_url: nil,
        puntaje: 0,
        visibilidad: :privado,
        tags: []
      }

      expect(ProjectStoreMock, :obtener_proyecto, fn _ -> proyecto end)
      expect(ProjectStoreMock, :guardar_proyecto, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :proyecto_actualizado, _ -> :ok end)

      {:ok, actualizado} =
        ProjectManager.actualizar_proyecto("HackVision", %{descripcion: "Versión mejorada", estado: :completado})

      assert actualizado.descripcion == "Versión mejorada"
      assert actualizado.estado == :completado
      assert actualizado.fecha_actualizacion != proyecto.fecha_actualizacion
    end
  end

  # ============================================================
  # ELIMINACIÓN DE PROYECTOS
  # ============================================================

  describe "eliminar_proyecto/1" do
    test "elimina un proyecto correctamente y notifica eventos relacionados" do
      proyecto = %Project{
        id: "proj2",
        nombre: "CodeAid",
        categoria: "Educación",
        equipo_id: "team-22",
        estado: :en_desarrollo
      }

      expect(ProjectStoreMock, :obtener_proyecto, fn _ -> proyecto end)
      expect(ProjectStoreMock, :eliminar_proyecto, fn _ -> :ok end)
      expect(TeamManagerMock, :obtener_equipo_por_id, fn _ -> {:ok, %{nombre: "Team22"}} end)
      expect(TeamManagerMock, :vincular_proyecto, fn _, _ -> :ok end)
      expect(CategoryServiceMock, :eliminar_proyecto_de_categoria, fn _, _ -> :ok end)
      expect(BroadcastServiceMock, :notificar, fn :proyecto_eliminado, _ -> :ok end)

      assert {:ok, :proyecto_eliminado} = ProjectManager.eliminar_proyecto("CodeAid")
    end
  end

  # ============================================================
  # CONSULTAS Y FILTROS
  # ============================================================

  describe "obtener_proyecto/1 y filtrar_proyectos/2" do
    test "retorna correctamente un proyecto existente" do
      proyecto = %Project{id: "proj3", nombre: "HackEdu", categoria: "Educación"}
      expect(ProjectStoreMock, :obtener_proyecto, fn "HackEdu" -> proyecto end)

      {:ok, result} = ProjectManager.obtener_proyecto("HackEdu")
      assert result.nombre == "HackEdu"
    end

    test "filtra por categoría correctamente" do
      proyectos = [
        %Project{nombre: "HackEdu", categoria: "Educación"},
        %Project{nombre: "HealthAI", categoria: "Salud"}
      ]

      expect(ProjectStoreMock, :listar_proyectos, fn -> proyectos end)

      result = ProjectManager.filtrar_proyectos(:categoria, "Educación")
      assert Enum.count(result) == 1
      assert hd(result).nombre == "HackEdu"
    end
  end

  # ============================================================
  # REGISTRO DE AVANCES
  # ============================================================

  describe "registrar_avance/2" do
    test "agrega un nuevo avance y actualiza la fecha" do
      avance = %Progress{id: "av1", descripcion: "Primer sprint"}
      proyecto = %Project{nombre: "HackVision", avances: []}

      expect(ProjectStoreMock, :obtener_proyecto, fn _ -> proyecto end)
      expect(ProgressStoreMock, :guardar_avance, fn _ -> :ok end)
      expect(ProjectStoreMock, :guardar_proyecto, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :avance_registrado, _ -> :ok end)

      {:ok, actualizado} = ProjectManager.registrar_avance("HackVision", avance)
      assert length(actualizado.avances) == 1
      assert hd(actualizado.avances).id == "av1"
    end
  end

  # ============================================================
  # RETROALIMENTACIONES
  # ============================================================

  describe "registrar_retroalimentacion/2" do
    test "añade correctamente el id del feedback" do
      feedback = %{id: "fb1", contenido: "Buen progreso"}
      proyecto = %Project{nombre: "HackVision", retroalimentaciones: []}

      expect(ProjectStoreMock, :obtener_proyecto, fn _ -> proyecto end)
      expect(FeedbackStoreMock, :guardar_feedback, fn _ -> :ok end)
      expect(ProjectStoreMock, :guardar_proyecto, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :retroalimentacion_registrada, _ -> :ok end)

      {:ok, actualizado} = ProjectManager.registrar_retroalimentacion("HackVision", feedback)
      assert "fb1" in actualizado.retroalimentaciones
    end
  end

  # ============================================================
  # ACTUALIZACIONES DE CAMPOS INDIVIDUALES
  # ============================================================

  describe "actualizar_campo/privado indirectamente" do
    test "actualiza la visibilidad correctamente" do
      proyecto = %Project{nombre: "HackVision", visibilidad: :privado}

      expect(ProjectStoreMock, :obtener_proyecto, fn _ -> proyecto end)
      expect(ProjectStoreMock, :guardar_proyecto, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :visibilidad_actualizada, _ -> :ok end)

      {:ok, actualizado} = ProjectManager.actualizar_visibilidad("HackVision", :publico)
      assert actualizado.visibilidad == :publico
    end

    test "actualiza los tags del proyecto" do
      proyecto = %Project{nombre: "HackVision", tags: []}
      expect(ProjectStoreMock, :obtener_proyecto, fn _ -> proyecto end)
      expect(ProjectStoreMock, :guardar_proyecto, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :tags_actualizados, _ -> :ok end)

      {:ok, actualizado} = ProjectManager.actualizar_tags("HackVision", ["AI", "Video"])
      assert actualizado.tags == ["AI", "Video"]
    end
  end

  # ============================================================
  # ARCHIVADO DE PROYECTOS
  # ============================================================

  describe "archivar_proyecto/1" do
    test "marca un proyecto como archivado y privado" do
      proyecto = %Project{nombre: "HackVision", estado: :en_desarrollo, visibilidad: :publico}

      expect(ProjectStoreMock, :obtener_proyecto, fn _ -> proyecto end)
      expect(ProjectStoreMock, :guardar_proyecto, fn p -> p end)
      expect(BroadcastServiceMock, :notificar, fn :proyecto_archivado, _ -> :ok end)

      {:ok, archivado} = ProjectManager.archivar_proyecto("HackVision")
      assert archivado.estado == :archivado
      assert archivado.visibilidad == :privado
    end
  end
end

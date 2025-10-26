defmodule ProyectoFinalPrg3.Test.Services.MentorManagerTest do
  use ExUnit.Case, async: true
  import Mox

  alias ProyectoFinalPrg3.Services.MentorManager

  @moduledoc """
  Pruebas unitarias para `MentorManager`.

  Validan los flujos principales del servicio:
  - Registro y actualización de mentores.
  - Asignación a equipos y gestión de disponibilidad.
  - Emisión, actualización y filtrado de feedbacks.
  - Comunicación mediante `BroadcastService`.

  Todas las dependencias externas (`MentorStore`, `FeedbackStore`, `TeamManager`, `BroadcastService`)
  son simuladas mediante `Mox`.
  """

  setup :verify_on_exit!

  # ============================================================
  # REGISTRO DE MENTORES
  # ============================================================

  describe "registrar_mentor/4" do
    test "registra correctamente un nuevo mentor" do
      expect(MentorStoreMock, :buscar_por_correo, fn _ -> nil end)
      expect(MentorStoreMock, :guardar_mentor, fn mentor -> mentor end)
      expect(BroadcastServiceMock, :notificar, fn :mentor_registrado, _ -> :ok end)

      {:ok, mentor} =
        MentorManager.registrar_mentor("Carlos Ruiz", "carlos@example.com", "IA", "tecnico")

      assert mentor.nombre == "Carlos Ruiz"
      assert mentor.especialidad == "IA"
      assert mentor.activo == true
      assert mentor.disponibilidad == :disponible
    end

    test "retorna error si el correo ya está registrado" do
      expect(MentorStoreMock, :buscar_por_correo, fn _ -> %{nombre: "Existente"} end)

      assert {:error, :correo_ya_registrado} =
               MentorManager.registrar_mentor("Laura", "laura@x.com", "UX", "mentor")
    end
  end

  # ============================================================
  # ACTUALIZACIÓN Y DESACTIVACIÓN
  # ============================================================

  describe "actualizar_datos/2" do
    test "actualiza correctamente los datos del mentor" do
      mentor = %{id: "m1", nombre: "Carlos", biografia: "Original"}
      expect(MentorStoreMock, :obtener_por_id, fn "m1" -> mentor end)
      expect(MentorStoreMock, :guardar_mentor, fn m -> m end)
      expect(BroadcastServiceMock, :notificar, fn :mentor_actualizado, _ -> :ok end)

      {:ok, actualizado} =
        MentorManager.actualizar_datos("m1", %{biografia: "Actualizada"})

      assert actualizado.biografia == "Actualizada"
    end

    test "retorna error si el mentor no existe" do
      expect(MentorStoreMock, :obtener_por_id, fn _ -> nil end)
      assert {:error, :no_encontrado} = MentorManager.actualizar_datos("invalido", %{bio: "x"})
    end
  end

  describe "desactivar_mentor/1" do
    test "marca al mentor como inactivo" do
      mentor = %{id: "m1", activo: true, disponibilidad: :disponible}
      expect(MentorStoreMock, :obtener_por_id, fn "m1" -> mentor end)
      expect(MentorStoreMock, :guardar_mentor, fn m -> m end)
      expect(BroadcastServiceMock, :notificar, fn :mentor_desactivado, _ -> :ok end)

      {:ok, resultado} = MentorManager.desactivar_mentor("m1")

      assert resultado.activo == false
      assert resultado.disponibilidad == :desconectado
    end
  end

  # ============================================================
  # ASIGNACIÓN A EQUIPO
  # ============================================================

  describe "asignar_a_equipo/2" do
    test "asigna correctamente un mentor a un equipo" do
      mentor = %{id: "m1", equipos_asignados: []}
      equipo = %{id: "e1", nombre: "Team Rocket"}

      expect(MentorStoreMock, :obtener_por_id, fn "m1" -> mentor end)
      expect(TeamManagerMock, :obtener_equipo, fn "Team Rocket" -> {:ok, equipo} end)
      expect(TeamManagerMock, :actualizar_equipo, fn _ -> :ok end)
      expect(MentorStoreMock, :guardar_mentor, fn m -> m end)
      expect(BroadcastServiceMock, :notificar, fn :mentor_asignado_equipo, _ -> :ok end)

      {:ok, actualizado} = MentorManager.asignar_a_equipo("m1", "Team Rocket")

      assert "e1" in actualizado.equipos_asignados
    end

    test "retorna error si el equipo no existe" do
      mentor = %{id: "m1", equipos_asignados: []}

      expect(MentorStoreMock, :obtener_por_id, fn "m1" -> mentor end)
      expect(TeamManagerMock, :obtener_equipo, fn _ -> {:error, :no_encontrado} end)

      assert {:error, :no_encontrado} = MentorManager.asignar_a_equipo("m1", "Desconocido")
    end
  end

  # ============================================================
  # DISPONIBILIDAD
  # ============================================================

  describe "cambiar_disponibilidad/2" do
    test "actualiza correctamente la disponibilidad" do
      mentor = %{id: "m1", disponibilidad: :disponible}
      expect(MentorStoreMock, :obtener_por_id, fn "m1" -> mentor end)
      expect(MentorStoreMock, :guardar_mentor, fn m -> m end)
      expect(BroadcastServiceMock, :notificar, fn :disponibilidad_cambiada, _ -> :ok end)

      {:ok, resultado} = MentorManager.cambiar_disponibilidad("m1", :ocupado)
      assert resultado.disponibilidad == :ocupado
    end
  end

  # ============================================================
  # FEEDBACKS
  # ============================================================

  describe "registrar_feedback/2" do
    test "crea un feedback correctamente" do
      mentor = %{id: "m1", retroalimentaciones: []}

      expect(MentorStoreMock, :obtener_por_id, fn "m1" -> mentor end)
      expect(FeedbackStoreMock, :guardar_feedback, fn fb -> fb end)
      expect(MentorStoreMock, :guardar_mentor, fn m -> m end)
      expect(BroadcastServiceMock, :notificar, fn :feedback_creado, _ -> :ok end)

      {:ok, feedback} =
        MentorManager.registrar_feedback("m1", %{
          proyecto_id: "p1",
          equipo_id: "e1",
          avance_id: "a1",
          contenido: "Buen avance"
        })

      assert feedback.proyecto_id == "p1"
      assert feedback.contenido == "Buen avance"
      assert feedback.estado == "pendiente"
    end
  end

  describe "actualizar_estado_feedback/2" do
    test "actualiza el estado de un feedback" do
      fb = %{id: "f1", estado: "pendiente"}
      expect(FeedbackStoreMock, :obtener_feedback, fn "f1" -> {:ok, fb} end)
      expect(FeedbackStoreMock, :guardar_feedback, fn f -> f end)
      expect(BroadcastServiceMock, :notificar, fn :feedback_actualizado, _ -> :ok end)

      {:ok, actualizado} = MentorManager.actualizar_estado_feedback("f1", "revisado")
      assert actualizado.estado == "revisado"
    end
  end

  describe "cambiar_visibilidad_feedback/2" do
    test "modifica la visibilidad correctamente" do
      fb = %{id: "f2", visibilidad: "privado"}
      expect(FeedbackStoreMock, :obtener_feedback, fn "f2" -> {:ok, fb} end)
      expect(FeedbackStoreMock, :guardar_feedback, fn f -> f end)
      expect(BroadcastServiceMock, :notificar, fn :feedback_visibilidad_cambiada, _ -> :ok end)

      {:ok, actualizado} = MentorManager.cambiar_visibilidad_feedback("f2", "público")
      assert actualizado.visibilidad == "público"
    end
  end

  # ============================================================
  # CANAL Y MENSAJES
  # ============================================================

  describe "asignar_canal/2" do
    test "asigna correctamente un canal al mentor" do
      mentor = %{id: "m1", canal_mentoria_id: nil}
      expect(MentorStoreMock, :obtener_por_id, fn "m1" -> mentor end)
      expect(MentorStoreMock, :guardar_mentor, fn m -> m end)
      expect(BroadcastServiceMock, :notificar, fn :canal_asignado_mentor, _ -> :ok end)

      {:ok, resultado} = MentorManager.asignar_canal("m1", "canal-99")
      assert resultado.canal_mentoria_id == "canal-99"
    end
  end

  describe "enviar_mensaje_general/2" do
    test "envía mensajes a todos los equipos asignados" do
      mentor = %{id: "m1", nombre: "Carlos", equipos_asignados: ["e1", "e2"]}
      expect(MentorStoreMock, :obtener_por_id, fn "m1" -> mentor end)
      expect(BroadcastServiceMock, :notificar, 2, fn :mensaje_mentor, _ -> :ok end)

      {:ok, :mensajes_enviados} = MentorManager.enviar_mensaje_general("m1", "Revisen el avance")
    end
  end
end

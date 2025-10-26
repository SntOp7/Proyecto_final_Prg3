defmodule ProyectoFinalPrg3.Test.Services.BroadcastServiceTest do
  use ExUnit.Case, async: true
  import Mox

  alias ProyectoFinalPrg3.Services.BroadcastService

  @moduledoc """
  Pruebas unitarias para `BroadcastService`.

  Se valida:
    - Difusión de eventos generales (`notificar/3`)
    - Envío directo (`enviar_directo/3`)
    - Difusión grupal (`notificar_grupo/3`)
    - Subscripción y cancelación (`suscribirse/2`, `cancelar_suscripcion/2`)
    - Registro de eventos de proyecto (`registrar_evento_proyecto/3`)
    - Notificación de errores (`notificar_error/2`)
    - Manejo de errores interno (`safe_broadcast/1`)

  Todos los adaptadores externos son simulados mediante `Mox` para aislar el servicio.
  """

  setup :verify_on_exit!

  setup do
    # Configuración de mocks simulados
    Application.put_env(:proyecto_final_prg3, :pubsub_adapter, self())
    Application.put_env(:proyecto_final_prg3, :channel_manager, self())
    Application.put_env(:proyecto_final_prg3, :node_manager, self())
    Application.put_env(:proyecto_final_prg3, :logger_service, self())
    :ok
  end

  # ============================================================
  # NOTIFICACIONES GENERALES
  # ============================================================

  describe "notificar/3" do
    test "difunde correctamente un evento general" do
      expect(LoggerServiceMock, :registrar_evento, fn _, _ -> :ok end)
      expect(PubSubAdapterMock, :publicar, fn :proyecto_creado, _ -> :ok end)
      expect(ChannelManagerMock, :broadcast, fn :proyecto_creado, _ -> :ok end)
      expect(NodeManagerMock, :enviar_a_nodos, fn :proyecto_creado, _ -> :ok end)

      {:ok, msg} =
        BroadcastService.notificar(:proyecto_creado, %{nombre: "SmartHub", categoria: "IA"}, :info)

      assert msg.tipo == :info
      assert msg.evento == :proyecto_creado
      assert is_map(msg.contenido)
      assert msg.contenido.nombre == "SmartHub"
    end
  end

  # ============================================================
  # MENSAJES DIRECTOS Y GRUPALES
  # ============================================================

  describe "enviar_directo/3" do
    test "envía un mensaje directo correctamente" do
      expect(LoggerServiceMock, :registrar_evento, fn _, _ -> :ok end)
      expect(ChannelManagerMock, :enviar, fn "canal1", _ -> :ok end)
      expect(NodeManagerMock, :enviar_directo, fn "canal1", _ -> :ok end)

      {:ok, payload} = BroadcastService.enviar_directo("canal1", %{msg: "hola"}, :directo)

      assert payload.tipo == :directo
      assert payload.destino == "canal1"
      assert is_map(payload.contenido)
      assert is_binary(payload.nodo)
    end
  end

  describe "notificar_grupo/3" do
    test "envía notificaciones a múltiples destinos" do
      expect(LoggerServiceMock, :registrar_evento, fn _, _ -> :ok end)
      expect(ChannelManagerMock, :enviar, 3, fn _, _ -> :ok end)
      expect(NodeManagerMock, :enviar_directo, 3, fn _, _ -> :ok end)

      :ok =
        BroadcastService.notificar_grupo(
          :actualizacion,
          ["canal1", "canal2", "canal3"],
          %{data: "Nuevo avance"}
        )

      assert_received {:ok, _}
    end
  end

  # ============================================================
  # SUSCRIPCIÓN Y CANCELACIÓN
  # ============================================================

  describe "suscribirse/2 y cancelar_suscripcion/2" do
    test "permite suscribir y cancelar eventos" do
      expect(PubSubAdapterMock, :suscribir, fn :evento_test, _pid -> :ok end)
      expect(PubSubAdapterMock, :desuscribir, fn :evento_test, _pid -> :ok end)
      expect(LoggerServiceMock, :registrar_evento, 2, fn _, _ -> :ok end)

      {:ok, :suscrito} = BroadcastService.suscribirse(:evento_test)
      {:ok, :cancelado} = BroadcastService.cancelar_suscripcion(:evento_test)
    end
  end

  # ============================================================
  # TRAZABILIDAD Y ERRORES
  # ============================================================

  describe "registrar_evento_proyecto/3" do
    test "registra y difunde un evento de proyecto" do
      expect(LoggerServiceMock, :registrar_evento, fn _, _ -> :ok end)
      expect(PubSubAdapterMock, :publicar, fn :evento_proyecto, _ -> :ok end)
      expect(ChannelManagerMock, :broadcast, fn :evento_proyecto, _ -> :ok end)

      {:ok, msg} =
        BroadcastService.registrar_evento_proyecto(:avance_creado, "EcoTech", %{avance: 1, estado: "ok"})

      assert msg.tipo == :proyecto
      assert msg.evento == :avance_creado
      assert msg.contenido.proyecto == "EcoTech"
    end
  end

  describe "notificar_error/2" do
    test "registra un error y devuelve estructura de mensaje con :error" do
      expect(LoggerServiceMock, :registrar_evento, fn _, _ -> :ok end)
      expect(PubSubAdapterMock, :publicar, fn :error_sistema, _ -> :ok end)
      expect(ChannelManagerMock, :broadcast, fn :error_sistema, _ -> :ok end)

      {:error, msg} = BroadcastService.notificar_error("ProjectManager", "Fallo de actualización")

      assert msg.tipo == :error
      assert msg.evento == :error_sistema
      assert msg.contenido.detalle == "Fallo de actualización"
    end
  end

  # ============================================================
  # MANEJO DE ERRORES INTERNO
  # ============================================================

  describe "safe_broadcast/1 (implícito)" do
    test "captura errores durante la difusión" do
      expect(LoggerServiceMock, :registrar_evento, fn _, _ -> :ok end)
      expect(PubSubAdapterMock, :publicar, fn _, _ -> raise "Error simulado" end)

      result = BroadcastService.notificar(:test_fallo, %{info: "x"}, :warn)
      assert match?({:ok, _} | {:error, _}, result)
    end
  end
end

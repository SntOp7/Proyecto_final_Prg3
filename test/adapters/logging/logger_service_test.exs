defmodule ProyectoFinalPrg3.Adapters.Logging.LoggerServiceTest do
  use ExUnit.Case, async: false
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  @tmp_dir "tmp/test_logs"
  @log_file Path.join(@tmp_dir, "event_log.csv")

  setup do
    File.rm_rf!(@tmp_dir)
    File.mkdir_p!(@tmp_dir)
    # Sobrescribimos el directorio global de logs para que use el temporal
    put_in(LoggerService.module_info(:attributes)[:log_dir], @tmp_dir)
    on_exit(fn -> File.rm_rf!(@tmp_dir) end)
    :ok
  end

  describe "registrar_evento/2" do
    test "crea el archivo CSV y registra un evento correctamente" do
      File.cd!(@tmp_dir, fn ->
        :ok = LoggerService.registrar_evento("Sistema iniciado", %{user: "admin"})
        assert File.exists?("logs/event_log.csv")

        contenido = File.read!("logs/event_log.csv")
        assert contenido =~ "Sistema iniciado"
        assert contenido =~ "admin"
        assert contenido =~ "info"
      end)
    end

    test "detecta tipo de evento automáticamente (error)" do
      File.cd!(@tmp_dir, fn ->
        :ok = LoggerService.registrar_evento("Error al iniciar servicio", %{})
        contenido = File.read!("logs/event_log.csv")
        assert contenido =~ "error"
      end)
    end

    test "detecta tipo de evento automáticamente (warning)" do
      File.cd!(@tmp_dir, fn ->
        :ok = LoggerService.registrar_evento("Advertencia de seguridad", %{})
        contenido = File.read!("logs/event_log.csv")
        assert contenido =~ "warning"
      end)
    end

    test "detecta tipo info por defecto" do
      File.cd!(@tmp_dir, fn ->
        :ok = LoggerService.registrar_evento("Proceso completado", %{})
        contenido = File.read!("logs/event_log.csv")
        assert contenido =~ "info"
      end)
    end
  end

  describe "obtener_eventos_recientes/1" do
    test "devuelve una lista vacía si el log no existe" do
      File.rm_rf!(@tmp_dir)
      assert LoggerService.obtener_eventos_recientes() == []
    end

    test "devuelve los últimos eventos registrados en CSV" do
      File.cd!(@tmp_dir, fn ->
        :ok = LoggerService.registrar_evento("Evento A", %{})
        :ok = LoggerService.registrar_evento("Evento B", %{})
        eventos = LoggerService.obtener_eventos_recientes(2)
        assert length(eventos) >= 1
        assert is_list(eventos)
      end)
    end
  end

  describe "limpiar_logs/0" do
    test "elimina y reinicia el archivo de logs" do
      File.cd!(@tmp_dir, fn ->
        :ok = LoggerService.registrar_evento("Evento temporal", %{})
        assert File.exists?("logs/event_log.csv")

        :ok = LoggerService.limpiar_logs()
        assert File.exists?("logs/event_log.csv")

        contenido = File.read!("logs/event_log.csv")
        assert contenido =~ "id,timestamp,nodo,tipo,mensaje,datos"
        assert not (contenido =~ "Evento temporal")
      end)
    end
  end

  describe "formato de CSV" do
    test "escapa correctamente caracteres especiales" do
      File.cd!(@tmp_dir, fn ->
        :ok = LoggerService.registrar_evento("Mensaje con \"comillas\"", %{clave: "valor"})
        contenido = File.read!("logs/event_log.csv")
        assert contenido =~ "Mensaje con 'comillas'"
      end)
    end
  end
end

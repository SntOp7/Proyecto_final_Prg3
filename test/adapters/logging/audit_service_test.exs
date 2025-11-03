defmodule ProyectoFinalPrg3.Adapters.Logging.AuditServiceTest do
  use ExUnit.Case, async: false
  alias ProyectoFinalPrg3.Adapters.Logging.AuditService

  @tmp_dir "tmp/test_logs"
  @csv_file Path.join(@tmp_dir, "event_log.csv")

  setup do
    File.rm_rf!(@tmp_dir)
    File.mkdir_p!(@tmp_dir)

    contenido = """
    id,timestamp,nodo,tipo,mensaje,datos
    1,2025-10-25T12:00:00Z,node1,info,Inicio del sistema,OK
    2,2025-10-25T13:00:00Z,node1,warning,Memoria alta,Uso 90%
    3,2025-10-26T14:00:00Z,node2,error,Fallo de conexión,Timeout
    4,2025-10-27T10:00:00Z,node3,info,Proceso completado,Finalizado
    """

    File.write!(@csv_file, contenido)

    # Reasignamos la ruta del log original a la temporal
    Application.put_env(:proyecto_final_prg3, :audit_log_path, @csv_file)

    on_exit(fn -> File.rm_rf!(@tmp_dir) end)

    :ok
  end

  describe "obtener_todos/0" do
    test "lee correctamente todos los eventos del CSV" do
      allow_file(@csv_file, fn ->
        eventos = AuditService.obtener_todos()
        assert length(eventos) == 4
        assert Enum.any?(eventos, &(&1.tipo == :warning))
        assert Enum.any?(eventos, &(&1.mensaje =~ "Fallo"))
      end)
    end

    test "retorna lista vacía si el archivo no existe" do
      File.rm!(@csv_file)
      assert AuditService.obtener_todos() == []
    end
  end

  describe "filtrar_por_tipo/1" do
    test "devuelve solo los eventos del tipo especificado" do
      eventos = AuditService.filtrar_por_tipo(:error)
      assert length(eventos) == 1
      assert hd(eventos).tipo == :error
    end
  end

  describe "filtrar_por_nodo/1" do
    test "devuelve solo eventos del nodo solicitado" do
      eventos = AuditService.filtrar_por_nodo("node1")
      assert Enum.all?(eventos, &(&1.nodo == "node1"))
      assert length(eventos) == 2
    end
  end

  describe "filtrar_por_rango/2" do
    test "filtra correctamente eventos dentro del rango válido" do
      eventos =
        AuditService.filtrar_por_rango("2025-10-25T12:30:00Z", "2025-10-26T20:00:00Z")

      assert length(eventos) == 2
      assert Enum.all?(eventos, &(&1.tipo in [:warning, :error]))
    end

    test "devuelve error si las fechas son inválidas" do
      assert {:error, :fechas_invalidas} = AuditService.filtrar_por_rango("no-date", "otra")
    end
  end

  describe "buscar_por_texto/1" do
    test "encuentra eventos que contienen el texto en mensaje o datos" do
      resultados = AuditService.buscar_por_texto("Fallo")
      assert length(resultados) == 1
      assert hd(resultados).mensaje =~ "Fallo"
    end

    test "busca coincidencias también en el campo datos" do
      resultados = AuditService.buscar_por_texto("OK")
      assert length(resultados) == 1
      assert hd(resultados).datos == "OK"
    end
  end

  describe "exportar_a_json/1" do
    test "genera correctamente el archivo JSON con los logs" do
      destino = Path.join(@tmp_dir, "export.json")
      {:ok, archivo} = AuditService.exportar_a_json(destino)
      assert File.exists?(archivo)
      contenido = File.read!(archivo)
      assert contenido =~ "Inicio del sistema"
      assert contenido =~ "\"tipo\": \"info\""
    end
  end

  describe "exportar_a_txt/1" do
    test "genera un archivo de texto legible con los eventos" do
      destino = Path.join(@tmp_dir, "export.txt")
      {:ok, archivo} = AuditService.exportar_a_txt(destino)
      assert File.exists?(archivo)
      contenido = File.read!(archivo)
      assert contenido =~ "Nodo: node1"
      assert contenido =~ "------------------------------"
    end
  end

  defp allow_file(_path, fun), do: fun.()
end

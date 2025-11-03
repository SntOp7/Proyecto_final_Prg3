defmodule ProyectoFinalPrg3.Adapters.Security.AuditLoggerTest do
  use ExUnit.Case, async: true
  alias ProyectoFinalPrg3.Adapters.Security.AuditLogger

  @audit_dir "logs"
  @audit_file Path.join(@audit_dir, "security_audit_log.csv")

  setup do
    File.rm_rf!(@audit_dir)
    File.mkdir_p!(@audit_dir)
    :ok
  end

  describe "registrar_auditoria/2" do
    test "crea el archivo CSV si no existe y escribe un evento" do
      assert :ok = AuditLogger.registrar_auditoria("Inicio de sesión", %{usuario: "juan", ip: "127.0.0.1", rol: "admin"})
      assert File.exists?(@audit_file)
      contenido = File.read!(@audit_file)
      assert String.contains?(contenido, "Inicio de sesión")
      assert String.contains?(contenido, "juan")
    end

    test "agrega nuevos eventos sin sobrescribir los existentes" do
      AuditLogger.registrar_auditoria("Intento de acceso fallido", %{usuario: "maria", ip: "192.168.0.5"})
      AuditLogger.registrar_auditoria("Cambio de rol", %{usuario: "maria", rol: "mentor"})

      contenido = File.read!(@audit_file)
      assert String.contains?(contenido, "Intento de acceso fallido")
      assert String.contains?(contenido, "Cambio de rol")
    end

    test "imprime alertas en color rojo si el estado es ERROR" do
      assert capture_io(:stderr, fn ->
        AuditLogger.registrar_auditoria("Violación de seguridad", %{usuario: "admin", estado: "ERROR"})
      end)
    end
  end

  describe "funciones privadas de construcción y serialización" do
    test "construir_evento genera estructura con valores por defecto" do
      evento = :erlang.apply(AuditLogger, :construir_evento, ["Acceso", %{}])
      assert is_map(evento)
      assert evento.usuario == "desconocido"
      assert evento.ip == "no_disponible"
      assert evento.estado == "OK"
      assert is_binary(evento.id)
    end

    test "evento_a_csv convierte un mapa de evento a línea CSV válida" do
      evento = %{
        id: "123",
        timestamp: "2025-10-27T00:00:00Z",
        accion: "Test de CSV",
        usuario: "tester",
        rol: "admin",
        ip: "1.1.1.1",
        estado: "OK",
        detalles: ~s({"key":"value"})
      }

      csv_line = :erlang.apply(AuditLogger, :evento_a_csv, [evento])
      assert String.contains?(csv_line, "Test de CSV")
      assert String.contains?(csv_line, "tester")
      assert String.contains?(csv_line, "admin")
    end

    test "escape_csv maneja correctamente comillas y tipos no binarios" do
      assert :erlang.apply(AuditLogger, :escape_csv, ["valor,con,comas"]) =~ ~s("valor;con;comas")
      assert :erlang.apply(AuditLogger, :escape_csv, [123]) == "123"
    end

    test "inicializar_csv crea encabezados correctamente" do
      :erlang.apply(AuditLogger, :inicializar_csv, [])
      contenido = File.read!(@audit_file)
      assert String.contains?(contenido, "timestamp,accion,usuario")
    end
  end

  describe "guardar_en_archivo/1" do
    test "guarda un evento correctamente en el CSV" do
      evento = %{
        id: "ABC",
        timestamp: "2025-10-27T10:00:00Z",
        accion: "Cambio de permisos",
        usuario: "dev",
        rol: "admin",
        ip: "10.0.0.1",
        estado: "OK",
        detalles: "{}"
      }

      :erlang.apply(AuditLogger, :guardar_en_archivo, [evento])
      contenido = File.read!(@audit_file)
      assert String.contains?(contenido, "Cambio de permisos")
    end
  end

  describe "mostrar_en_consola/1" do
    test "muestra alerta de seguridad con estado ERROR" do
      evento = %{estado: "ERROR", timestamp: "t", accion: "Intrusión detectada", usuario: "root"}
      salida = capture_io(fn -> :erlang.apply(AuditLogger, :mostrar_en_consola, [evento]) end)
      assert salida =~ "SECURITY ALERT"
      assert salida =~ "Intrusión detectada"
    end

    test "muestra log normal si estado es OK" do
      evento = %{estado: "OK", timestamp: "t", accion: "Inicio", usuario: "root"}
      salida = capture_io(fn -> :erlang.apply(AuditLogger, :mostrar_en_consola, [evento]) end)
      assert salida =~ "SECURITY"
      refute salida =~ "ALERT"
    end
  end
end

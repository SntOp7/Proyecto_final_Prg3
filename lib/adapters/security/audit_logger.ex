defmodule ProyectoFinalPrg3.Adapters.Security.AuditLogger do
  @moduledoc """
  Módulo especializado en la **auditoría de seguridad** del sistema.

  A diferencia de `LoggerService`, este componente se centra en **eventos críticos**
  relacionados con la seguridad, como:
  - Autenticación (inicios y cierres de sesión).
  - Intentos de acceso no autorizado.
  - Cambios de permisos o roles.
  - Modificaciones administrativas.

  Los eventos se registran en un archivo separado (`security_audit_log.csv`)
  para mantener una trazabilidad segura y aislada.

  ## Integraciones:
  - `AuthService` → registra inicios y cierres de sesión.
  - `PermissionAdapter` → registra cambios de roles o violaciones de acceso.
  - `SessionManager` → registra sesiones revocadas o expiradas.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha: 2025-10-27
  Licencia: GNU GPLv3
  """

  @audit_dir "logs"
  @audit_file "#{@audit_dir}/security_audit_log.csv"

  @doc """
  Registra un evento de auditoría de seguridad.

  ## Parámetros:
    - `accion`: descripción de la acción o evento crítico.
    - `detalles`: mapa con información adicional (usuario, IP, rol, etc.)
  """
  def registrar_auditoria(accion, detalles \\ %{}) when is_binary(accion) do
    evento = construir_evento(accion, detalles)
    guardar_en_archivo(evento)
    mostrar_en_consola(evento)
    :ok
  end

  # ============================================================
  # FUNCIONES PRIVADAS
  # ============================================================

  defp construir_evento(accion, detalles) do
    %{
      id: UUID.uuid4(),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      accion: accion,
      usuario: Map.get(detalles, :usuario, "desconocido"),
      ip: Map.get(detalles, :ip, "no_disponible"),
      rol: Map.get(detalles, :rol, "no_definido"),
      estado: Map.get(detalles, :estado, "OK"),
      detalles: Jason.encode!(detalles)
    }
  end

  defp guardar_en_archivo(evento) do
    File.mkdir_p!(@audit_dir)
    unless File.exists?(@audit_file), do: inicializar_csv()

    File.open!(@audit_file, [:append], fn file ->
      IO.write(file, evento_a_csv(evento))
    end)
  end

  defp mostrar_en_consola(%{estado: "ERROR"} = e),
    do: IO.puts(:red, "[SECURITY ALERT] #{e.timestamp} | #{e.accion} | Usuario: #{e.usuario}")

  defp mostrar_en_consola(e),
    do: IO.puts(:magenta, "[SECURITY] #{e.timestamp} | #{e.accion} | Usuario: #{e.usuario}")

  defp inicializar_csv do
    encabezados = ["id", "timestamp", "accion", "usuario", "rol", "ip", "estado", "detalles"]
    File.write!(@audit_file, Enum.join(encabezados, ",") <> "\n")
  end

  defp evento_a_csv(e) do
    Enum.join(
      [
        e.id,
        e.timestamp,
        e.accion,
        e.usuario,
        e.rol,
        e.ip,
        e.estado,
        escape_csv(e.detalles)
      ],
      ","
    ) <> "\n"
  end

  defp escape_csv(v) when is_binary(v) do
    escaped = String.replace(v, "\"", "'")
    "\"#{escaped}\""
  end
end

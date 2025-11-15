defmodule ProyectoFinalPrg3.Adapters.Logging.LoggerService do
  @moduledoc """
  Servicio central de **logging** del sistema de hackathon colaborativa.

  Este módulo actúa como punto unificado para registrar eventos de operación,
  notificaciones del sistema, acciones de usuarios y trazas generales.

  **No registra eventos de seguridad crítica**, los cuales se manejan
  desde `ProyectoFinalPrg3.Adapters.Security.AuditLogger`.

  ## Funcionalidades principales:
  - Registrar eventos con distintos niveles (`:info`, `:warning`, `:error`).
  - Guardar logs persistentes en formato CSV.
  - Mostrar eventos relevantes en la consola.
  - Servir como fuente para el `AuditService`.

  ## Ejemplo de uso:
      iex> LoggerService.registrar_evento("Proyecto creado", %{proyecto: "SmartHub"})
      :ok

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha: 2025-10-27
  Licencia: GNU GPLv3
  """

  @log_dir "logs"
  @log_file "#{@log_dir}/event_log.csv"

  # ============================================================
  # API PÚBLICA
  # ============================================================

  @doc """
  Registra un evento general con su mensaje y datos asociados.
  """
  def registrar_evento(mensaje, data \\ %{}) when is_binary(mensaje) do
    evento = construir_evento(mensaje, data)
    guardar_en_archivo(evento)
    mostrar_en_consola(evento)
    :ok
  end

  @doc """
  Obtiene los últimos `N` eventos registrados (por defecto 20).
  """
  def obtener_eventos_recientes(limite \\ 20) do
    if File.exists?(@log_file) do
      @log_file
      |> File.stream!()
      |> Stream.drop(1)
      |> CSV.decode!(headers: true)
      |> Enum.take(-limite)
    else
      []
    end
  end

  @doc """
  Limpia los logs del sistema.
  """
  def limpiar_logs do
    File.rm(@log_file)
    File.mkdir_p!(@log_dir)
    inicializar_csv()
    :ok
  end

  # ============================================================
  # FUNCIONES PRIVADAS
  # ============================================================

  defp construir_evento(mensaje, data) do
    %{
      id: UUID.uuid4(),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      nodo: Atom.to_string(Node.self()),
      mensaje: mensaje,
      tipo: Map.get(data, :tipo, inferir_tipo(mensaje)),
      datos: Jason.encode!(data)
    }
  end

  defp guardar_en_archivo(evento) do
    File.mkdir_p!(@log_dir)
    unless File.exists?(@log_file), do: inicializar_csv()

    File.open!(@log_file, [:append], fn file ->
      IO.write(file, evento_a_csv(evento))
    end)
  end

  defp mostrar_en_consola(%{tipo: :error} = e) do
    IO.puts(IO.ANSI.red() <> "[ERROR] #{e.timestamp} | #{e.mensaje}" <> IO.ANSI.reset())
  end

  defp mostrar_en_consola(%{tipo: :warning} = e) do
    IO.puts(IO.ANSI.yellow() <> "[WARN] #{e.timestamp} | #{e.mensaje}" <> IO.ANSI.reset())
  end

  defp mostrar_en_consola(e) do
    IO.puts(IO.ANSI.cyan() <> "[INFO] #{e.timestamp} | #{e.mensaje}" <> IO.ANSI.reset())
  end

  defp inicializar_csv do
    encabezados = ["id", "timestamp", "nodo", "tipo", "mensaje", "datos"]
    File.write!(@log_file, Enum.join(encabezados, ",") <> "\n")
  end

  defp evento_a_csv(e) do
    ([e.id, e.timestamp, e.nodo, to_string(e.tipo), escape_csv(e.mensaje), escape_csv(e.datos)]
     |> Enum.join(",")) <>
      "\n"
  end

  defp escape_csv(v) when is_binary(v) do
    escaped = String.replace(v, "\"", "'")
    "\"#{escaped}\""
  end

  defp inferir_tipo(msg) do
    cond do
      String.contains?(msg, ["error", "fallo", "excepción"]) -> :error
      String.contains?(msg, ["advertencia", "alerta"]) -> :warning
      true -> :info
    end
  end

  # ============================================================
  # INTEGRACIÓN CON SUPERVISIÓN
  # ============================================================

  @doc """
  Registra este servicio dentro del `SupervisionManager` para monitoreo continuo.
  """
  def registrar_supervision do
    ProyectoFinalPrg3.Services.SupervisionService.registrar_proceso(:logger_service, __MODULE__)
  end

  @doc """
  Verifica que el servicio de logging esté activo.
  """
  def inicializar_supervision do
    File.mkdir_p!("logs")
    registrar_evento("LoggerService inicializado", %{estado: :ok})
    :ok
  end
end

defmodule ProyectoFinalPrg3.Adapters.Logging.LoggerService do
  @moduledoc """
  Servicio responsable del registro y auditoría de eventos dentro del sistema.
  Actúa como capa de logging central para todos los servicios, registrando
  eventos en consola y en archivos CSV o TXT.

  Se integra principalmente con `BroadcastService` y con los servicios de dominio
  (`TeamManager`, `ProjectManager`, `MentorManager`, etc.) para dejar trazabilidad
  de cada acción o notificación.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-27
  Licencia: GNU GPLv3
  """

  @log_dir "logs"
  @log_file "#{@log_dir}/event_log.csv"

  # ============================================================
  # API PÚBLICA
  # ============================================================

  @doc """
  Registra un evento con un mensaje descriptivo y un conjunto de datos asociados.

  ## Ejemplo:
      LoggerService.registrar_evento("Proyecto creado", %{proyecto: "SmartHub", categoria: "IA"})
  """
  def registrar_evento(mensaje, data \\ %{}) when is_binary(mensaje) do
    evento = construir_evento(mensaje, data)
    guardar_en_archivo(evento)
    mostrar_en_consola(evento)
    :ok
  end

  @doc """
  Obtiene los últimos N eventos registrados desde el archivo.
  """
  def obtener_eventos_recientes(limite \\ 20) do
    if File.exists?(@log_file) do
      @log_file
      |> File.stream!()
      |> Stream.drop(1) # Omitir encabezado
      |> CSV.decode!(headers: true)
      |> Enum.take(-limite)
    else
      []
    end
  end

  @doc """
  Limpia el archivo de logs (por mantenimiento o reinicio del sistema).
  """
  def limpiar_logs do
    File.rm(@log_file)
    File.mkdir_p!(@log_dir)
    inicializar_csv()
    :ok
  end

  # ============================================================
  # FUNCIONES PRIVADAS DE REGISTRO
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

    unless File.exists?(@log_file) do
      inicializar_csv()
    end

    File.open!(@log_file, [:append], fn file ->
      IO.write(file, evento_a_csv(evento))
    end)
  end

  defp mostrar_en_consola(%{tipo: :error} = evento) do
    IO.puts(:red, "[ERROR] #{evento.timestamp} | #{evento.mensaje}")
  end

  defp mostrar_en_consola(%{tipo: :warning} = evento) do
    IO.puts(:yellow, "[WARN] #{evento.timestamp} | #{evento.mensaje}")
  end

  defp mostrar_en_consola(evento) do
    IO.puts(:cyan, "[INFO] #{evento.timestamp} | #{evento.mensaje}")
  end

  defp inicializar_csv do
    encabezados = ["id", "timestamp", "nodo", "tipo", "mensaje", "datos"]

    File.open!(@log_file, [:write], fn file ->
      IO.write(file, Enum.join(encabezados, ",") <> "\n")
    end)
  end

  defp evento_a_csv(evento) do
    [
      evento.id,
      evento.timestamp,
      evento.nodo,
      to_string(evento.tipo),
      escape_csv(evento.mensaje),
      escape_csv(evento.datos)
    ]
    |> Enum.join(",")
    |> Kernel.<>("\n")
  end

  defp escape_csv(nil), do: ""
  defp escape_csv(value) when is_binary(value),
    do: "\"" <> String.replace(value, "\"", "'") <> "\""
  defp escape_csv(value), do: to_string(value)

  defp inferir_tipo(mensaje) do
    cond do
      String.contains?(mensaje, ["error", "fallo", "excepción"]) -> :error
      String.contains?(mensaje, ["advertencia", "alerta"]) -> :warning
      true -> :info
    end
  end
end

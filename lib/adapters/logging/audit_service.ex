defmodule ProyectoFinalPrg3.Adapters.Logging.AuditService do
  @moduledoc """
  Servicio de auditoría del sistema de hackathon.
  Permite consultar, filtrar y exportar los registros generados por `LoggerService`.

  Este módulo es parte de la capa de adaptadores (`adapters/logging`) y se usa
  principalmente para:
    - Consultar eventos por tipo, rango de fechas o nodo.
    - Exportar logs a distintos formatos (CSV, JSON, TXT).
    - Generar reportes de actividad para mentores, equipos o proyectos.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService
  @log_file "logs/event_log.csv"

  # ============================================================
  # CONSULTA Y FILTRADO
  # ============================================================

  @doc """
  Obtiene todos los eventos del log en formato de lista de mapas.
  """
  def obtener_todos do
    if File.exists?(@log_file) do
      @log_file
      |> File.stream!()
      |> Stream.drop(1)
      |> CSV.decode!(headers: true)
      |> Enum.map(&parsear_evento/1)
    else
      []
    end
  end

  @doc """
  Filtra eventos por tipo (:info, :warning, :error, :proyecto, etc.)
  """
  def filtrar_por_tipo(tipo) do
    obtener_todos()
    |> Enum.filter(&(&1.tipo == tipo))
  end

  @doc """
  Filtra eventos ocurridos dentro de un rango de fechas ISO8601.
  """
  def filtrar_por_rango(fecha_inicio, fecha_fin) do
    with {:ok, fi, _} <- DateTime.from_iso8601(fecha_inicio),
         {:ok, ff, _} <- DateTime.from_iso8601(fecha_fin) do
      obtener_todos()
      |> Enum.filter(fn evento ->
        case DateTime.from_iso8601(evento.timestamp) do
          {:ok, fecha_evento, _} ->
            DateTime.compare(fecha_evento, fi) != :lt and DateTime.compare(fecha_evento, ff) != :gt
          _ ->
            false
        end
      end)
    else
      _ -> {:error, :fechas_invalidas}
    end
  end

  @doc """
  Busca eventos que contengan un texto o palabra clave en el mensaje o los datos.
  """
  def buscar_por_texto(texto) do
    obtener_todos()
    |> Enum.filter(fn evento ->
      String.contains?(evento.mensaje, texto) or String.contains?(evento.datos, texto)
    end)
  end

  @doc """
  Obtiene todos los eventos registrados por un nodo específico.
  """
  def filtrar_por_nodo(nombre_nodo) do
    obtener_todos()
    |> Enum.filter(&(&1.nodo == nombre_nodo))
  end

  # ============================================================
  # EXPORTACIÓN DE LOGS
  # ============================================================

  @doc """
  Exporta los registros actuales a un archivo en formato JSON.
  """
  def exportar_a_json(destino \\ "logs/audit_export.json") do
    eventos = obtener_todos()
    File.mkdir_p!("logs")
    File.write!(destino, Jason.encode_pretty!(eventos, indent: 2))
    {:ok, destino}
  end

  @doc """
  Exporta los registros actuales a un archivo en formato TXT legible.
  """
  def exportar_a_txt(destino \\ "logs/audit_export.txt") do
    eventos = obtener_todos()

    contenido =
      eventos
      |> Enum.map(fn e ->
        """
        [#{e.timestamp}] (#{e.tipo}) #{e.mensaje}
        Nodo: #{e.nodo}
        Datos: #{e.datos}
        ------------------------------
        """
      end)
      |> Enum.join("\n")

    File.mkdir_p!("logs")
    File.write!(destino, contenido)
    {:ok, destino}
  end

  # ============================================================
  # FUNCIONES AUXILIARES
  # ============================================================

  defp parsear_evento(row) do
    %{
      id: row["id"],
      timestamp: row["timestamp"],
      nodo: row["nodo"],
      tipo: parse_atom(row["tipo"]),
      mensaje: row["mensaje"],
      datos: row["datos"]
    }
  end

  defp parse_atom(nil), do: :info
  defp parse_atom(""), do: :info
  defp parse_atom(str), do: String.to_atom(str)
end

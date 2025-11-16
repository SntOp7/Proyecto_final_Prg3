defmodule ProyectoFinalPrg3.Adapters.Logging.AuditService do
  @moduledoc """
  Servicio de auditoría del sistema.
  Analiza los eventos generados por LoggerService:

  - Obtiene todos los eventos
  - Filtra por tipo, rango, nodo
  - Busca por texto
  - Exporta resultados

  No registra eventos.
  """

  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  @log_file "logs/event_log.csv"

  # ============================================================
  # LECTURA PRINCIPAL
  # ============================================================

  def obtener_todos do
    if File.exists?(@log_file) do
      @log_file
      |> File.stream!()
      |> Stream.drop(1)
      |> Enum.map(&parse_csv_line/1)
      |> Enum.filter(&is_map/1)
    else
      []
    end
  end

  # ============================================================
  # FILTROS
  # ============================================================

  def filtrar_por_tipo(tipo),
    do: obtener_todos() |> Enum.filter(&(&1.tipo == tipo))

  def filtrar_por_nodo(nodo),
    do: obtener_todos() |> Enum.filter(&(&1.nodo == nodo))

  def buscar_por_texto(texto) do
    obtener_todos()
    |> Enum.filter(fn e ->
      String.contains?(e.mensaje, texto) ||
        Jason.encode!(e.datos) |> String.contains?(texto)
    end)
  end

  def filtrar_por_rango(fi_str, ff_str) do
    with {:ok, fi, _} <- DateTime.from_iso8601(fi_str),
         {:ok, ff, _} <- DateTime.from_iso8601(ff_str) do
      obtener_todos()
      |> Enum.filter(fn e ->
        with {:ok, fecha, _} <- DateTime.from_iso8601(e.timestamp) do
          DateTime.compare(fecha, fi) != :lt and
            DateTime.compare(fecha, ff) != :gt
        else
          _ -> false
        end
      end)
    else
      _ -> {:error, :fechas_invalidas}
    end
  end

  # ============================================================
  # EXPORTACIÓN
  # ============================================================

  def exportar_a_json(destino \\ "logs/audit_export.json") do
    eventos = obtener_todos()
    File.write!(destino, Jason.encode!(eventos, pretty: true))
    {:ok, destino}
  end

  def exportar_a_txt(destino \\ "logs/audit_export.txt") do
    contenido =
      obtener_todos()
      |> Enum.map(fn e ->
        """
        [#{e.timestamp}] #{e.tipo} | #{e.mensaje}
        Nodo: #{e.nodo}
        Datos: #{Jason.encode!(e.datos)}
        """
      end)
      |> Enum.join("\n\n")

    File.write!(destino, contenido)
    {:ok, destino}
  end
end

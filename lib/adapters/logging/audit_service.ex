defmodule ProyectoFinalPrg3.Adapters.Logging.AuditService do
  @moduledoc """
  Servicio de auditoría que analiza y exporta los registros
  generados por LoggerService desde logs/event_log.csv.
  """

  @log_file "logs/event_log.csv"

  # ============================================================
  # LECTURA PRINCIPAL DE EVENTOS
  # ============================================================

  @doc "Obtiene todos los eventos del sistema."
  def obtener_todos do
    unless File.exists?(@log_file) do
      []
    else
      @log_file
      |> File.stream!()
      |> Stream.drop(1)
      |> Enum.map(&parse_csv_line/1)
    end
  end

  # ============================================================
  # PARSEO ROBUSTO DE CSV (compatible con LoggerService)
  # ============================================================

  defp parse_csv_line(linea) do
    campos =
      Regex.scan(~r/"([^"]*)"|([^,]+)/, linea)
      |> Enum.map(fn
        [_, quoted, _] when quoted != nil -> quoted
        [_, _, unquoted]                  -> unquoted
      end)

    [id, timestamp, nodo, tipo, mensaje, datos_json] = campos

    datos =
      case Jason.decode(datos_json) do
        {:ok, mapa} -> mapa
        _ -> %{}
      end

    %{
      id: id,
      timestamp: timestamp,
      nodo: nodo,
      tipo: safe_atom(tipo),
      mensaje: mensaje,
      datos: datos
    }
  end


  defp safe_atom(nil), do: :info
defp safe_atom(""), do: :info

defp safe_atom(str) when is_binary(str) do
  try do
    String.to_existing_atom(str)
  rescue
    _ -> :info
  end
end




  # ============================================================
  # FILTROS
  # ============================================================

  def filtrar_por_tipo(tipo),
    do: obtener_todos() |> Enum.filter(&(&1.tipo == tipo))

  def filtrar_por_rango(fi_str, ff_str) do
    with {:ok, fi, _} <- DateTime.from_iso8601(fi_str),
         {:ok, ff, _} <- DateTime.from_iso8601(ff_str) do

      obtener_todos()
      |> Enum.filter(fn evento ->
        case DateTime.from_iso8601(evento.timestamp) do
          {:ok, fecha, _} ->
            DateTime.compare(fecha, fi) != :lt and
            DateTime.compare(fecha, ff) != :gt

          _ -> false
        end
      end)

    else
      _ -> {:error, :fechas_invalidas}
    end
  end

  def buscar_por_texto(texto) do
    obtener_todos()
    |> Enum.filter(fn e ->
      String.contains?(e.mensaje, texto) or
        Jason.encode!(e.datos) |> String.contains?(texto)
    end)
  end

  def filtrar_por_nodo(nodo),
    do: obtener_todos() |> Enum.filter(&(&1.nodo == nodo))

  # ============================================================
  # EXPORTACIONES
  # ============================================================

  def exportar_a_json(destino \\ "logs/audit_export.json") do
    eventos = obtener_todos()
    File.mkdir_p!("logs")
    File.write!(destino, Jason.encode!(eventos, pretty: true))
    {:ok, destino}
  end

  def exportar_a_txt(destino \\ "logs/audit_export.txt") do
    eventos = obtener_todos()

    contenido =
      eventos
      |> Enum.map(fn e ->
        """
        [#{e.timestamp}] (#{e.tipo}) #{e.mensaje}
        Nodo: #{e.nodo}
        Datos: #{Jason.encode!(e.datos)}
        ----------------------------------------
        """
      end)
      |> Enum.join("\n")

    File.mkdir_p!("logs")
    File.write!(destino, contenido)
    {:ok, destino}
  end
end

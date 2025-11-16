defmodule ProyectoFinalPrg3.Adapters.Logging.AuditService do
  @moduledoc """
  Servicio de auditoría para leer, filtrar y exportar los registros
  generados en `logs/event_log.csv`.

  Autores: Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez
  Licencia: GNU GPLv3
  """

  @log_file "logs/event_log.csv"

  # ============================================================
  # LECTURA PRINCIPAL
  # ============================================================

  @doc "Retorna todos los eventos registrados en el archivo de logs."
  def obtener_todos do
    if File.exists?(@log_file) do
      @log_file
      |> File.stream!()
      |> Stream.drop(1)               # Saltar encabezado
      |> Enum.map(&parse_csv_line/1)  # Usar parser interno
      |> Enum.filter(&is_map/1)       # Filtrar líneas inválidas
    else
      []
    end
  end

  # ============================================================
  # PARSEO ROBUSTO (sin dependencias privadas)
  # ============================================================

  defp parse_csv_line(linea) do
  linea = String.trim(linea)

  # Ignorar líneas vacías o basura
  if linea == "" or linea == "," or linea == "\"\"" do
    :ignore
  else
    campos =
      Regex.scan(~r/"([^"]*)"|([^,]+)/, linea)
      |> Enum.map(fn
        [_, quoted, _] when quoted != nil -> quoted
        [_, _, normal] -> normal
        _ -> ""
      end)

    case campos do
      [id, timestamp, nodo, tipo, mensaje, datos_json] ->
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

      _ ->
        :ignore  # ya no imprime warnings feos
    end
  end
end


  defp safe_atom(nil), do: :info
  defp safe_atom(""), do: :info

  defp safe_atom(str) do
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

  def filtrar_por_nodo(nodo),
    do: obtener_todos() |> Enum.filter(&(&1.nodo == nodo))

  def buscar_por_texto(texto) do
    obtener_todos()
    |> Enum.filter(fn e ->
      String.contains?(e.mensaje, texto) or
        Jason.encode!(e.datos) |> String.contains?(texto)
    end)
  end

  def filtrar_por_rango(inicio, fin) do
    with {:ok, fi, _} <- DateTime.from_iso8601(inicio),
         {:ok, ff, _} <- DateTime.from_iso8601(fin) do
      obtener_todos()
      |> Enum.filter(fn evento ->
        case DateTime.from_iso8601(evento.timestamp) do
          {:ok, fecha, _} ->
            DateTime.compare(fecha, fi) != :lt and
              DateTime.compare(fecha, ff) != :gt

          _ ->
            false
        end
      end)
    else
      _ -> {:error, :fechas_invalidas}
    end
  end

  # ============================================================
  # EXPORTACIONES
  # ============================================================

  def exportar_a_json(destino \\ "logs/audit_export.json") do
    eventos =
      obtener_todos()
      |> Enum.filter(&is_map/1)

    File.mkdir_p!("logs")
    File.write!(destino, Jason.encode!(eventos, pretty: true))
    {:ok, destino}
  end

  def exportar_a_txt(destino \\ "logs/audit_export.txt") do
    eventos =
      obtener_todos()
      |> Enum.filter(&is_map/1)

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

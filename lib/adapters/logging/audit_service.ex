defmodule ProyectoFinalPrg3.Adapters.Logging.AuditService do
  @moduledoc """
  Servicio de auditoría para leer, filtrar y exportar los registros
  generados en `logs/event_log.csv`.

  Proporciona funcionalidades para:
    - Obtener todos los eventos registrados.
    - Filtrar eventos por tipo, nodo o texto.
    - Filtrar eventos dentro de un rango de fechas.
    - Exportar los eventos a formatos JSON o TXT.
  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  @log_file "logs/event_log.csv"

  # ============================================================
  # LECTURA PRINCIPAL
  # ============================================================

  @doc "Retorna todos los eventos registrados en el archivo de logs.
  Filtra líneas inválidas automáticamente.
  Parámetros: Ninguno.
  Retorna: Lista de mapas con los eventos.
  "
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

  @doc false
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
        :ignore
    end
  end
end

  @doc false
  defp safe_atom(nil), do: :info

  @doc false
  defp safe_atom(""), do: :info

  @doc false
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

  @doc"""
  Funciones para filtrar los eventos de auditoría por diferentes criterios.
  Cada función retorna una lista de eventos que cumplen con el criterio especificado.
  Parámetros:
    - `tipo`: Átomo que representa el tipo de evento (e.g., :info, :error).
    - `nodo`: String con el nombre del nodo.
    - `texto`: String con el texto a buscar en mensaje o datos.
    - `inicio`: String en formato ISO8601 para la fecha de inicio.
    - `fin`: String en formato ISO8601 para la fecha de fin.
  Retorna:
    - Lista de eventos filtrados según el criterio.
  """
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

  @doc """
  Funciones para exportar los eventos de auditoría a diferentes formatos.
  Parámetros:
    - `destino`: Ruta del archivo destino (opcional).
  Retorna:
    - `{:ok, destino}` con la ubicación del archivo exportado.

  """
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

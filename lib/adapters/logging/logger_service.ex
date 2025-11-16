defmodule ProyectoFinalPrg3.Adapters.Logging.LoggerService do
  @moduledoc """
  Servicio de logging central del sistema.

  - Registra eventos en logs/event_log.csv
  - Muestra en consola con colores
  - Exporta a JSON o TXT

  No realiza filtros ni análisis (eso es trabajo de AuditService).
  """

  @log_dir "logs"
  @log_file "#{@log_dir}/event_log.csv"

  # ============================================================
  # API PÚBLICA
  # ============================================================

  def registrar_evento(mensaje, data \\ %{}) do
    evento = construir_evento(mensaje, data)
    guardar_en_archivo(evento)
    mostrar_en_consola(evento)
    :ok
  end

  def obtener_eventos_recientes(limite \\ 20) do
    if File.exists?(@log_file) do
      @log_file
      |> File.stream!()
      |> Stream.drop(1)
      |> Enum.map(&parse_line/1)
      |> Enum.filter(&is_map/1)
      |> Enum.take(-limite)
    else
      []
    end
  end

  def limpiar_logs do
    File.rm(@log_file)
    File.mkdir_p!(@log_dir)
    inicializar_csv()
  end

  def exportar_a_json(ruta_salida) do
    eventos =
      obtener_eventos_recientes(99999)

    File.write!(ruta_salida, Jason.encode!(eventos, pretty: true))
    {:ok, ruta_salida}
  end

  def exportar_a_txt(ruta_salida) do
    contenido =
      obtener_eventos_recientes(99999)
      |> Enum.map(fn e ->
        "[#{e.timestamp}] (#{e.tipo}) #{e.mensaje} — #{Jason.encode!(e.datos)}"
      end)
      |> Enum.join("\n")

    File.write!(ruta_salida, contenido)
    {:ok, ruta_salida}
  end

  # ============================================================
  # PRIVADO
  # ============================================================

  defp construir_evento(mensaje, data) do
    %{
      id: UUID.uuid4(),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      nodo: Atom.to_string(Node.self()),
      tipo: Map.get(data, :tipo, inferir_tipo(mensaje)),
      mensaje: mensaje,
      datos: data
    }
  end

  defp guardar_en_archivo(evento) do
    File.mkdir_p!(@log_dir)
    unless File.exists?(@log_file), do: inicializar_csv()

    json =
      if is_binary(evento.datos),
        do: evento.datos,
        else: Jason.encode!(evento.datos)

    fila_vals = [
      evento.id,
      evento.timestamp,
      evento.nodo,
      evento.tipo,
      evento.mensaje,
      json
    ]

    linea =
      fila_vals
      |> Enum.map(&escape/1)
      |> Enum.join(",")

    linea = linea <> "\n"

    File.write!(@log_file, linea, [:append])
  end

  defp parse_line(linea) do
    campos =
      Regex.scan(~r/"([^"]*)"|([^,]+)/, linea)
      |> Enum.map(fn
        [_, quoted, _] when quoted != nil -> quoted
        [_, _, normal] -> normal
      end)

    case campos do
      [id, ts, nodo, tipo, msg, json] ->
        datos =
          case Jason.decode(json) do
            {:ok, map} -> map
            _ -> %{}
          end

        %{
          id: id,
          timestamp: ts,
          nodo: nodo,
          tipo: safe_atom(tipo),
          mensaje: msg,
          datos: datos
        }

      _ ->
        :invalid
    end
  end

  defp escape(v) do
    v
    |> to_string()
    |> String.replace("\"", "'")
    |> (&("\"" <> &1 <> "\"")).()
  end

  defp safe_atom(v),
    do:
      (try do
         String.to_existing_atom(v)
       rescue
         _ ->
           :info
       end)

  defp inicializar_csv do
    encabezado = "id,timestamp,nodo,tipo,mensaje,datos\n"
    File.write!(@log_file, encabezado)
  end

  defp mostrar_en_consola(%{tipo: :error} = e),
    do: IO.puts(IO.ANSI.red() <> "[ERROR] #{e.timestamp} | #{e.mensaje}" <> IO.ANSI.reset())

  defp mostrar_en_consola(%{tipo: :warning} = e),
    do: IO.puts(IO.ANSI.yellow() <> "[WARN] #{e.timestamp} | #{e.mensaje}" <> IO.ANSI.reset())

  defp mostrar_en_consola(e),
    do: IO.puts(IO.ANSI.cyan() <> "[INFO] #{e.timestamp} | #{e.mensaje}" <> IO.ANSI.reset())

  defp inferir_tipo(msg) do
    cond do
      Regex.match?(~r/error|fallo/i, msg) -> :error
      Regex.match?(~r/advertencia|alerta/i, msg) -> :warning
      true -> :info
    end
  end
end

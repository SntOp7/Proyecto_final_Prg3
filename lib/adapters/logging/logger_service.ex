defmodule ProyectoFinalPrg3.Adapters.Logging.LoggerService do
  @moduledoc """
  Servicio de logging del sistema. Registra eventos en `logs/event_log.csv`
  y permite exportarlos a JSON o TXT.
  """

  @behaviour ProyectoFinalPrg3.Adapters.Logging.LoggerServiceBehaviour

  @log_dir "logs"
  @log_file "#{@log_dir}/event_log.csv"

  # ============================================================
  # API PÚBLICA
  # ============================================================

  def registrar_evento(mensaje, data \\ %{}) when is_binary(mensaje) do
    evento = construir_evento(mensaje, data)
    guardar_en_archivo(evento)
    mostrar_en_consola(evento)
    :ok
  end

  def obtener_eventos_recientes(limite \\ 20) do
    unless File.exists?(@log_file) do
      []
    else
      @log_file
      |> File.stream!()
      |> Stream.drop(1)
      |> Enum.map(&parse_linea_csv/1)
      |> Enum.take(-limite)
    end
  end

  def limpiar_logs do
    File.rm(@log_file)
    File.mkdir_p!(@log_dir)
    inicializar_csv()
    :ok
  end

  # ============================================================
  # EXPORTACIONES
  # ============================================================

  def exportar_a_json(ruta_salida) do
    log_path = @log_file

    with true <- File.exists?(log_path),
         {:ok, contenido} <- File.read(log_path) do

      eventos =
        contenido
        |> String.split("\n", trim: true)
        |> Enum.drop(1)
        |> Enum.map(&parse_linea_csv/1)

      File.write!(ruta_salida, Jason.encode!(eventos, pretty: true))
      {:ok, ruta_salida}

    else
      _ -> {:error, :no_existe_log}
    end
  end

  def exportar_a_txt(ruta_salida) do
    case File.exists?(@log_file) do
      true ->
        File.cp!(@log_file, ruta_salida)
        {:ok, ruta_salida}

      false ->
        {:error, :no_existe_log}
    end
  end

  # ============================================================
  # PRIVADAS
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
    IO.puts(IO.ANSI.yellow() <> "[WARN]  #{e.timestamp} | #{e.mensaje}" <> IO.ANSI.reset())
  end

  defp mostrar_en_consola(e) do
    IO.puts(IO.ANSI.cyan() <> "[INFO]  #{e.timestamp} | #{e.mensaje}" <> IO.ANSI.reset())
  end

  defp inicializar_csv do
    encabezados = ["id", "timestamp", "nodo", "tipo", "mensaje", "datos"]
    File.write!(@log_file, Enum.join(encabezados, ",") <> "\n")
  end

  defp evento_a_csv(e) do
    [
      escape(e.id),
      escape(e.timestamp),
      escape(e.nodo),
      escape(to_string(e.tipo)),
      escape(e.mensaje),
      escape(e.datos)
    ]
    |> Enum.join(",")
    |> Kernel.<>("\n")
  end

  # ============================================================
  # CSV PARSER ROBUSTO
  # ============================================================

  defp parse_linea_csv(linea) do
    campos =
      linea
      |> String.trim()
      |> split_csv_line()

    [id, timestamp, nodo, tipo, mensaje, datos_json] = campos

    %{
      id: id,
      timestamp: timestamp,
      nodo: nodo,
      tipo: tipo,
      mensaje: mensaje,
      datos: Jason.decode!(datos_json)
    }
  end

  # Manejo correcto de campos entre comillas
  defp split_csv_line(line) do
    Regex.scan(~r/"([^"]*)"|([^,]+)/, line)
    |> Enum.map(fn
      [_, quoted, _] when quoted != nil -> quoted
      [_, _, unquoted]                  -> unquoted
    end)
  end

  defp escape(v) do
    v
    |> String.replace("\"", "'")
    |> then(&"\"#{&1}\"")
  end

  defp inferir_tipo(msg) do
    cond do
      String.contains?(msg, ["error", "fallo", "excepción"]) -> :error
      String.contains?(msg, ["advertencia", "alerta"]) -> :warning
      true -> :info
    end
  end
end

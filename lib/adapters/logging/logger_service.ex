defmodule ProyectoFinalPrg3.Adapters.Logging.LoggerService do
  @moduledoc """
  Servicio de logging central del sistema.

  - Registra eventos en logs/event_log.csv
  - Muestra en consola con colores
  - Exporta a JSON o TXT

  No realiza filtros ni análisis (eso es trabajo de AuditService).

  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  @log_dir "logs"
  @log_file "#{@log_dir}/event_log.csv"

  # ============================================================
  # API PÚBLICA
  # ============================================================

  @doc """
  Función principal para registrar un evento de logging.
  Parámetros:
    - `mensaje`: Descripción del evento.
    - `data`: Mapa con datos adicionales (opcional).
  Retorna: :ok
  """
  def registrar_evento(mensaje, data \\ %{}) when is_binary(mensaje) do
    evento = construir_evento(mensaje, data)
    guardar_en_archivo(evento)
    mostrar_en_consola(evento)
    :ok
  end

  @doc """
  Función para obtener los eventos más recientes del log.
  Parámetros:
    - `limite`: Cantidad máxima de eventos a retornar (por defecto 20).
  Retorna: Lista de mapas con los eventos.
  """
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

  @doc """
  Función para limpiar todos los logs existentes.
  Parámetros: Ninguno.
  Retorna: :ok
  """
  def limpiar_logs do
    # eliminar de forma segura (no falla si no existe)
    File.rm_rf!(@log_file)
    File.mkdir_p!(@log_dir)
    inicializar_csv()
    :ok
  end

  @doc """
  Funciones para exportar los eventos de logging a diferentes formatos.
  Parámetros:
    - `ruta_salida`: Ruta del archivo destino.
  Retorna:
    - `{:ok, ruta_salida}` con la ubicación del archivo exportado.
  """
  def exportar_a_json(ruta_salida) do
    eventos = obtener_eventos_recientes(99999)
    File.mkdir_p!(Path.dirname(ruta_salida))
    File.write!(ruta_salida, Jason.encode!(eventos, pretty: true))
    {:ok, ruta_salida}
  end

  @doc """
  Funciones para exportar los eventos de logging a diferentes formatos.
  Parámetros:
    - `ruta_salida`: Ruta del archivo destino.
  Retorna:
    - `{:ok, ruta_salida}` con la ubicación del archivo exportado.
  """
  def exportar_a_txt(ruta_salida) do
    contenido =
      obtener_eventos_recientes(99999)
      |> Enum.map(fn e ->
        "[#{e.timestamp}] (#{e.tipo}) #{e.mensaje} — #{Jason.encode!(e.datos)}"
      end)
      |> Enum.join("\n")

    File.mkdir_p!(Path.dirname(ruta_salida))
    File.write!(ruta_salida, contenido)
    {:ok, ruta_salida}
  end

  # ============================================================
  # PRIVADO
  # ============================================================

  @doc false
  defp construir_evento(mensaje, data) do
    %{
      id: UUID.uuid4(),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      nodo: Atom.to_string(Node.self()),
      tipo: Map.get(data || %{}, :tipo, inferir_tipo(mensaje)),
      mensaje: mensaje,
      datos: normalizar_datos(data)
    }
  end

  # Normaliza entrada recibida como `data` para guardarla y evitar
  # errores en JSON. Devuelve siempre una estructura JSON-serializable.
  @doc false
  defp normalizar_datos(nil), do: %{}
  defp normalizar_datos(data) when is_binary(data), do: data

  defp normalizar_datos(%_{} = s) do
    s
    |> Map.from_struct()
    |> Map.drop([:contrasena])
    |> normalizar_para_json()
  end

  defp normalizar_datos(map) when is_map(map) do
    map
    |> Map.drop([:contrasena])
    |> normalizar_para_json()
  end

  defp normalizar_datos(other), do: normalizar_para_json(other)

  # -------------------------------------------------------
  # GUARDA EN ARCHIVO (solo nodo central escribe CSV)
  # -------------------------------------------------------
  @doc false
  defp guardar_en_archivo(evento) do
    # Solo CENTRAL guarda logs en CSV (si quieres cambiar ese comportamiento,
    # modifica la condición). Esto evita duplicados y competencia por archivo.
    if Application.get_env(:proyecto_final_prg3, :tipo_nodo) == :central do
      File.mkdir_p!(@log_dir)
      unless File.exists?(@log_file), do: inicializar_csv()

      # normalizamos y convertimos a JSON seguro
      json_safe =
        evento.datos
        |> normalizar_para_json()
        |> Jason.encode!()

      fila_vals =
        [
          evento.id,
          evento.timestamp,
          evento.nodo,
          evento.tipo,
          evento.mensaje,
          json_safe
        ]
        |> Enum.map(&to_string/1)
        |> Enum.map(&escape/1)

      linea = Enum.join(fila_vals, ",") <> "\n"

      File.open!(@log_file, [:append, :binary], fn file ->
        IO.binwrite(file, linea)
      end)
    else
      # Si no es central, no escribe en CSV (pero sí muestra en consola)
      :ok
    end
  rescue
    e ->
      # Guardar fallo no debe romper la app; lo notificamos por consola
      IO.puts(
        IO.ANSI.red() <>
          "[LOGGER-ERR] #{DateTime.utc_now() |> DateTime.to_iso8601()} | Error guardando log: #{inspect(e)}" <>
          IO.ANSI.reset()
      )

      :ok
  end

  # ----------------------------------------------
  # NORMALIZAR CUALQUIER TIPO DE DATO PARA JSON/CSV
  # ----------------------------------------------

  # Tuplas → lista (segura)
  defp normalizar_para_json(tuple) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Enum.map(&normalizar_para_json/1)
  end

  defp normalizar_para_json(nil), do: %{}
  defp normalizar_para_json(d) when is_binary(d), do: d

  defp normalizar_para_json(%_{} = struct) do
    struct
    |> Map.from_struct()
    |> normalizar_para_json()
  end

  defp normalizar_para_json(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> {to_string(k), normalizar_para_json(v)} end)
    |> Map.new()
  end

  defp normalizar_para_json(list) when is_list(list) do
    Enum.map(list, &normalizar_para_json/1)
  end

  defp normalizar_para_json(other), do: to_string(other)

  @doc false
  defp parse_line(linea) do
    # Manejo robusto: si la línea está vacía o malformada, devolvemos :invalid
    linea = String.trim(linea)

    if linea == "" do
      :invalid
    else
      campos =
        Regex.scan(~r/"([^"]*)"|([^,]+)/, linea)
        |> Enum.map(fn
          [_, quoted, _] when quoted != nil -> quoted
          [_, _, normal] -> normal
          _ -> ""
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
  end

  @doc false
  defp escape(v) do
    v
    |> to_string()
    |> String.replace("\"", "'")
    |> (&("\"" <> &1 <> "\"")).()
  end

  @doc false
  defp safe_atom(v) when is_binary(v) do
    # evitamos crear atoms dinámicamente con String.to_atom/1
    try do
      String.to_existing_atom(v)
    rescue
      _ -> String.to_atom("unknown")
    end
  end

  defp safe_atom(_), do: :info

  @doc false
  defp inicializar_csv do
    File.mkdir_p!(@log_dir)
    encabezado = "id,timestamp,nodo,tipo,mensaje,datos\n"
    File.write!(@log_file, encabezado)
  end

  # ============================================================
  # NUEVO BLOQUE: MOSTRAR EN CONSOLA POR NODO
  # ============================================================

  defp mostrar_en_consola(evento) do
    tipo_nodo = Application.get_env(:proyecto_final_prg3, :tipo_nodo)
    # Comparamos por string para NO crear atoms dinámicamente
    nodo_local_str = Atom.to_string(Node.self())
    nodo_evento_str = to_string(evento.nodo)

    cond do
      # CENTRAL → muestra logs generados por CENTRAL (comparación por string segura)
      tipo_nodo == :central and nodo_evento_str == nodo_local_str ->
        imprimir(evento)

      # PERSISTENCIA → solo logs generados por persistencia
      tipo_nodo == :persistencia and nodo_evento_str == nodo_local_str ->
        imprimir(evento)

      # CLI → solo logs generados por CLI
      tipo_nodo == :cli and nodo_evento_str == nodo_local_str ->
        imprimir(evento)

      # En modo desarrollo local (cuando todos están en el mismo BEAM), permitimos
      # que CLI muestre sus logs también si tipo_nodo == :cli.
      true ->
        # no imprimir logs que no nos correspondan
        :ok
    end
  end

  defp imprimir(evento) do
    color =
      case evento.tipo do
        :error -> IO.ANSI.red()
        :warning -> IO.ANSI.yellow()
        _ -> IO.ANSI.cyan()
      end

    tipo_str = String.upcase(to_string(evento.tipo))

    IO.puts("#{color}[#{tipo_str}] #{evento.timestamp} | #{evento.mensaje}#{IO.ANSI.reset()}")
  end

  @doc false
  defp inferir_tipo(msg) do
    cond do
      Regex.match?(~r/error|fallo/i, msg) -> :error
      Regex.match?(~r/advertencia|alerta/i, msg) -> :warning
      true -> :info
    end
  end
end

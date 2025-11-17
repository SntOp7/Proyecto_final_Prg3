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
  def registrar_evento(mensaje, data \\ %{}) do
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
    File.rm(@log_file)
    File.mkdir_p!(@log_dir)
    inicializar_csv()
  end

  @doc """
  Funciones para exportar los eventos de logging a diferentes formatos.
  Parámetros:
    - `ruta_salida`: Ruta del archivo destino.
  Retorna:
    - `{:ok, ruta_salida}` con la ubicación del archivo exportado.
  """
  def exportar_a_json(ruta_salida) do
    eventos =
      obtener_eventos_recientes(99999)

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
      tipo: Map.get(data, :tipo, inferir_tipo(mensaje)),
      mensaje: mensaje,
      # <---- FIX
      datos: normalizar_datos(data)
    }
  end

  @doc false
  defp normalizar_datos(data) when is_struct(data) do
    data
    |> Map.from_struct()
    # nunca loguear contraseñas
    |> Map.drop([:contrasena])
  end

  @doc false
  defp normalizar_datos(data) when is_map(data) do
    data
    |> Map.drop([:contrasena])
  end

  # -------------------------------------------------------

  @doc false
  defp guardar_en_archivo(evento) do
    File.mkdir_p!(@log_dir)
    unless File.exists?(@log_file), do: inicializar_csv()

    json =
      if is_binary(evento.datos),
        do: evento.datos,
        # ← ahora siempre seguro
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

  @doc false
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

  @doc false
  defp escape(v) do
    v
    |> to_string()
    |> String.replace("\"", "'")
    |> (&("\"" <> &1 <> "\"")).()
  end

  @doc false
  defp safe_atom(v),
    do:
      (try do
         String.to_existing_atom(v)
       rescue
         _ ->
           :info
       end)

  @doc false
  defp inicializar_csv do
    encabezado = "id,timestamp,nodo,tipo,mensaje,datos\n"
    File.write!(@log_file, encabezado)
  end

  defp mostrar_en_consola(evento) do
    nodo_central = Application.get_env(:proyecto_final_prg3, :nodo_central)
    tipo_nodo = Application.get_env(:proyecto_final_prg3, :tipo_nodo)

    # Solo mostrar en consola si estamos en el nodo central
    if tipo_nodo == :central do
      case evento.tipo do
        :error ->
          IO.puts(
            IO.ANSI.red() <> "[ERROR] #{evento.timestamp} | #{evento.mensaje}" <> IO.ANSI.reset()
          )

        :warning ->
          IO.puts(
            IO.ANSI.yellow() <>
              "[WARN] #{evento.timestamp} | #{evento.mensaje}" <> IO.ANSI.reset()
          )

        _ ->
          IO.puts(
            IO.ANSI.cyan() <> "[INFO] #{evento.timestamp} | #{evento.mensaje}" <> IO.ANSI.reset()
          )
      end
    else
      # Si estamos en CLI o persistencia, enviar logs al nodo central
      try do
        if Node.alive?() and nodo_central do
          :rpc.call(nodo_central, IO, :puts, [formatear_log_remoto(evento)])
        end
      rescue
        _ -> :ok
      end
    end
  end

  defp formatear_log_remoto(evento) do
    color =
      case evento.tipo do
        :error -> IO.ANSI.red()
        :warning -> IO.ANSI.yellow()
        _ -> IO.ANSI.cyan()
      end

    tipo_str = String.upcase(to_string(evento.tipo))
    "#{color}[#{tipo_str}] #{evento.timestamp} | #{evento.mensaje}#{IO.ANSI.reset()}"
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

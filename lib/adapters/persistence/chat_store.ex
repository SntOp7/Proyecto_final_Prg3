# ============================================================
# CHAT STORE UNIFICADO - ETS + CSV en un solo módulo
# ============================================================

defmodule ProyectoFinalPrg3.Adapters.Persistence.ChatStore do
  @moduledoc """
  Almacena mensajes de chat usando ETS (memoria) con persistencia automática en CSV.

  Características:
  - Acceso rápido en memoria con ETS
  - Persistencia automática en CSV
  - Carga automática al iniciar
  - Todo en un solo módulo
  """

  alias ProyectoFinalPrg3.Domain.Message

  @table :chat_mensajes
  @mensajes_file "data/mensajes.csv"
  @headers "id,remitente_id,canal_id,contenido,timestamp\n"

  # ============================================================
  # INICIALIZACIÓN
  # ============================================================

  @doc """
  Inicializa ETS y carga mensajes desde CSV si existen.
  """
  def init do
    case :ets.whereis(@table) do
      :undefined ->
        :ets.new(@table, [:named_table, :public, :bag])
        asegurar_archivo_csv()
        cargar_mensajes_desde_csv()
        :ok
      _ ->
        :ok
    end
  end

  defp asegurar_archivo_csv do
    unless File.exists?(@mensajes_file) do
      File.mkdir_p!("data")
      File.write!(@mensajes_file, @headers)
    end
  end

  defp cargar_mensajes_desde_csv do
    case File.read(@mensajes_file) do
      {:ok, contenido} ->
        # Parsear CSV respetando comillas (contenido puede tener saltos de línea)
        mensajes = parsear_csv_completo(contenido)

        # Cargar en ETS
        Enum.each(mensajes, fn mensaje ->
          :ets.insert(@table, {mensaje.canal_id, mensaje})
        end)

        if length(mensajes) > 0 do
          IO.puts("✅ #{length(mensajes)} mensajes cargados desde persistencia")
          # Debug: mostrar canales únicos
          canales = mensajes |> Enum.map(& &1.canal_id) |> Enum.uniq()
          IO.puts("   Canales encontrados: #{Enum.join(canales, ", ")}")
        else
          IO.puts("⚠️  No se encontraron mensajes válidos en el CSV")
        end

      {:error, _} ->
        :ok
    end
  end

  # Parser CSV que respeta comillas y saltos de línea dentro de campos
  defp parsear_csv_completo(contenido) do
    lineas = String.split(contenido, "\n")
    |> Enum.drop(1)  # Saltar header
    |> Enum.reject(&(&1 == ""))

    parsear_lineas_csv(lineas, [])
  end

  defp parsear_lineas_csv([], acumulado), do: Enum.reverse(acumulado)

  defp parsear_lineas_csv([linea | resto], acumulado) do
    # Contar comillas en la línea
    num_comillas = linea |> String.graphemes() |> Enum.count(&(&1 == "\""))

    cond do
      # Si hay un número par de comillas, la línea está completa
      rem(num_comillas, 2) == 0 ->
        case parsear_linea_csv_completa(linea) do
          nil -> parsear_lineas_csv(resto, acumulado)
          mensaje -> parsear_lineas_csv(resto, [mensaje | acumulado])
        end

      # Si hay número impar, necesitamos juntar con la siguiente línea
      true ->
        case resto do
          [siguiente | resto_resto] ->
            linea_completa = linea <> "\n" <> siguiente
            parsear_lineas_csv([linea_completa | resto_resto], acumulado)

          [] ->
            acumulado
        end
    end
  end

  defp parsear_linea_csv_completa(linea) do
    # Parsear: id,remitente_id,canal_id,"contenido",timestamp
    # Usar regex para extraer campos correctamente
    case Regex.run(~r/^([^,]+),([^,]+),([^,]+),"(.+)",(.+)$/, linea) do
      [_, id, remitente_id, canal_id, contenido, timestamp_str] ->
        # Desescapar comillas dobles
        contenido_limpio = String.replace(contenido, "\"\"", "\"")

        case DateTime.from_iso8601(String.trim(timestamp_str)) do
          {:ok, timestamp, _} ->
            Message.nuevo(
              String.trim(id),
              String.trim(remitente_id),
              String.trim(canal_id),
              contenido_limpio,
              timestamp
            )
          _ ->
            nil
        end

      _ ->
        nil
    end
  end

  # ============================================================
  # OPERACIONES PRINCIPALES
  # ============================================================

  @doc """
  Agrega un mensaje al canal (lo guarda en ETS y CSV).

  Acepta:
  - Struct Message completo
  - Datos individuales (canal_id, remitente_id, contenido)
  """
  def agregar_mensaje(canal_id, %Message{} = mensaje) do
    init()

    # Guardar en ETS (rápido)
    :ets.insert(@table, {canal_id, mensaje})

    # Guardar en CSV (asíncrono para no bloquear)
    Task.start(fn ->
      guardar_mensaje_csv(mensaje)
    end)

    :ok
  end

  def agregar_mensaje(canal_id, remitente_id, contenido) when is_binary(contenido) do
    mensaje = Message.nuevo(
      UUID.uuid4(),
      remitente_id,
      canal_id,
      contenido,
      DateTime.utc_now()
    )

    agregar_mensaje(canal_id, mensaje)
    {:ok, mensaje}
  end

  @doc """
  Obtiene los últimos N mensajes de un canal.
  """
  def obtener_mensajes(canal_id, limite \\ 50) do
    init()

    :ets.lookup(@table, canal_id)
    |> Enum.map(fn {_id, msg} -> msg end)
    |> Enum.sort_by(& &1.timestamp, {:desc, DateTime})
    |> Enum.take(limite)
    |> Enum.reverse()
  end

  @doc """
  Elimina todos los mensajes de un canal (solo de ETS).
  Nota: No elimina del CSV para mantener historial.
  """
  def limpiar_chat(canal_id) do
    init()
    :ets.match_delete(@table, {canal_id, :_})
    :ok
  end

  # ============================================================
  # PERSISTENCIA CSV
  # ============================================================

  defp guardar_mensaje_csv(%Message{} = mensaje) do
    linea = [
      mensaje.id,
      mensaje.remitente_id,
      mensaje.canal_id,
      "\"#{escapar_csv(mensaje.contenido)}\"",
      DateTime.to_iso8601(mensaje.timestamp)
    ]
    |> Enum.join(",")
    |> Kernel.<>("\n")

    File.write!(@mensajes_file, linea, [:append])
  rescue
    e ->
      IO.puts("⚠️  Error guardando mensaje en CSV: #{inspect(e)}")
  end

  defp escapar_csv(texto) do
    texto |> String.replace("\"", "\"\"")
  end
end

# ============================================================
# HELPER PARA FECHAS
# ============================================================

defmodule ProyectoFinalPrg3.Utils.DateTimeHelper do
  @moduledoc """
  Helper para formatear fechas en zona horaria de Colombia (UTC-5).
  """

  @doc """
  Convierte DateTime UTC a hora de Colombia.
  """
  def to_colombia_time(%DateTime{} = dt) do
    DateTime.add(dt, -5 * 3600, :second)
  end

  @doc """
  Formato para chat: "14:30", "Ayer 14:30", o "15/11 14:30"
  """
  def formato_chat(%DateTime{} = dt) do
    ahora = DateTime.utc_now()
    dt_colombia = to_colombia_time(dt)
    ahora_colombia = to_colombia_time(ahora)

    cond do
      # Hoy
      Date.compare(DateTime.to_date(dt_colombia), DateTime.to_date(ahora_colombia)) == :eq ->
        Calendar.strftime(dt_colombia, "%H:%M")

      # Ayer
      Date.diff(DateTime.to_date(ahora_colombia), DateTime.to_date(dt_colombia)) == 1 ->
        "Ayer " <> Calendar.strftime(dt_colombia, "%H:%M")

      # Más días
      true ->
        Calendar.strftime(dt_colombia, "%d/%m %H:%M")
    end
  end
end

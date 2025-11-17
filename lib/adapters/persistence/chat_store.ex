defmodule ProyectoFinalPrg3.Adapters.Persistence.ChatStore do
  @moduledoc """
  Almacena mensajes de chat usando ETS con persistencia automática en CSV.

  Características:
  - ETS en memoria (rápido)
  - Persistencia automática en CSV (seguro)
  - Carga de historial al iniciar
  - Parsing correcto incluso con comillas o saltos de línea
  """

  use GenServer
  alias ProyectoFinalPrg3.Domain.Message

  @table :chat_mensajes
  @mensajes_file "data/mensajes.csv"
  @headers "id,remitente_id,canal_id,contenido,timestamp\n"

  # ---------------------------------------------------------------------
  # PUBLIC API
  # ---------------------------------------------------------------------

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    init_store()
    {:ok, state}
  end

  @doc """
  Función pública para asegurar que ETS + CSV están inicializados.
  """
  def init_store do
    case :ets.whereis(@table) do
      :undefined ->
        :ets.new(@table, [:named_table, :public, :bag])
        asegurar_archivo_csv()
        cargar_mensajes_desde_csv()

      _ ->
        :ok
    end
  end

  # ---------------------------------------------------------------------
  # ARCHIVOS / PERSISTENCIA
  # ---------------------------------------------------------------------

  defp asegurar_archivo_csv do
    unless File.exists?(@mensajes_file) do
      File.mkdir_p!("data")
      File.write!(@mensajes_file, @headers)
    end
  end

  defp cargar_mensajes_desde_csv do
    case File.read(@mensajes_file) do
      {:ok, contenido} ->
        mensajes = parsear_csv_completo(contenido)

        Enum.each(mensajes, fn mensaje ->
          :ets.insert(@table, {mensaje.canal_id, mensaje})
        end)

        if mensajes == [] do
          IO.puts("⚠️  No se encontraron mensajes válidos en el CSV")
        else
          IO.puts("✅ #{length(mensajes)} mensajes cargados desde persistencia")
        end

      _ ->
        :ok
    end
  end

  # ---------------------------------------------------------------------
  # AGREGAR MENSAJE
  # ---------------------------------------------------------------------

  def agregar_mensaje(canal_id, %Message{} = mensaje) do
    init_store()

    canal_str =
      case canal_id do
        canal when is_atom(canal) -> Atom.to_string(canal)
        canal when is_binary(canal) -> canal
      end

    mensaje_normalizado = %{mensaje | canal_id: canal_str}

    :ets.insert(@table, {canal_str, mensaje_normalizado})

    Task.start(fn ->
      guardar_mensaje_csv(mensaje_normalizado)
    end)

    :ok
  end

  def agregar_mensaje(canal_id, remitente_id, contenido) do
    canal_str =
      case canal_id do
        canal when is_atom(canal) -> Atom.to_string(canal)
        canal when is_binary(canal) -> canal
      end

    mensaje =
      Message.nuevo(
        UUID.uuid4(),
        remitente_id,
        canal_str,
        contenido,
        DateTime.utc_now()
      )

    agregar_mensaje(canal_str, mensaje)
    {:ok, mensaje}
  end

  # ---------------------------------------------------------------------
  # OBTENER MENSAJES
  # ---------------------------------------------------------------------

  def obtener_mensajes(canal_id, limite \\ 50) do
    init_store()

    canal_str =
      case canal_id do
        c when is_atom(c) -> Atom.to_string(c)
        c when is_binary(c) -> c
      end

    :ets.lookup(@table, canal_str)
    |> Enum.map(fn {_id, msg} -> msg end)
    |> Enum.sort_by(& &1.timestamp, {:desc, DateTime})
    |> Enum.take(limite)
    |> Enum.reverse()
  end

  @doc """
  Retorna el historial completo de los anuncios globales.
  """
  def obtener_anuncios_globales(limite \\ 50) do
    obtener_mensajes("canal_anuncios_globales", limite)
  end

  # ---------------------------------------------------------------------
  # CSV WRITER
  # ---------------------------------------------------------------------

  defp guardar_mensaje_csv(%Message{} = mensaje) do
    linea =
      [
        mensaje.id,
        mensaje.remitente_id,
        to_string(mensaje.canal_id),
        "\"#{escapar_csv(mensaje.contenido)}\"",
        DateTime.to_iso8601(mensaje.timestamp)
      ]
      |> Enum.join(",")
      |> Kernel.<>("\n")

    File.write!(@mensajes_file, linea, [:append])
  end

  defp escapar_csv(txt), do: String.replace(txt, "\"", "\"\"")

  # ---------------------------------------------------------------------
  # CSV PARSER
  # ---------------------------------------------------------------------

  defp parsear_csv_completo(contenido) do
    contenido
    |> String.split("\n")
    |> Enum.drop(1)
    |> Enum.reject(&(&1 == ""))
    |> parsear_lineas_csv([])
  end

  defp parsear_lineas_csv([], acc), do: Enum.reverse(acc)

  defp parsear_lineas_csv([linea | resto], acc) do
    num_comillas =
      linea
      |> String.graphemes()
      |> Enum.count(&(&1 == "\""))

    cond do
      rem(num_comillas, 2) == 0 ->
        case parsear_linea_csv(linea) do
          nil -> parsear_lineas_csv(resto, acc)
          msg -> parsear_lineas_csv(resto, [msg | acc])
        end

      true ->
        case resto do
          [sig | tail] ->
            parsear_lineas_csv([linea <> "\n" <> sig | tail], acc)

          [] ->
            acc
        end
    end
  end

  defp parsear_linea_csv(linea) do
    columnas = split_csv_line(linea)

    case columnas do
      [id, remitente, canal, contenido_raw, timestamp_str] ->
        contenido =
          contenido_raw
          |> String.trim_leading("\"")
          |> String.trim_trailing("\"")
          |> String.replace("\"\"", "\"")

        with {:ok, timestamp, _} <- DateTime.from_iso8601(String.trim(timestamp_str)) do
          Message.nuevo(
            String.trim(id),
            String.trim(remitente),
            canal |> String.trim(),
            contenido,
            timestamp
          )
        else
          _ -> nil
        end

      _ ->
        nil
    end
  end

  # Dividir CSV respetando comillas
  defp split_csv_line(linea) do
    do_split(String.graphemes(linea), [], "", false)
  end

  defp do_split([], acc, buf, _), do: acc ++ [buf]

  defp do_split([char | rest], acc, buf, en_comillas) do
    case {char, en_comillas} do
      {",", false} ->
        do_split(rest, acc ++ [buf], "", false)

      {"\"", false} ->
        do_split(rest, acc, buf <> char, true)

      {"\"", true} ->
        case rest do
          ["\"" | rr] -> do_split(rr, acc, buf <> "\"", true)
          _ -> do_split(rest, acc, buf <> "\"", false)
        end

      _ ->
        do_split(rest, acc, buf <> char, en_comillas)
    end
  end
end

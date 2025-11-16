defmodule ProyectoFinalPrg3.Adapters.Persistence.ProgressStore do
  @moduledoc """
  Persistencia de avances (Progress) totalmente alineada con el dominio actual.
  """

  alias ProyectoFinalPrg3.Domain.Progress

  @ruta Path.join([File.cwd!(), "data", "progress.csv"])
  @headers "id,proyecto_id,equipo_id,titulo,descripcion,fecha_registro,autor_id,estado,retroalimentacion,adjuntos,version\n"

  # ============================================================
  # CRUD PRINCIPAL
  # ============================================================

  def guardar_avance(%Progress{} = avance) do
    lista =
      listar_avances()
      |> Enum.reject(&(&1.id == avance.id))
      |> Kernel.++([avance])

    persistir_lista(lista)
    {:ok, avance}
  end

  def listar_avances do
    if File.exists?(@ruta) do
      File.stream!(@ruta)
      |> Stream.drop(1)
      |> Stream.map(&String.trim/1)
      |> Stream.reject(&(&1 == ""))
      |> Enum.map(&parse_line/1)
    else
      []
    end
  rescue
    _ -> []
  end

  def obtener_avance(id) do
    case Enum.find(listar_avances(), &(&1.id == id)) do
      nil -> {:error, :no_encontrado}
      avance -> {:ok, avance}
    end
  end

  def listar_por_proyecto(proyecto_id) do
    listar_avances()
    |> Enum.filter(&(&1.proyecto_id == proyecto_id))
  end

  def eliminar_avance(id) do
    nuevos =
      listar_avances()
      |> Enum.reject(&(&1.id == id))

    persistir_lista(nuevos)
    :ok
  end

  # ============================================================
  # SERIALIZACIÓN
  # ============================================================

  def persistir_lista(lista) do
    File.mkdir_p!("data")

    contenido =
      lista
      |> Enum.map(&to_csv/1)
      |> Enum.join("\n")

    File.write!(@ruta, @headers <> contenido <> "\n")
  end

  defp to_csv(%Progress{} = p) do
    [
      p.id,
      p.proyecto_id || "",
      p.equipo_id || "",
      clean(p.titulo),
      clean(p.descripcion),
      serialize_datetime(p.fecha_registro),
      p.autor_id || "",
      Atom.to_string(p.estado),
      clean(p.retroalimentacion || ""),
      serialize_list(p.adjuntos),
      p.version || ""
    ]
    |> Enum.join(",")
  end

  # ============================================================
  # PARSEO
  # ============================================================

  defp parse_line(line) do
    [
      id,
      proyecto_id,
      equipo_id,
      titulo,
      descripcion,
      fecha,
      autor_id,
      estado,
      retro,
      adjuntos,
      version
    ] =
      String.split(line, ",", parts: 11)

    %Progress{
      id: id,
      proyecto_id: blank(proyecto_id),
      equipo_id: blank(equipo_id),
      titulo: titulo,
      descripcion: descripcion,
      fecha_registro: parse_datetime(fecha),
      autor_id: blank(autor_id),
      estado: String.to_atom(estado),
      retroalimentacion: blank(retro),
      adjuntos: parse_list(adjuntos),
      version: version
    }
  end

  # ============================================================
  # UTILIDADES
  # ============================================================

  defp clean(nil), do: ""
  defp clean(text),
    do: text |> String.replace(",", ";") |> String.replace("\n", " ")

  defp blank(""), do: nil
  defp blank(v), do: v

  defp serialize_datetime(nil), do: ""
  defp serialize_datetime(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp serialize_datetime(%NaiveDateTime{} = dt), do: NaiveDateTime.to_string(dt)

  defp parse_datetime(""), do: nil
  defp parse_datetime(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> dt
      _ ->
        case NaiveDateTime.from_iso8601(str) do
          {:ok, dt} -> dt
          _ -> nil
        end
    end
  end

  defp serialize_list(nil), do: ""
  defp serialize_list(lista) when is_list(lista), do: Enum.join(lista, "|")

  defp parse_list(""), do: []
  defp parse_list(str), do: String.split(str, "|")
end

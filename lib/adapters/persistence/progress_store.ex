defmodule ProyectoFinalPrg3.Adapters.Persistence.ProgressStore do
  @moduledoc """
  Persistencia de avances (Progress) totalmente alineada con el dominio actual.
  Guarda los campos: id, proyecto_id, equipo_id, titulo, descripcion, fecha_registro, autor_id, estado, retroalimentacion, adjuntos, version.
  Utiliza CSV en `data/progress.csv` con encabezado:
  "id,proyecto_id,equipo_id,titulo,descripcion,fecha_registro
  ,autor_id,estado,retroalimentacion,adjuntos,version"
  Proporciona operaciones CRUD completas y consultas específicas por proyecto.
  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  alias ProyectoFinalPrg3.Domain.Progress

  @ruta Path.join([File.cwd!(), "data", "progress.csv"])
  @headers "id,proyecto_id,equipo_id,titulo,descripcion,fecha_registro,autor_id,estado,retroalimentacion,adjuntos,version\n"

  # ============================================================
  # CRUD PRINCIPAL
  # ============================================================

  @doc"""
  Guarda o actualiza un avance basado en su id.
  Parámetros:
    - `avance`: Struct %Progress{} a guardar o actualizar.
  Retorna:
    - `{:ok, avance}` confirmando la operación.
  """
  def guardar_avance(%Progress{} = avance) do
    lista =
      listar_avances()
      |> Enum.reject(&(&1.id == avance.id))
      |> Kernel.++([avance])

    persistir_lista(lista)
    {:ok, avance}
  end

  @doc"""
  Lista todos los avances almacenados.
  Retorna:
    - Lista de structs %Progress{}.
  """
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

  @doc"""
  Obtiene un avance por su id.
  Parámetros:
    - `id`: Identificador único del avance.
  Retorna:
    - `{:ok, avance}` si se encuentra.
    - `{:error, :no_encontrado}` si no existe.
  """
  def obtener_avance(id) do
    case Enum.find(listar_avances(), &(&1.id == id)) do
      nil -> {:error, :no_encontrado}
      avance -> {:ok, avance}
    end
  end

  @doc"""
  Lista todos los avances asociados a un proyecto específico.
  Parámetros:
    - `proyecto_id`: Identificador del proyecto.
  Retorna:
    - Lista de structs %Progress{} asociados al proyecto.
  """
  def listar_por_proyecto(proyecto_id) do
    listar_avances()
    |> Enum.filter(&(&1.proyecto_id == proyecto_id))
  end

  @doc"""
  Elimina un avance por su id.
  Parámetros:
    - `id`: Identificador único del avance a eliminar.
  Retorna:
    - `:ok` tras la eliminación.
  """
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

  @doc"""
  Persiste la lista completa de avances en el archivo CSV.
  Parámetros:
    - `lista`: Lista de structs %Progress{} a persistir.
  Retorna:
    - `:ok` tras la persistencia.
  """
  def persistir_lista(lista) do
    File.mkdir_p!("data")

    contenido =
      lista
      |> Enum.map(&to_csv/1)
      |> Enum.join("\n")

    File.write!(@ruta, @headers <> contenido <> "\n")
  end

  @doc false
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

  @doc false
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

  @doc false
  defp clean(nil), do: ""
  defp clean(text),
    do: text |> String.replace(",", ";") |> String.replace("\n", " ")

  @doc false
  defp blank(""), do: nil
  defp blank(v), do: v

  @doc false
  defp serialize_datetime(nil), do: ""
  defp serialize_datetime(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp serialize_datetime(%NaiveDateTime{} = dt), do: NaiveDateTime.to_string(dt)

  @doc false
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

  @doc false
  defp serialize_list(nil), do: ""
  defp serialize_list(lista) when is_list(lista), do: Enum.join(lista, "|")

  @doc false
  defp parse_list(""), do: []
  defp parse_list(str), do: String.split(str, "|")
end

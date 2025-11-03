defmodule ProyectoFinalPrg3.Adapters.Persistence.ProgressStore do
  @moduledoc """
  Adaptador de persistencia encargado de almacenar y recuperar los avances (`Progress`)
  asociados a proyectos dentro del sistema Hackathon.

  Este módulo pertenece a la capa de persistencia de la arquitectura hexagonal y es utilizado
  por `ProjectManager` o `TeamManager` para registrar y consultar el progreso de los equipos.

  Los datos se almacenan en formato CSV dentro de `data/progress.csv`.
  Incluye soporte para serialización de campos complejos (por ejemplo, listas de adjuntos o notas de retroalimentación).

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.Progress

  @data_path Path.join([File.cwd!(), "data", "progress.csv"])
  @headers "id,proyecto_id,equipo_id,titulo,descripcion,fecha_registro,autor_id,estado,retroalimentacion,adjuntos,version\n"

  # ============================================================
  # FUNCIONES CRUD PRINCIPALES
  # ============================================================

  @doc """
  Guarda un avance en el archivo CSV.
  Si ya existe un avance con el mismo `id`, lo reemplaza.
  """
  def guardar_avance(%Progress{} = avance) do
    avances =
      listar_avances()
      |> Enum.reject(&(&1.id == avance.id))
      |> Kernel.++([avance])

    persistir_lista(avances)
    {:ok, avance}
  end

  @doc """
  Retorna una lista con todos los avances registrados.
  """
  def listar_avances do
    if File.exists?(@data_path) do
      File.stream!(@data_path)
      |> Stream.drop(1) # Saltar encabezado
      |> Stream.map(&String.trim/1)
      |> Stream.reject(&(&1 == ""))
      |> Enum.map(&parsear_linea/1)
    else
      []
    end
  rescue
    _ -> []
  end

  @doc """
  Obtiene un avance por su identificador único.
  """
  def obtener_avance(id) do
    case Enum.find(listar_avances(), &(&1.id == id)) do
      nil -> {:error, :no_encontrado}
      avance -> {:ok, avance}
    end
  end

  @doc """
  Lista los avances asociados a un proyecto específico.
  """
  def listar_por_proyecto(proyecto_id) do
    listar_avances()
    |> Enum.filter(&(&1.proyecto_id == proyecto_id))
  end

  @doc """
  Elimina un avance por su ID.
  """
  def eliminar_avance(id) do
    avances_filtrados =
      listar_avances()
      |> Enum.reject(&(&1.id == id))

    persistir_lista(avances_filtrados)
    :ok
  end

  # ============================================================
  # FUNCIONES PRIVADAS DE SERIALIZACIÓN Y DESERIALIZACIÓN
  # ============================================================

  @doc false
  defp persistir_lista(lista) do
    File.mkdir_p!("data")

    contenido =
      lista
      |> Enum.map(&serializar_avance/1)
      |> Enum.join("\n")

    File.write!(@data_path, @headers <> contenido <> "\n")
  end

  @doc false
  defp serializar_avance(%Progress{} = avance) do
    [
      avance.id,
      avance.proyecto_id || "",
      avance.equipo_id || "",
      limpiar(avance.titulo),
      limpiar(avance.descripcion),
      serialize_datetime(avance.fecha_registro),
      avance.autor_id || "",
      avance.estado || "",
      limpiar(avance.retroalimentacion),
      serialize_list(avance.adjuntos),
      avance.version || ""
    ]
    |> Enum.join(",")
  end

  @doc false
  defp parsear_linea(linea) do
    [
      id,
      proyecto_id,
      equipo_id,
      titulo,
      descripcion,
      fecha_registro,
      autor_id,
      estado,
      retroalimentacion,
      adjuntos,
      version
    ] =
      String.split(linea, ",", parts: 11)

    %Progress{
      id: id,
      proyecto_id: parse_blank(proyecto_id),
      equipo_id: parse_blank(equipo_id),
      titulo: titulo,
      descripcion: descripcion,
      fecha_registro: parse_datetime(fecha_registro),
      autor_id: parse_blank(autor_id),
      estado: estado,
      retroalimentacion: retroalimentacion,
      adjuntos: parse_list(adjuntos),
      version: version
    }
  end

  # ============================================================
  # FUNCIONES AUXILIARES
  # ============================================================

  defp limpiar(nil), do: ""
  defp limpiar(texto) do
    texto
    |> String.replace(",", ";")
    |> String.replace("\n", " ")
  end

  defp parse_blank(""), do: nil
  defp parse_blank(valor), do: valor

  defp serialize_datetime(nil), do: ""
  defp serialize_datetime(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp serialize_datetime(%NaiveDateTime{} = dt), do: NaiveDateTime.to_string(dt)

  defp parse_datetime(""), do: nil
  defp parse_datetime(str) do
    cond do
      String.contains?(str, "T") ->
        case DateTime.from_iso8601(str) do
          {:ok, dt, _} -> dt
          _ -> nil
        end

      true ->
        case NaiveDateTime.from_iso8601(str) do
          {:ok, dt} -> dt
          _ -> nil
        end
    end
  end

  defp serialize_list(nil), do: ""
  defp serialize_list(lista) when is_list(lista), do: Enum.join(lista, "|")

  defp parse_list(""), do: []
  defp parse_list(cadena), do: String.split(cadena, "|")
end

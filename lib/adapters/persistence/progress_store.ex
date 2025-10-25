defmodule ProyectoFinalPrg3.Adapters.Persistence.ProgressStore do
  @moduledoc """
  Módulo responsable de la persistencia de los avances (Progress) asociados a proyectos dentro del sistema Hackathon.
  Este adaptador forma parte de la capa de persistencia de la arquitectura hexagonal y es utilizado por `ProjectManager`.

  Los datos se almacenan en formato CSV en `data/progress.csv`, con cada línea representando un avance.
  Incluye soporte para serialización JSON para estructuras anidadas (por ejemplo, metadatos o archivos adjuntos).

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-26
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.Progress
  @ruta_archivo Path.join([File.cwd!(), "data", "progress.csv"])

  # ============================================================
  # FUNCIONES PÚBLICAS PRINCIPALES
  # ============================================================

  @doc """
  Guarda un nuevo avance en el archivo CSV.
  Si ya existe un avance con el mismo ID, lo reemplaza.
  """
  def guardar_avance(%Progress{} = avance) do
    avances = listar_avances()

    avances_actualizados =
      avances
      |> Enum.reject(&(&1.id == avance.id))
      |> Kernel.++([avance])

    persistir_lista(avances_actualizados)
  end

  @doc """
  Lista todos los avances registrados.
  """
  def listar_avances do
    if File.exists?(@data_file) do
      File.stream!(@data_file)
      |> Stream.map(&String.trim/1)
      |> Stream.reject(&(&1 == ""))
      |> Enum.map(&parsear_linea/1)
    else
      []
    end
  end

  @doc """
  Obtiene un avance a partir de su ID.
  """
  def obtener_avance(id) do
    listar_avances()
    |> Enum.find(&(&1.id == id))
  end

  @doc """
  Obtiene todos los avances asociados a un proyecto.
  """
  def listar_por_proyecto(proyecto_id) do
    listar_avances()
    |> Enum.filter(&(&1.proyecto_id == proyecto_id))
  end

  @doc """
  Elimina un avance por su ID.
  """
  def eliminar_avance(id) do
    avances =
      listar_avances()
      |> Enum.reject(&(&1.id == id))

    persistir_lista(avances)
  end

  # ============================================================
  # FUNCIONES INTERNAS DE PERSISTENCIA
  # ============================================================

  @doc false
  defp persistir_lista(lista) do
    File.mkdir_p!("data")

    contenido =
      lista
      |> Enum.map(&serializar_avance/1)
      |> Enum.join("\n")

    File.write!(@data_file, contenido)
  end

  @doc false
  defp serializar_avance(%Progress{} = avance) do
    [
      avance.id,
      avance.proyecto_id || "",
      avance.autor_id || "",
      avance.titulo || "",
      limpiar(avance.descripcion),
      serialize_timestamp(avance.fecha),
      avance.estado |> Atom.to_string(),
      serialize_json(avance.metadatos)
    ]
    |> Enum.join(",")
  end

  @doc false
  defp parsear_linea(linea) do
    [
      id,
      proyecto_id,
      autor_id,
      titulo,
      descripcion,
      fecha,
      estado,
      metadatos
    ] =
      String.split(linea, ",", parts: 8)

    %Progress{
      id: id,
      proyecto_id: parse_blank(proyecto_id),
      autor_id: parse_blank(autor_id),
      titulo: titulo,
      descripcion: descripcion,
      fecha: parse_timestamp(fecha),
      estado: String.to_atom(estado),
      metadatos: parse_json(metadatos)
    }
  end

  # ============================================================
  # FUNCIONES AUXILIARES DE SERIALIZACIÓN
  # ============================================================

  @doc false
  defp limpiar(nil), do: ""
  defp limpiar(texto), do: String.replace(texto, ",", ";")

  @doc false
  defp parse_blank(""), do: nil
  defp parse_blank(valor), do: valor

  @doc false
  defp serialize_timestamp(nil), do: ""
  defp serialize_timestamp(%DateTime{} = dt), do: DateTime.to_iso8601(dt)

  @doc false
  defp parse_timestamp(""), do: nil
  defp parse_timestamp(valor) do
    case DateTime.from_iso8601(valor) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end

  @doc false
  defp serialize_json(nil), do: ""
  defp serialize_json(map) when is_map(map), do: Jason.encode!(map)

  @doc false
  defp parse_json(""), do: %{}
  defp parse_json(json) do
    case Jason.decode(json) do
      {:ok, mapa} -> mapa
      _ -> %{}
    end
  end
end

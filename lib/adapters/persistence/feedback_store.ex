defmodule ProyectoFinalPrg3.Adapters.Persistence.FeedbackStore do
  @moduledoc """
  Adaptador de persistencia encargado de almacenar y recuperar las retroalimentaciones (feedbacks)
  del sistema de hackathon.

  Permite registrar, listar, filtrar, actualizar y eliminar retroalimentaciones asociadas a proyectos
  o equipos, garantizando la trazabilidad de los comentarios emitidos por mentores.

  Este módulo actúa como capa de persistencia dentro de la arquitectura hexagonal,
  utilizando almacenamiento en archivos CSV ubicados en `data/feedbacks.csv`.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.Feedback

  @ruta_archivo Path.join([File.cwd!(), "data", "feedback.csv"])
  @headers "id,mentor_id,proyecto_id,equipo_id,avance_id,contenido,fecha_creacion,nivel,visibilidad,estado\n"

  # ============================================================
  # FUNCIONES CRUD PRINCIPALES
  # ============================================================

  @doc """
  Guarda o actualiza un feedback en el archivo CSV.
  Si el feedback ya existe (por `id`), se reemplaza su información.
  """
  def guardar_feedback(%Feedback{} = feedback) do
    feedbacks =
      listar_feedbacks()
      |> Enum.reject(&(&1.id == feedback.id))
      |> Kernel.++([feedback])

    escribir_feedbacks(feedbacks)
    {:ok, feedback}
  end

  @doc """
  Obtiene un feedback a partir de su identificador único.
  """
  def obtener_feedback(id) do
    case Enum.find(listar_feedbacks(), &(&1.id == id)) do
      nil -> {:error, :no_encontrado}
      feedback -> {:ok, feedback}
    end
  end

  @doc """
  Lista todos los feedbacks registrados en el sistema.
  Retorna una lista de estructuras `%Feedback{}`.
  """
  def listar_feedbacks do
    if File.exists?(@ruta_archivo) do
      File.stream!(@ruta_archivo)
      |> Stream.drop(1) # Saltar encabezado CSV
      |> Stream.map(&parse_csv_line/1)
      |> Enum.to_list()
    else
      []
    end
  rescue
    _ -> []
  end

  @doc """
  Elimina un feedback del archivo CSV a partir de su ID.
  """
  def eliminar_feedback(id) do
    feedbacks_filtrados =
      listar_feedbacks()
      |> Enum.reject(fn f -> f.id == id end)

    escribir_feedbacks(feedbacks_filtrados)
    :ok
  end

  # ============================================================
  # FUNCIONES DE FILTRADO Y CONSULTA
  # ============================================================

  @doc """
  Lista los feedback emitidos por un mentor específico.
  """
  def listar_por_mentor(id_mentor) do
    listar_feedbacks()
    |> Enum.filter(&(&1.mentor_id == id_mentor))
  end

  @doc """
  Lista los feedback asociados a un proyecto o equipo.
  """
  def listar_por_destino(destino_id) do
    listar_feedbacks()
    |> Enum.filter(fn f ->
      f.proyecto_id == destino_id or f.equipo_id == destino_id
    end)
  end

  @doc """
  Filtra feedbacks por estado, nivel o visibilidad.
  """
  def filtrar_por(campo, valor) do
    listar_feedbacks()
    |> Enum.filter(fn f ->
      case campo do
        :estado -> f.estado == valor
        :nivel -> f.nivel == valor
        :visibilidad -> f.visibilidad == valor
        _ -> false
      end
    end)
  end

  # ============================================================
  # FUNCIONES PRIVADAS DE SERIALIZACIÓN Y DESERIALIZACIÓN
  # ============================================================

  # Convierte una línea CSV en una estructura %Feedback{}
  defp parse_csv_line(line) do
    [
      id,
      mentor_id,
      proyecto_id,
      equipo_id,
      avance_id,
      contenido,
      fecha_creacion,
      nivel,
      visibilidad,
      estado
    ] =
      line
      |> String.trim()
      |> String.split(",", parts: 10)

    %Feedback{
      id: id,
      mentor_id: parse_nil(mentor_id),
      proyecto_id: parse_nil(proyecto_id),
      equipo_id: parse_nil(equipo_id),
      avance_id: parse_nil(avance_id),
      contenido: contenido,
      fecha_creacion: parse_datetime(fecha_creacion),
      nivel: nivel,
      visibilidad: visibilidad,
      estado: estado
    }
  end

  # Convierte lista de feedbacks a formato CSV y guarda el archivo
  defp escribir_feedbacks(feedbacks) do
    contenido =
      feedbacks
      |> Enum.map(&to_csv_line/1)
      |> Enum.join("\n")

    File.mkdir_p!("data")
    File.write!(@ruta_archivo, @headers <> contenido <> "\n")
  end

  # Convierte una estructura %Feedback{} a una línea CSV
  defp to_csv_line(%Feedback{} = f) do
    [
      f.id,
      f.mentor_id || "",
      f.proyecto_id || "",
      f.equipo_id || "",
      f.avance_id || "",
      sanitize(f.contenido),
      format_datetime(f.fecha_creacion),
      f.nivel,
      f.visibilidad,
      f.estado
    ]
    |> Enum.join(",")
  end

  # ============================================================
  # FUNCIONES AUXILIARES
  # ============================================================

  defp sanitize(texto) when is_binary(texto) do
    texto
    |> String.replace(",", ";")
    |> String.replace("\n", " ")
  end

  defp parse_nil(""), do: nil
  defp parse_nil(valor), do: valor

  defp parse_datetime(""), do: nil
  defp parse_datetime(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end

  defp format_datetime(nil), do: ""
  defp format_datetime(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
end

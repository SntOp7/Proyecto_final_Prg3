defmodule ProyectoFinalPrg3.Adapters.Persistence.FeedbackStore do
  @moduledoc """
  Módulo encargado de la persistencia de retroalimentaciones (feedbacks) del sistema.
  Permite registrar, listar, actualizar y eliminar retroalimentaciones, garantizando
  la trazabilidad de los comentarios emitidos por los mentores.

  Este módulo actúa como adaptador de persistencia dentro de la arquitectura hexagonal,
  utilizando archivos CSV ubicados en `data/feedbacks.csv`.

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
  Si el feedback ya existe, se reemplaza su información.
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
  Obtiene un feedback por su ID.
  """
  def obtener_feedback(id) do
    case Enum.find(listar_feedbacks(), &(&1.id == id)) do
      nil -> {:error, :no_encontrado}
      feedback -> {:ok, feedback}
    end
  end

  @doc """
  Lista todos los feedbacks registrados en el sistema.
  """
  def listar_feedbacks do
    if File.exists?(@data_path) do
      File.stream!(@data_path)
      |> Stream.drop(1)
      |> Stream.map(&parse_csv_line/1)
      |> Enum.to_list()
    else
      []
    end
  end

  @doc """
  Elimina un feedback a partir de su identificador.
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
  Lista los feedback asociados a un mentor específico.
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

  # Convierte una línea CSV a estructura %Feedback{}
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

  # Convierte una lista de feedbacks en texto CSV y lo guarda en archivo
  defp escribir_feedbacks(feedbacks) do
    contenido =
      feedbacks
      |> Enum.map(&to_csv_line/1)
      |> Enum.join("\n")

    File.mkdir_p!("data")
    File.write!(@data_path, @headers <> contenido)
  end

  # Convierte un feedback a una línea CSV
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

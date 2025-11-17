defmodule ProyectoFinalPrg3.Adapters.Persistence.FeedbackStore do
  @moduledoc """
  Persistencia de retroalimentaciones (feedback) alineada al dominio Feedback.
  Guarda los campos: id, mentor_id, proyecto_id, contenido, fecha_creacion.
  Proporciona operaciones CRUD y consultas específicas.
  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  alias ProyectoFinalPrg3.Domain.Feedback

  @ruta Path.join([File.cwd!(), "data", "feedback.csv"])
  @headers "id,mentor_id,proyecto_id,contenido,fecha_creacion\n"

  # ============================================================
  # CRUD PRINCIPAL
  # ============================================================

  @doc """
  Guarda o actualiza un feedback basado en su id.
  Parámetros:
    - `feedback`: Struct %Feedback{} a guardar o actualizar.
  Retorna:
    - `{:ok, feedback}` confirmando la operación.
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
  Obtiene un feedback por id.
  Parámetros:
    - `id`: Identificador único del feedback.
  Retorna:
    - `{:ok, feedback}` si se encuentra.
    - `{:error, :no_encontrado}` si no existe.
  """
  def obtener_feedback(id) do
    case Enum.find(listar_feedbacks(), &(&1.id == id)) do
      nil -> {:error, :no_encontrado}
      f -> {:ok, f}
    end
  end

  @doc """
  Lista todos los feedbacks como structs.
  Parámetros: Ninguno.
  Retorna:
    - Lista de feedbacks.
  """
  def listar_feedbacks do
    if File.exists?(@ruta) do
      File.stream!(@ruta)
      |> Stream.drop(1)
      |> Stream.map(&parse_line/1)
      |> Enum.to_list()
    else
      []
    end
  rescue
    _ -> []
  end

  @doc """
  Elimina un feedback por id.
  Parámetros:
    - `id`: Identificador único del feedback a eliminar.
  Retorna:
    - `:ok`.
  """
  def eliminar_feedback(id) do
    feedbacks =
      listar_feedbacks()
      |> Enum.reject(&(&1.id == id))

    escribir_feedbacks(feedbacks)
    :ok
  end

  # ============================================================
  # CONSULTAS SIMPLES
  # ============================================================

  @doc """
  Lista todos los feedback creados por un mentor.
  Parámetros:
    - `id_mentor`: Identificador único del mentor.
  Retorna:
    - Lista de feedbacks creados por el mentor.
  """
  def listar_por_mentor(id_mentor) do
    listar_feedbacks()
    |> Enum.filter(&(&1.mentor_id == id_mentor))
  end

  @doc """
  Lista todos los feedback dirigidos a un proyecto.
  Parámetros:
    - `id_proyecto`: Identificador único del proyecto.
  Retorna:
    - Lista de feedbacks dirigidos al proyecto.
  """
  def listar_por_proyecto(id_proyecto) do
    listar_feedbacks()
    |> Enum.filter(&(&1.proyecto_id == id_proyecto))
  end

  # ============================================================
  # SERIALIZACIÓN / DESERIALIZACIÓN
  # ============================================================

  @doc false
  defp parse_line(linea) do
    [id, mentor_id, proyecto_id, contenido, fecha] =
      linea
      |> String.trim()
      |> split_csv()

    %Feedback{
      id: id,
      mentor_id: mentor_id,
      proyecto_id: proyecto_id,
      contenido: contenido,
      fecha_creacion: parse_datetime(fecha)
    }
  end

  @doc false
  defp escribir_feedbacks(lista) do
    contenido =
      lista
      |> Enum.map(&to_csv/1)
      |> Enum.join("\n")

    File.mkdir_p!("data")
    File.write!(@ruta, @headers <> contenido <> "\n")
  end

  @doc false
  defp to_csv(%Feedback{
         id: id,
         mentor_id: mentor_id,
         proyecto_id: proyecto_id,
         contenido: contenido,
         fecha_creacion: fecha
       }) do
    [
      id,
      mentor_id,
      proyecto_id,
      escapar(contenido),
      format_datetime(fecha)
    ]
    |> Enum.join(",")
  end

  # ============================================================
  # UTILIDADES
  # ============================================================

  # Maneja comas dentro de contenido
  @doc false
  defp escapar(texto) when is_binary(texto) do
    if String.contains?(texto, ",") do
      "\"" <> texto <> "\""
    else
      texto
    end
  end

  # Permite comas dentro de comillas
  @doc false
  defp split_csv(linea) do
  Regex.scan(~r/"([^"]*)"|([^,]+)/, linea)
  |> Enum.map(fn
    [_, quoted, nil] -> quoted
    [_, nil, normal] -> normal
    _ -> ""
  end)
end

  @doc false
  defp parse_datetime(""), do: nil

  @doc false
  defp parse_datetime(str) when is_binary(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end

  @doc false
  defp format_datetime(nil), do: ""

  @doc false
  defp format_datetime(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
end

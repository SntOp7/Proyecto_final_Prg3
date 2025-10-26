defmodule ProyectoFinalPrg3.Adapters.Persistence.FeedbackStore do
  @moduledoc """
  Módulo encargado de la persistencia de retroalimentaciones (feedbacks) dentro del
  sistema de hackathon. Permite registrar, listar, actualizar y eliminar los
  comentarios y evaluaciones emitidos por mentores o jurados sobre proyectos o equipos.

  Este adaptador se usa tanto desde `ProjectManager` como desde `MentorManager`,
  garantizando que todas las evaluaciones estén centralizadas y sean consultables.

  Los datos se almacenan en `data/feedbacks.csv` y soportan listas serializadas en JSON.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-26
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.Feedback
  @ruta_archivo Path.join([File.cwd!(), "data", "feedback.csv"])

  # ============================================================
  # FUNCIONES PRINCIPALES
  # ============================================================

  @doc """
  Guarda una nueva retroalimentación o actualiza una existente si ya existe con el mismo ID.
  """
  def guardar_feedback(%Feedback{} = feedback) do
    feedbacks = listar_feedbacks()

    feedbacks_actualizados =
      feedbacks
      |> Enum.reject(&(&1.id == feedback.id))
      |> Kernel.++([feedback])

    persistir_lista(feedbacks_actualizados)
  end

  @doc """
  Devuelve la lista completa de retroalimentaciones registradas.
  """
  def listar_feedbacks do
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
  Obtiene una retroalimentación a partir de su identificador único.
  """
  def obtener_por_id(id) do
    listar_feedbacks()
    |> Enum.find(&(&1.id == id))
  end

  @doc """
  Lista todas las retroalimentaciones asociadas a un proyecto.
  """
  def listar_por_proyecto(id_proyecto) do
    listar_feedbacks()
    |> Enum.filter(&(&1.proyecto_id == id_proyecto))
  end

  @doc """
  Lista todas las retroalimentaciones emitidas por un mentor específico.
  """
  def listar_por_mentor(id_mentor) do
    listar_feedbacks()
    |> Enum.filter(&(&1.mentor_id == id_mentor))
  end

  @doc """
  Elimina una retroalimentación del sistema por su ID.
  """
  def eliminar_feedback(id) do
    feedbacks =
      listar_feedbacks()
      |> Enum.reject(&(&1.id == id))

    persistir_lista(feedbacks)
  end

  # ============================================================
  # FUNCIONES INTERNAS DE PERSISTENCIA
  # ============================================================

  @doc false
  defp persistir_lista(lista_feedbacks) do
    File.mkdir_p!("data")

    contenido =
      lista_feedbacks
      |> Enum.map(&serializar_feedback/1)
      |> Enum.join("\n")

    File.write!(@data_file, contenido)
  end

  @doc false
  defp serializar_feedback(%Feedback{} = f) do
    [
      f.id,
      limpiar(f.proyecto_id),
      limpiar(f.mentor_id),
      limpiar(f.autor_nombre),
      limpiar(f.comentario),
      f.calificacion || 0,
      serialize_timestamp(f.fecha_creacion),
      serialize_timestamp(f.fecha_actualizacion),
      serialize_json(f.etiquetas)
    ]
    |> Enum.join(",")
  end

  @doc false
  defp parsear_linea(linea) do
    [
      id,
      proyecto_id,
      mentor_id,
      autor_nombre,
      comentario,
      calificacion,
      fecha_creacion,
      fecha_actualizacion,
      etiquetas_json
    ] =
      String.split(linea, ",", parts: 9)

    %Feedback{
      id: id,
      proyecto_id: proyecto_id,
      mentor_id: mentor_id,
      autor_nombre: autor_nombre,
      comentario: comentario,
      calificacion: String.to_integer(calificacion),
      fecha_creacion: parse_timestamp(fecha_creacion),
      fecha_actualizacion: parse_timestamp(fecha_actualizacion),
      etiquetas: parse_json(etiquetas_json)
    }
  end

  # ============================================================
  # FUNCIONES AUXILIARES DE SERIALIZACIÓN
  # ============================================================

  @doc false
  defp limpiar(nil), do: ""
  defp limpiar(texto), do: texto |> String.replace(",", ";") |> String.trim()

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
  defp serialize_json(nil), do: "[]"
  defp serialize_json(lista) when is_list(lista), do: Jason.encode!(lista)

  @doc false
  defp parse_json(""), do: []
  defp parse_json(json) do
    case Jason.decode(json) do
      {:ok, lista} -> lista
      _ -> []
    end
  end
end

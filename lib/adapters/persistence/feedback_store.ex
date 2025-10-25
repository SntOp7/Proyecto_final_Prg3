defmodule ProyectoFinalPrg3.Adapters.Persistence.FeedbackStore do
  @moduledoc """
  Módulo responsable de la persistencia de retroalimentaciones (feedbacks) asociadas a los proyectos.
  Actúa como un adaptador de la capa de persistencia dentro de la arquitectura hexagonal.

  Gestiona el almacenamiento, lectura, actualización y eliminación de retroalimentaciones.
  Utiliza un formato CSV liviano y serialización JSON para mantener compatibilidad con datos anidados
  (como evaluaciones, observaciones o archivos adjuntos).

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-26
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.Feedback
   @ruta_archivo Path.join([File.cwd!(), "data", "feedback.csv"])

  # ============================================================
  # FUNCIONES PÚBLICAS PRINCIPALES
  # ============================================================

  @doc """
  Guarda una retroalimentación en el sistema.
  Si ya existe una con el mismo ID, se reemplaza.
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
  Devuelve todas las retroalimentaciones registradas.
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
  Obtiene una retroalimentación específica por su ID.
  """
  def obtener_feedback(id) do
    listar_feedbacks()
    |> Enum.find(&(&1.id == id))
  end

  @doc """
  Lista todas las retroalimentaciones asociadas a un proyecto.
  """
  def listar_por_proyecto(proyecto_id) do
    listar_feedbacks()
    |> Enum.filter(&(&1.proyecto_id == proyecto_id))
  end

  @doc """
  Lista todas las retroalimentaciones hechas por un mentor específico.
  """
  def listar_por_mentor(mentor_id) do
    listar_feedbacks()
    |> Enum.filter(&(&1.autor_id == mentor_id))
  end

  @doc """
  Elimina una retroalimentación del registro.
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
  defp persistir_lista(lista) do
    File.mkdir_p!("data")

    contenido =
      lista
      |> Enum.map(&serializar_feedback/1)
      |> Enum.join("\n")

    File.write!(@data_file, contenido)
  end

  @doc false
  defp serializar_feedback(%Feedback{} = feedback) do
    [
      feedback.id,
      feedback.proyecto_id || "",
      feedback.autor_id || "",
      limpiar(feedback.titulo),
      limpiar(feedback.comentario),
      feedback.puntaje || 0,
      feedback.tipo || "general",
      serialize_timestamp(feedback.fecha),
      serialize_json(feedback.adjuntos)
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
      comentario,
      puntaje,
      tipo,
      fecha,
      adjuntos_json
    ] =
      String.split(linea, ",", parts: 9)

    %Feedback{
      id: id,
      proyecto_id: parse_blank(proyecto_id),
      autor_id: parse_blank(autor_id),
      titulo: titulo,
      comentario: comentario,
      puntaje: parse_integer(puntaje),
      tipo: tipo,
      fecha: parse_timestamp(fecha),
      adjuntos: parse_json(adjuntos_json)
    }
  end

  # ============================================================
  # FUNCIONES AUXILIARES DE SERIALIZACIÓN
  # ============================================================

  @doc false
  defp limpiar(nil), do: ""
  defp limpiar(texto), do: texto |> String.replace(",", ";") |> String.trim()

  @doc false
  defp parse_blank(""), do: nil
  defp parse_blank(valor), do: valor

  @doc false
  defp parse_integer(""), do: 0
  defp parse_integer(valor), do: String.to_integer(valor)

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

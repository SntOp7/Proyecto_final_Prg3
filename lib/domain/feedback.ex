defmodule ProyectoFinalPrg3.Domain.Feedback do
  @moduledoc """
  Representa un comentario o retroalimentación emitida por un mentor
  hacia un proyecto dentro del sistema de Hackathon.
  Esta retroalimentación es crucial para guiar a los equipos
  en la mejora de sus propuestas y soluciones.
  """

  defstruct [
    :id,             # Identificador único de la retroalimentación
    :mentor_id,      # ID del mentor que emite el comentario
    :proyecto_id,    # ID del proyecto al que se dirige la retroalimentación
    :contenido,      # Texto del comentario
    :fecha_creacion  # Fecha en que se registró el feedback
  ]

  @doc """
  Crea una nueva instancia de `Feedback` con los atributos esenciales.

  ## Parámetros:
    - `id`             → Identificador único.
    - `mentor_id`      → Mentor que emite la retroalimentación.
    - `proyecto_id`    → Proyecto que recibe la retroalimentación.
    - `contenido`      → Texto del comentario.
    - `fecha_creacion` → Momento de creación del registro.

  ## Ejemplo:
      iex> Feedback.nuevo("fb1", "m1", "prj1", "Buen avance", NaiveDateTime.utc_now())
  """
  def nuevo(id, mentor_id, proyecto_id, contenido, fecha_creacion) do
    %__MODULE__{
      id: id,
      mentor_id: mentor_id,
      proyecto_id: proyecto_id,
      contenido: contenido,
      fecha_creacion: fecha_creacion
    }
  end
end

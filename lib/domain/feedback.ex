defmodule ProyectoFinalPrg3.Domain.Feedback do
  @moduledoc """
  Representa un comentario o retroalimentación emitida por un mentor
  hacia un proyecto dentro del sistema de Hackathon.
  Esta retroalimentación es crucial para guiar a los equipos
  en la mejora de sus propuestas y soluciones.
  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """
  @derive Jason.Encoder
  defstruct [
    # Identificador único de la retroalimentación
    :id,
    # ID del mentor que emite el comentario
    :mentor_id,
    # ID del proyecto al que se dirige la retroalimentación
    :proyecto_id,
    # Texto del comentario
    :contenido,
    # Fecha en que se registró el feedback
    :fecha_creacion
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

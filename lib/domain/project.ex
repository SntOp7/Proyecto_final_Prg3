defmodule ProyectoFinalPrg3.Domain.Project do
  @moduledoc """
  Representa un **proyecto de hackathon**, asociado a un equipo, un mentor y
  una categoría temática.

  Esta versión ha sido reducida a los campos **realmente necesarios** para:

    - Persistencia en CSV
    - Integración con CategoryService
    - Integración con TeamStore y Mentor/Participant
    - CLI
    - Evaluación y seguimiento básico del proyecto

  ## Campos esenciales
    - `:id` — Identificador único del proyecto.
    - `:nombre` — Nombre del proyecto.
    - `:descripcion` — Resumen general del proyecto.
    - `:categoria` — Categoría temática.
    - `:estado` — Estado (`:en_desarrollo`, `:completado`, etc.).
    - `:fecha_creacion` — Fecha de registro.
    - `:equipo_id` — Equipo dueño del proyecto.
    - `:mentor_id` — Mentor asignado.
    - `:repositorio_url` — Enlace externo al código (opcional).
    - `:puntaje` — Calificación final opcional.

  NOTA IMPORTANTE:
  - Los avances NO se guardan en este struct.
  - La retroalimentación y comentarios se manejan por `Progress`.
  """

  defstruct [
    :id,
    :nombre,
    :descripcion,
    :categoria,
    :estado,
    :fecha_creacion,
    :equipo_id,
    :mentor_id,
    :repositorio_url,
    :puntaje
  ]

  @doc """
  Constructor oficial del dominio para un proyecto.

  ## Parámetros mínimos:
    - `id`
    - `nombre`
    - `descripcion`
    - `categoria`
    - `estado`
    - `fecha_creacion`
    - `equipo_id`
    - `mentor_id`

  ## Parámetros opcionales:
    - `repositorio_url` (por defecto `nil`)
    - `puntaje` (por defecto `nil`)
  """
  def nuevo(
        id,
        nombre,
        descripcion,
        categoria,
        estado,
        fecha_creacion,
        equipo_id,
        mentor_id,
        repositorio_url \\ nil,
        puntaje \\ nil
      ) do
    %__MODULE__{
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      categoria: categoria,
      estado: estado,
      fecha_creacion: fecha_creacion,
      equipo_id: equipo_id,
      mentor_id: mentor_id,
      repositorio_url: repositorio_url,
      puntaje: puntaje
    }
  end
end

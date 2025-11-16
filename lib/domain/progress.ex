defmodule ProyectoFinalPrg3.Domain.Progress do
  @moduledoc """
  Representa un registro de **avance** dentro de un proyecto de hackathon.

  Esta estructura ha sido reducida a los **atributos mínimos realmente necesarios**
  para soportar:
    - Persistencia (CSV)
    - Servicios del proyecto/equipos
    - CLI
    - Versionado del avance
    - Proceso de revisión por mentores

  ## Campos esenciales
    - `:id` — Identificador único del avance.
    - `:proyecto_id` — Proyecto al que pertenece.
    - `:equipo_id` — Equipo que registró el avance.
    - `:titulo` — Título corto del avance.
    - `:descripcion` — Detalle del trabajo realizado.
    - `:fecha_registro` — Fecha del registro.
    - `:autor_id` — Participante que creó el avance.
    - `:estado` — Estado del avance (`:pendiente`, `:revision`, `:aprobado`).
    - `:version` — Número o etiqueta de versión.

  ## Campos opcionales útiles
    - `:retroalimentacion` — Comentarios del mentor (si existen).
    - `:adjuntos` — Lista de URLs o archivos relacionados.

  """

  defstruct [
    :id,
    :proyecto_id,
    :equipo_id,
    :titulo,
    :descripcion,
    :fecha_registro,
    :autor_id,
    :estado,
    :version,
    retroalimentacion: nil,
    adjuntos: []
  ]

  @doc """
  Constructor simplificado para avances.

  ## Parámetros mínimos requeridos:
    - `id`
    - `proyecto_id`
    - `equipo_id`
    - `titulo`
    - `descripcion`
    - `fecha_registro`
    - `autor_id`
    - `estado`
    - `version`

  Los campos opcionales son:
    - `retroalimentacion`
    - `adjuntos`

  """
  def nuevo(
        id,
        proyecto_id,
        equipo_id,
        titulo,
        descripcion,
        fecha_registro,
        autor_id,
        estado,
        version,
        retroalimentacion \\ nil,
        adjuntos \\ []
      ) do
    %__MODULE__{
      id: id,
      proyecto_id: proyecto_id,
      equipo_id: equipo_id,
      titulo: titulo,
      descripcion: descripcion,
      fecha_registro: fecha_registro,
      autor_id: autor_id,
      estado: estado,
      version: version,
      retroalimentacion: retroalimentacion,
      adjuntos: adjuntos || []
    }
  end
end

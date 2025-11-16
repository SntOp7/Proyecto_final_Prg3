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

  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """
  @derive Jason.Encoder
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
  Constructor para crear un nuevo registro de avance.
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

defmodule ProyectoFinalPrg3.Domain.Team do
  @moduledoc """
  Representa un **equipo de la hackathon** dentro del dominio.

  Esta versión contiene únicamente los campos necesarios para:
    - Persistencia en CSV
    - Asignación de participantes
    - Relación con proyectos
    - Relación con mentores
    - CLI y servicios centrales

  ## Campos esenciales:
    - `:id`              — Identificador único del equipo.
    - `:nombre`          — Nombre del equipo.
    - `:descripcion`     — Breve descripción del equipo.
    - `:categoria`       — Categoría temática asignada.
    - `:id_proyecto`     — Proyecto asociado (1 a 1).
    - `:id_mentor`       — Mentor responsable.
    - `:participantes`   — Lista de IDs de participantes.
    - `:fecha_creacion`  — Fecha de formación.
    - `:estado`          — Estado (`:activo`, `:inactivo`, `:disuelto`).

  NOTA:
  - No incluye historial, puntaje ni canal de chat.
  - La mensajería se maneja por BroadcastService, no por el dominio.
  """

  defstruct [
    :id,
    :nombre,
    :descripcion,
    :categoria,
    :id_proyecto,
    :id_mentor,
    :participantes,
    :fecha_creacion,
    :estado
  ]

  @doc """
  Constructor oficial del dominio Team.

  Los parámetros opcionales (descripcion, participantes) pueden ser nil o listas vacías.
  """
  def nuevo(
        id,
        nombre,
        descripcion,
        categoria,
        id_proyecto,
        id_mentor,
        participantes \\ [],
        fecha_creacion,
        estado
      ) do
    %__MODULE__{
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      categoria: categoria,
      id_proyecto: id_proyecto,
      id_mentor: id_mentor,
      participantes: participantes || [],
      fecha_creacion: fecha_creacion,
      estado: estado
    }
  end
end

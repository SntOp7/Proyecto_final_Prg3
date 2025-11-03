defmodule ProyectofinalPrg3.Domain.Progress do
   @moduledoc """
    Este módulo define la estructura y el comportamiento asociados al **avance (progress)**
    dentro del dominio del sistema de hackathon.

    Un **avance** representa un registro formal del progreso alcanzado por un equipo o
    participante dentro de un proyecto. Permite documentar logros, retroalimentaciones
    y versiones del desarrollo, contribuyendo al seguimiento de la evolución del proyecto.

    ### Contexto de dominio
    Cada avance forma parte de un proyecto y está asociado tanto a un equipo responsable
    como a un participante autor. Además, contiene metadatos que describen su estado,
    adjuntos relevantes y observaciones de revisión o mentoría.

    Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
    Fecha de creación: 2025-10-25
    Fecha de última modificación:
    Licencia: GNU GPLv3
  """
  defstruct [
  :id,                 # Identificador único del avance
  :proyecto_id,        # ID del proyecto al que pertenece
  :equipo_id,          # ID del equipo responsable del avance
  :titulo,             # Título breve del avance
  :descripcion,        # Descripción detallada del progreso realizado
  :fecha_registro,     # Fecha en que se reportó el avance
  :autor_id,           # ID del participante que registró el avance
  :estado,             # Estado del avance (pendiente, en revisión, aprobado)
  :retroalimentacion,  # Comentarios o notas del mentor
  :adjuntos,           # Archivos o enlaces relacionados con el avance
  :version             # Número o etiqueta de versión del avance
  ]

  @doc """
  Crea una nueva instancia de un avance dentro del sistema de hackathon.

  Esta función actúa como un **constructor** del dominio, permitiendo inicializar
  una estructura `%Progress{}` con todos los campos definidos, la cual representa
  un registro documentado del progreso de un equipo o participante.

  ### Parámetros
  - `id` → Identificador único del avance.
  - `proyecto_id` → ID del proyecto al que pertenece el avance.
  - `equipo_id` → ID del equipo responsable del avance.
  - `titulo` → Título breve que identifica el avance.
  - `descripcion` → Descripción detallada del trabajo o logro alcanzado.
  - `fecha_registro` → Fecha en la que se reporta el avance (tipo `Date` o `NaiveDateTime`).
  - `autor_id` → ID del participante que crea o reporta el avance.
  - `estado` → Estado actual del avance (`"pendiente"`, `"en revisión"`, `"aprobado"`).
  - `retroalimentacion` → Comentarios del mentor o evaluador (puede ser `nil`).
  - `adjuntos` → Lista de archivos, URLs o recursos relacionados (puede ser vacía).
  - `version` → Número o etiqueta de versión del avance (`"v1.0"`, `"v2.1"`, etc.).

  ### Retorna
  Devuelve una estructura del tipo `%Proyecto_final_Prg3.Domain.Progress{}` con todos los
  campos inicializados.
  """
  def nuevo(id, proyecto_id, equipo_id, titulo, descripcion, fecha_registro, autor_id, estado,
   retroalimentacion, adjuntos, version) do
    %__MODULE__{id: id, proyecto_id: proyecto_id, equipo_id: equipo_id, titulo: titulo, descripcion: descripcion,
    fecha_registro: fecha_registro, autor_id: autor_id, estado: estado, retroalimentacion: retroalimentacion, adjuntos: adjuntos, version: version
  }
  end
end

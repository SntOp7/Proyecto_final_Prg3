defmodule ProyectofinalPrg3.Domain.Category do

  @moduledoc """

  ## Módulo: `ProyectofinalPrg3.Domain.Category`

  Este módulo define la estructura y comportamiento de una **categoría (Category)** dentro
  del dominio del sistema de hackathon.

  Una **categoría** representa un ámbito temático o área de enfoque bajo la cual se agrupan
  los proyectos participantes. Su función es facilitar la organización, clasificación y
  evaluación de las propuestas presentadas según su propósito o campo de aplicación.

  ### Contexto de dominio
  Las categorías permiten:
  - Organizar los proyectos por **temáticas específicas** (por ejemplo: Educación, Salud, Medio Ambiente, Innovación Social, etc.).
  - **Filtrar y evaluar** las propuestas de forma más justa y contextual.
  - Facilitar la **asignación de mentores** y jurados especializados por campo.
  - Promover la **diversidad de soluciones** dentro del evento hackathon.

  Cada categoría puede tener múltiples proyectos asociados, conservar información sobre su creador,
  y mantenerse activa o inactiva según la gestión de los administradores del sistema.


  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-25
  Fecha de última modificación:
  Licencia: GNU GPLv3
  """

  defstruct [
  :id,                # Identificador único de la categoría
  :nombre,            # Nombre de la categoría (ej: Educación, Salud, Medio Ambiente)
  :descripcion,       # Descripción breve del enfoque o propósito de la categoría
  :proyectos,         # Lista de IDs o structs de proyectos asociados
  :fecha_creacion,    # Fecha en que se creó la categoría
  :creador_id,        # ID del usuario o administrador que la definió
  :activo             # Booleano: indica si la categoría está activa o no
  ]

  @doc"""
  Crea una nueva instancia de la estructura `Category` con los atributos especificados.

  ## Parámetros:
    - `id`: Identificador único de la categoría.
    - `nombre`: Nombre descriptivo de la categoría.
    - `descripcion`: Breve explicación del propósito o alcance de la categoría.
    - `proyectos`: Lista de identificadores o estructuras de proyectos asociados.
    - `fecha_creacion`: Fecha de registro o creación de la categoría.
    - `creador_id`: ID del usuario o administrador responsable de su creación.
    - `activo`: Valor booleano que indica si la categoría está habilitada o no dentro del sistema.
  """

  def nuevo(id, nombre, descripcion, proyectos, fecha_creacion, creador_id, activo) do
    %__MODULE__{id: id, nombre: nombre, descripcion: descripcion, proyectos: proyectos, fecha_creacion: fecha_creacion, creador_id: creador_id, activo: activo}
  end
end

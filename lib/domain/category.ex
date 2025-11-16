defmodule ProyectoFinalPrg3.Domain.Category do


  @moduledoc """
  Representa una categoría temática dentro del sistema de Hackathon.

  Una categoría permite clasificar y organizar proyectos por áreas
  de enfoque tales como: Educación, Salud, Medio Ambiente, etc.

  Esta versión optimizada conserva únicamente los atributos esenciales
  necesarios para satisfacer los requisitos del dominio.

  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3

  """

  @derive Jason.Encoder

  defstruct [
    # Identificador único de la categoría
    :id,
    # Nombre de la categoría (Educación, Salud, etc.)
    :nombre,
    # Explicación breve del propósito o enfoque
    :descripcion
  ]

  @doc """
  Crea una nueva instancia de `Category`.

  ## Parámetros:
    - `id`: Identificador único.
    - `nombre`: Nombre de la categoría.
    - `descripcion`: Breve descripción del enfoque.

  ## Ejemplo:
      iex> Category.nuevo("cat1", "Salud", "Soluciones para servicios médicos")
  """
  def nuevo(id, nombre, descripcion) do
    %__MODULE__{
      id: id,
      nombre: nombre,
      descripcion: descripcion
    }
  end
end

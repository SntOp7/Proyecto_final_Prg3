defmodule ProyectoFinalPrg3.Domain.Mentor do
  @moduledoc """
  Representa un mentor dentro del sistema de Hackathon.

  Esta versión optimizada contiene únicamente los atributos esenciales
  requeridos por los módulos de autenticación, registro y emisión de
  retroalimentación, según los requisitos del proyecto académico.
  """

  defstruct [
    :id,          # Identificador único del mentor
    :nombre,      # Nombre completo del mentor
    :correo,      # Correo electrónico
    :contrasena,  # Contraseña para autenticación
    :rol,         # Rol (mentor)
    :especialidad # Área profesional o técnica del mentor
  ]

  @doc """
  Crea una nueva instancia del dominio `Mentor`.

  ## Parámetros:
    - `id`           → Identificador único.
    - `nombre`       → Nombre completo del mentor.
    - `correo`       → Correo electrónico.
    - `contrasena`   → Contraseña del mentor.
    - 'rol'         -> rol
    - `especialidad` → Área de experiencia profesional.

  ## Ejemplo:
      iex> Mentor.nuevo("m1", "Ana Torres", "ana@hackathon.com", "1234", "mentor" "IA")
  """
  def nuevo(id, nombre, correo, contrasena, rol, especialidad) do
    %__MODULE__{
      id: id,
      nombre: nombre,
      correo: correo,
      contrasena: contrasena,
      rol: rol,
      especialidad: especialidad
    }
  end
end

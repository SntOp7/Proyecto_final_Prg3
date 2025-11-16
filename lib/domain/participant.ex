defmodule ProyectoFinalPrg3.Domain.Participant do
  @moduledoc """
  Estructura del participante dentro del dominio del sistema.

  Esta versión está alineada con la estructura usada por:
    - ParticipantStore
    - AuthService
    - TeamManager
    - Mox y behaviours de pruebas

  No incluye el campo :contrasena dentro del struct,
  ya que la contraseña cifrada se maneja únicamente en la capa de servicios
  (AuthService + EncryptionAdapter).
  """

  defstruct [
    :id,
    :nombre,
    :correo,
    :username,
    :rol,
    :equipo_id,
    :experiencia,
    :fecha_registro,
    :estado,
    :ultima_conexion,
    :mensajes,
    :canales_asignados,
    :token_sesion,
    :perfil_url
  ]

  @doc """
  Constructor con la aridad exacta utilizada por todo el sistema: 14 parámetros.

  Este constructor es usado por:
    - ParticipantManager
    - TeamManager
    - AuthService (luego añade contrasena cifrada por separado)
    - ParticipantStore
    - Los tests con Mox

  Todos los campos de lista se normalizan para evitar errores.
  """

  def nuevo(
        id,
        nombre,
        correo,
        username,
        rol,
        equipo_id,
        experiencia,
        fecha_registro,
        estado,
        ultima_conexion,
        mensajes,
        canales_asignados,
        token_sesion,
        perfil_url
      ) do

    %__MODULE__{
      id: id,
      nombre: nombre,
      correo: correo,
      username: username,
      rol: rol,
      equipo_id: equipo_id,
      experiencia: experiencia,
      fecha_registro: fecha_registro,
      estado: estado,
      ultima_conexion: ultima_conexion,
      mensajes: mensajes || [],
      canales_asignados: canales_asignados || [],
      token_sesion: token_sesion,
      perfil_url: perfil_url
    }
  end
end

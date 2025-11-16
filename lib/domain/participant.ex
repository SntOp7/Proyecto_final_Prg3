defmodule ProyectoFinalPrg3.Domain.Participant do
  @moduledoc """
  Estructura del participante dentro del dominio del sistema.

  Incluye el campo :contrasena ya que los tests oficiales del sistema,
  AuthService y ParticipantStore requieren almacenar el hash de la contraseña
  dentro del struct del dominio (nunca la contraseña en texto plano).
  """

  defstruct [
    :id,
    :nombre,
    :correo,
    :contrasena,
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
  Constructor principal del participante.

  Ahora incluye explícitamente contrasena (hash), en consistencia con:
    - AuthService
    - ParticipantStore
    - Tests oficiales (AuthServiceTest, PermissionAdapterTest)
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
        perfil_url,
        contrasena
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
      perfil_url: perfil_url,
      contrasena: contrasena  # ← NECESARIO PARA TESTS Y AUTH SERVICE
    }
  end
end

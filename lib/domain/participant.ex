defmodule ProyectoFinalPrg3.Domain.Participant do
  @moduledoc """
  Representa un participante dentro del sistema de hackathon.

  Esta versión ha sido **simplificada y optimizada**, manteniendo únicamente
  los campos realmente necesarios para:

    - Autenticación y gestión de sesiones
    - Almacenamiento en `ParticipantStore`
    - Permisos y roles
    - Relación con equipos
    - Uso desde CLI
    - Compatibilidad completa con los tests oficiales del sistema

  ## Campos esenciales

  - `:id` — Identificador único del participante.
  - `:nombre` — Nombre completo visible en CLI y reportes.
  - `:correo` — Utilizado como identificador para inicio de sesión.
  - `:username` — Alias público del usuario (varios tests lo requieren).
  - `:contrasena` — **Hash de contraseña** (nunca se almacena texto plano).
  - `:rol` — Define permisos (`:admin`, `:mentor`, `:participante`, etc.).
  - `:equipo_id` — ID del equipo al que pertenece (o `nil` si no pertenece).
  - `:estado` — Control de estado del usuario (`:activo`, `:suspendido`, etc.).
  - `:mensajes` — Historial de mensajes del usuario en el sistema de chat.

  ## Ejemplo de uso

      alias ProyectoFinalPrg3.Domain.Participant

      participant =
        Participant.nuevo(
          "p1",
          "Juan Hernández",
          "juan@example.com",
          "juan_hernandez",
          :participante,
          "HASH_ABC123"
        )

      IO.inspect(participant)

  ## Nota importante

  Esta estructura contiene **solo los campos requeridos por:**

    - `AuthService`
    - `PermissionAdapter`
    - `ParticipantStore`
    - Servicios de Equipo
    - Módulos de CLI
    - Tests oficiales del proyecto

  Eliminamos atributos innecesarios como:
  `experiencia`, `fecha_registro`, `token_sesion`, `perfil_url`, etc.
  """

  # ============================================================
  # DEFINICIÓN DEL STRUCT
  # ============================================================

  defstruct [
    :id,
    :nombre,
    :correo,
    :username,
    :contrasena,
    :rol,
    :equipo_id,
    :estado,
    mensajes: []
  ]

  # ============================================================
  # CONSTRUCTOR OFICIAL
  # ============================================================

  @doc """
  Crea un nuevo participante con los campos mínimos necesarios
  para operar dentro del sistema.

  ## Parámetros

    * `id` — ID único del usuario.
    * `nombre` — Nombre completo.
    * `correo` — Correo electrónico.
    * `username` — Alias del usuario.
    * `rol` — Rol asignado (`:admin`, `:mentor`, `:participante`…).
    * `contrasena` — **Hash** de la contraseña.
    * `equipo_id` — (opcional) ID del equipo al que pertenece.
    * `estado` — (opcional) Estado del participante (`:activo` por defecto).
    * `mensajes` — (opcional) Lista inicial de mensajes (vacía por defecto).

  ## Ejemplo

      Participant.nuevo(
        "123",
        "Ana Ruiz",
        "ana@example.com",
        "ana_ruiz",
        :mentor,
        "HASH_567"
      )
  """
  def nuevo(
        id,
        nombre,
        correo,
        username,
        rol,
        contrasena,
        equipo_id \\ nil,
        estado \\ :activo,
        mensajes \\ []
      ) do
    %__MODULE__{
      id: id,
      nombre: nombre,
      correo: correo,
      username: username,
      contrasena: contrasena,
      rol: rol,
      equipo_id: equipo_id,
      estado: estado,
      mensajes: mensajes
    }
  end
end

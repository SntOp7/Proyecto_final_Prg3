defmodule ProyectoFinalPrg3.Domain.Participant do
  @moduledoc """
  Define la estructura y comportamiento del **participante** dentro del dominio del sistema de hackathon.

  Un **Participante** representa a cada miembro que forma parte de la hackathon, ya sea como
  desarrollador, diseñador, líder de equipo o mentor. Su información permite gestionar
  autenticación, rol, actividad, conexión y pertenencia a equipos o canales de comunicación.

  Este módulo pertenece a la **capa de dominio**, y se utiliza principalmente en:
  - `AuthService` → para autenticación y gestión de sesiones.
  - `ParticipantManager` → para administración de participantes.
  - `ParticipantStore` → para persistencia en disco o base de datos.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-25
  Última modificación: 2025-11-03
  Licencia: GNU GPLv3
  """

  defstruct [
    :id,                 # Identificador único del participante
    :nombre,             # Nombre completo del participante
    :correo,             # Correo electrónico (usado también para autenticación)
    :username,           # Nombre de usuario dentro de la plataforma
    :contrasena,         # 🔹 Contraseña cifrada (no en texto plano)
    :rol,                # Rol dentro de la hackathon (participante, líder, organizador, mentor, etc.)
    :equipo_id,          # ID del equipo al que pertenece
    :experiencia,        # Breve descripción o nivel de experiencia
    :fecha_registro,     # Fecha en que se unió al sistema
    :estado,             # Estado actual (:activo, :desconectado, :pendiente)
    :ultima_conexion,    # Timestamp de la última vez que estuvo en línea
    :mensajes,           # Lista o referencia a mensajes enviados
    :canales_asignados,  # Canales en los que participa (equipos, salas, mentorías)
    :token_sesion,       # Token de sesión (para autenticación y seguridad)
    :perfil_url          # Enlace a la foto o perfil público
  ]

  @doc """
  Crea un nuevo registro de tipo `Participante` con los atributos especificados.

  ## Parámetros:
    - `id` — Identificador único del participante.
    - `nombre` — Nombre completo.
    - `correo` — Correo electrónico asociado.
    - `username` — Nombre de usuario en la plataforma.
    - `contrasena` — Contraseña **ya cifrada** mediante `EncryptionAdapter`.
    - `rol` — Rol del usuario (`"participante"`, `"líder"`, `"organizador"`, etc.).
    - `equipo_id` — Identificador del equipo al que pertenece.
    - `experiencia` — Descripción del nivel o área de experiencia.
    - `fecha_registro` — Fecha de registro en el sistema.
    - `estado` — Estado actual (`:activo`, `:pendiente`, `:inactivo`).
    - `ultima_conexion` — Fecha/hora de la última sesión.
    - `mensajes` — Mensajes enviados.
    - `canales_asignados` — Canales o grupos donde participa.
    - `token_sesion` — Token de sesión generado al autenticarse.
    - `perfil_url` — URL de la foto o perfil.

  ## Retorna:
  Un struct `%Participant{}` correctamente formado.
  """
  def nuevo(
        id,
        nombre,
        correo,
        username,
        contrasena,
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
      contrasena: contrasena,
      rol: rol,
      equipo_id: equipo_id,
      experiencia: experiencia,
      fecha_registro: fecha_registro,
      estado: estado,
      ultima_conexion: ultima_conexion,
      mensajes: mensajes,
      canales_asignados: canales_asignados,
      token_sesion: token_sesion,
      perfil_url: perfil_url
    }
  end
end

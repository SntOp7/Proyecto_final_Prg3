defmodule Proyecto_final_Prg3.Domain.Participant do
    @moduledoc """
     Define la estructura y comportamiento del **participante** dentro del dominio del sistema de hackathon.

    Un **Participante** representa a cada miembro que forma parte de la hackathon, ya sea como
    desarrollador, diseñador, líder de equipo u organizador. Su información permite gestionar
    su rol, actividad, conexión y pertenencia a equipos y canales de comunicación.

    Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
    Fecha de creación: 2025-10-25
    Fecha de última modificación:
    Licencia: GNU GPLv3
  """
   defstruct [
    :id,                 # Identificador único del participante
    :nombre,             # Nombre completo del participante
    :correo,             # Correo electrónico (usado también para autenticación)
    :username,           # Nombre de usuario dentro de la plataforma
    :rol,                # Rol dentro de la hackathon (ej: participante, líder, organizador)
    :equipo_id,          # ID del equipo al que pertenece
    :experiencia,        # Breve descripción o nivel de experiencia
    :fecha_registro,     # Fecha en que se unió al sistema
    :estado,             # Estado actual (activo, desconectado, pendiente)
    :ultima_conexion,    # Timestamp de la última vez que estuvo en línea
    :mensajes,           # Lista o referencia a mensajes enviados
    :canales_asignados,  # Canales en los que participa (equipos, salas, mentoría)
    :token_sesion,       # Token de sesión (para autenticación y seguridad)
    :perfil_url          # Enlace a la foto o perfil público
   ]


  @doc """

  Crea un nuevo registro de tipo `Participante` con los atributos especificados.

  ## Parámetros
    - `id` — Identificador único del participante.
    - `nombre` — Nombre completo del participante.
    - `correo` — Correo electrónico asociado (también utilizado para autenticación).
    - `username` — Nombre de usuario dentro de la plataforma.
    - `rol` — Rol que desempeña dentro de la hackathon (`"participante"`, `"líder"`, `"organizador"`, etc.).
    - `equipo_id` — Identificador del equipo al que pertenece.
    - `experiencia` — Breve descripción del nivel o área de experiencia del participante.
    - `fecha_registro` — Fecha de incorporación al sistema.
    - `estado` — Estado actual (`:activo`, `:desconectado`, `:pendiente`).
    - `ultima_conexion` — Fecha y hora de la última sesión activa.
    - `mensajes` — Lista de mensajes enviados o su referencia.
    - `canales_asignados` — Lista de canales (equipos, salas, mentorías) donde participa.
    - `token_sesion` — Token de sesión generado para autenticación.
    - `perfil_url` — Enlace al perfil o imagen del participante.
  """



  def nuevo(id, nombre, correo, username, rol, equipo_id, experiencia, fecha_registro, estado,
   ultima_conexion, mensajes, canales_asignados, token_sesion, perfil_url) do
    %__MODULE__{id: id, nombre: nombre, correo: correo, username: username, rol: rol, equipo_id: equipo_id, experiencia: experiencia,
    fecha_registro: fecha_registro, estado: estado, ultima_conexion: ultima_conexion, mensajes: mensajes,
    canales_asignados: canales_asignados, token_sesion: token_sesion, perfil_url: perfil_url}
  end

end

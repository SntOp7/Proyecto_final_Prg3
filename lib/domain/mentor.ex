defmodule ProyectoFinalPrg3.Domain.Mentor do
  @moduledoc """
  Define la estructura y comportamiento del **mentor** dentro del dominio del proyecto.
  Un **Mentor** representa una figura de apoyo técnico o metodológico en el sistema de hackathon,
  responsable de guiar equipos, brindar retroalimentación y mantener comunicación activa
  a través de un canal asignado.
  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-25
  Fecha de última modificación:
  Licencia: GNU GPLv3
  """

  @doc """
  Campos del struct:
    - `:id` — Identificador único del mentor.
    - `:nombre` — Nombre completo del mentor.
    - `:correo` — Correo electrónico de contacto.
    - `:especialidad` — Área de experiencia (ej: IA, Backend, UX/UI, etc.).
    - `:biografia` — Breve descripción del perfil profesional del mentor.
    - `:equipos_asignados` — Lista de IDs o estructuras de equipos asesorados.
    - `:disponibilidad` — Estado actual (`:disponible`, `:ocupado`, `:desconectado`).
    - `:canal_mentoria_id` — Identificador del canal de mentoría asignado.
    - `:fecha_registro` — Fecha de registro en el sistema.
    - `:retroalimentaciones` — Lista o referencia a las retroalimentaciones realizadas.
    - `:rol` — Rol o tipo de mentor (ej. técnico, metodológico, general).
    - `:activo` — Booleano que indica si el mentor sigue participando activamente en la hackathon.
  """
  defstruct [
    :id,                  # Identificador único del mentor
    :nombre,              # Nombre completo del mentor
    :correo,              # Correo electrónico de contacto
    :especialidad,        # Área de experiencia (ej: IA, backend, UX/UI, etc.)
    :biografia,           # Descripción breve del perfil del mentor
    :equipos_asignados,   # Lista de IDs o structs de equipos que asesora
    :disponibilidad,      # Estado actual (disponible, ocupado, desconectado)
    :canal_mentoria_id,   # ID del canal de mentoría asignado
    :fecha_registro,      # Fecha en que fue registrado en el sistema
    :retroalimentaciones, # Lista o referencia a feedbacks dados
    :rol,                 # Tipo de mentor
    :activo               # Booleano: indica si sigue participando en la hackathon
   ]


    @doc """
    Crea un nuevo registro de tipo Mentor con los atributos especificados.

    - Parámetros
    - `id` — Identificador único del mentor.
    - `nombre` — Nombre completo del mentor.
    - `correo` — Dirección de correo electrónico.
    - `especialidad` — Área de experiencia profesional.
    - `biografia` — Breve descripción del perfil profesional.
    - `equipos_asignados` — Lista de equipos o identificadores que asesora.
    - `disponibilidad` — Estado actual del mentor (`:disponible`, `:ocupado`, etc.).
    - `canal_mentoria_id` — ID del canal de comunicación asignado.
    - `fecha_registro` — Fecha de incorporación al sistema.
    - `retroalimentaciones` — Lista de retroalimentaciones o su referencia.
    - `rol` — Rol o tipo de mentor dentro de la hackathon.
    - `activo` — Booleano que indica si continúa participando.
    """
   def nuevo(id, nombre, correo, especialidad, biografia, equipos_asignados, disponibilidad, canal_mentoria_id, fecha_registro, retroalimentaciones, rol, activo) do
     %__MODULE__{id: id, nombre: nombre, correo: correo, especialidad: especialidad, biografia: biografia,
     equipos_asignados: equipos_asignados, disponibilidad: disponibilidad, canal_mentoria_id: canal_mentoria_id,
     fecha_registro: fecha_registro, retroalimentaciones: retroalimentaciones, rol: rol, activo: activo}
   end
end

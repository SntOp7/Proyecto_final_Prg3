defmodule ProyectoFinalPrg3.Domain.Project do

  @moduledoc """
  Define la estructura y comportamiento del **proyecto** dentro del dominio del sistema de hackathon.

  Un **Proyecto** representa la propuesta o solución tecnológica desarrollada por un equipo,
  la cual está asociada a un mentor, un repositorio de código y un conjunto de avances o
  retroalimentaciones que reflejan su evolución durante el evento hackaton.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-25
  Fecha de última modificación:
  Licencia: GNU GPLv3
  """

  defstruct [
    :id,                  # Identificador único del proyecto
    :nombre,               # Nombre del proyecto
    :descripcion,          # Descripción general de la idea
    :categoria,            # Categoría del proyecto (educación, salud, ambiente, etc.)
    :estado,               # Estado actual (en_desarrollo, completado, pausado)
    :fecha_creacion,       # Fecha de registro del proyecto
    :fecha_actualizacion,  # Última modificación o avance registrado
    :equipo_id,            # ID del equipo al que pertenece
    :mentor_id,            # ID del mentor asociado
    :avances,              # Lista de avances (referencia al módulo Avance)
    :retroalimentaciones,  # Lista de feedbacks o comentarios (referencia a Feedback/Historial)
    :repositorio_url,      # Enlace al repositorio del código (GitHub, GitLab, etc.)
    :puntaje,              # Puntuación o calificación final (opcional)
    :visibilidad,          # Pública o privada (para control de acceso)
    :tags                  # Lista de etiquetas o palabras clave relacionadas
  ]

  @doc"""
   Crea un nuevo registro de tipo Project con los atributos especificados.

  ## Parámetros
    - `id` — Identificador único del proyecto.
    - `nombre` — Nombre oficial del proyecto.
    - `descripcion` — Descripción general de la idea o solución propuesta.
    - `categoria` — Categoría temática (ej. educación, salud, ambiente, tecnología, etc.).
    - `estado` — Estado actual (`:en_desarrollo`, `:completado`, `:pausado`).
    - `fecha_creacion` — Fecha en la que se registró el proyecto.
    - `fecha_actualizacion` — Última fecha de modificación o avance.
    - `equipo_id` — Identificador del equipo propietario.
    - `mentor_id` — Identificador del mentor asignado.
    - `avances` — Lista de avances registrados (puede referenciar a otro módulo).
    - `retroalimentaciones` — Lista de comentarios o feedback del mentor.
    - `repositorio_url` — Enlace al repositorio del proyecto (GitHub, GitLab, etc.).
    - `puntaje` — Calificación final o puntuación obtenida (opcional).
    - `visibilidad` — Define si el proyecto es `:publico` o `:privado`.
    - `tags` — Lista de etiquetas relacionadas con el contenido o propósito del proyecto.

  """
  def nuevo(id, nombre, descripcion, categoria, estado, fecha_creacion, fecha_actualizacion, equipo_id, mentor_id, avances,
  retroalimentaciones, repositorio_url, puntaje, visibilidad, tags) do

    %__MODULE__{id: id, nombre: nombre, descripcion: descripcion, categoria: categoria, estado: estado, fecha_creacion: fecha_creacion,
    fecha_actualizacion: fecha_actualizacion, equipo_id: equipo_id, mentor_id: mentor_id, avances: avances,
    retroalimentaciones: retroalimentaciones, repositorio_url: repositorio_url, puntaje: puntaje, visibilidad: visibilidad,
     tags: tags}

  end
end

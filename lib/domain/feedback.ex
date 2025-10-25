defmodule Proyecto_final_Prg3.Domain.Feedback do

  @moduledoc """

   ## Módulo: `Proyecto_final_Prg3.Domain.Feedback`

  Este módulo define la estructura y el comportamiento de la **retroalimentación (Feedback)** dentro
  del dominio del sistema de hackathon.

  Un **feedback** representa la evaluación, comentario o sugerencia emitida por un **mentor** hacia
  un proyecto o equipo participante, con el fin de mejorar su desarrollo, corregir errores o
  reconocer avances significativos durante el evento.

  ### Contexto de dominio
  La retroalimentación constituye un elemento clave en la dinámica del hackathon, ya que:
  - Facilita el **acompañamiento pedagógico y técnico** de los mentores hacia los equipos.
  - Permite **registrar observaciones** sobre avances específicos o sobre el proyecto general.
  - Contribuye a la **evaluación continua** del desempeño del equipo o participante.
  - Puede clasificarse por **nivel** o **intención comunicativa**, como informativa, correctiva o de reconocimiento.

  Cada retroalimentación se asocia a un **mentor**, un **proyecto** y, opcionalmente, a un **avance**
  particular registrado en el sistema. Asimismo, puede tener distinta visibilidad según las reglas
  del evento (pública o privada).

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-25
  Fecha de última modificación:
  Licencia: GNU GPLv3
  """

  defstruct [
  :id,                # Identificador único del feedback
  :mentor_id,         # ID del mentor que emite la retroalimentación
  :proyecto_id,       # ID del proyecto al que pertenece
  :equipo_id,         # ID del equipo asociado (si aplica)
  :avance_id,         # ID del avance específico que se comenta (opcional)
  :contenido,         # Texto de la retroalimentación
  :fecha_creacion,    # Fecha y hora en que se registró
  :nivel,             # Tipo o nivel del feedback (informativo, corrección, elogio)
  :visibilidad,       # Privado (solo equipo) o público (visible en el canal)
  :estado,            # Estado del feedback (pendiente, revisado, aplicado)
  ]


  @doc """

  Crea una nueva instancia de una **retroalimentación (Feedback)** en el dominio del hackathon.

  Esta función actúa como un **constructor** para inicializar una estructura `%Feedback{}`,
  representando la observación o comentario emitido por un mentor sobre un proyecto o avance.

  ### Parámetros
  - `id` → Identificador único del feedback.
  - `mentor_id` → ID del mentor que genera la retroalimentación.
  - `proyecto_id` → ID del proyecto que recibe el feedback.
  - `equipo_id` → ID del equipo asociado (puede ser `nil` si el feedback es general).
  - `avance_id` → ID del avance específico comentado (opcional).
  - `contenido` → Texto descriptivo del comentario o sugerencia.
  - `fecha_creacion` → Fecha y hora en que se registró el feedback (`NaiveDateTime`).
  - `nivel` → Clasificación del feedback según su tipo (`"informativo"`, `"corrección"`, `"elogio"`).
  - `visibilidad` → Define el alcance del comentario (`"privado"` o `"público"`).
  - `estado` → Estado actual de la retroalimentación (`"pendiente"`, `"revisado"`, `"aplicado"`).

  ### Retorna
  Una estructura `%Proyecto_final_Prg3.Domain.Feedback{}` completamente inicializada con la información
  correspondiente al comentario emitido.

  """
  def nuevo(id, mentor_id, proyecto_id, equipo_id, avance_id, contenido, fecha_creacion, nivel, visibilidad, estado) do
    %__MODULE__{id: id, mentor_id: mentor_id, proyecto_id: proyecto_id, equipo_id: equipo_id, avance_id: avance_id, contenido: contenido,
  fecha_creacion: fecha_creacion, nivel: nivel, visibilidad: visibilidad, estado: estado}
  end
end

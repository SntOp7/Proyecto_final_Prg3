defmodule ProyectoFinalPrg3.Domain.Message do
  @moduledoc """
  ## Módulo: `Proyecto_final_Prg3.Domain.Message`

  Este módulo define la estructura y el comportamiento del **mensaje** dentro del dominio
  del sistema de hackathon.

  Un **mensaje** representa una unidad de comunicación dentro de los canales, equipos o proyectos
  de la plataforma. Permite la interacción entre participantes, el intercambio de archivos,
  notificaciones del sistema y seguimiento de la actividad colaborativa durante el evento.

  ### Contexto de dominio
  Los mensajes son el núcleo de la comunicación asincrónica y en tiempo real en el hackathon.
  Pueden pertenecer a diferentes tipos de canales (equipo, mentoría, general, privado) y
  estar asociados a participantes, equipos o proyectos. Asimismo, pueden incorporar metadatos
  como reacciones, estado de lectura y archivos adjuntos.

    Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
    Fecha de creación: 2025-10-25
    Fecha de última modificación:
    Licencia: GNU GPLv3

  """

  defstruct [

  :id,                # Identificador único del mensaje
  :remitente_id,      # ID del participante que envía el mensaje
  :canal_id,          # ID del canal o sala donde se envía
  :contenido,         # Texto o cuerpo del mensaje
  :timestamp,         # Fecha y hora de envío
  :tipo,              # Tipo de mensaje (texto, archivo, sistema, notificación)
  :adjunto_url,       # Enlace a archivo adjunto (opcional)
  :equipo_id,         # ID del equipo asociado (si aplica)
  :proyecto_id,       # ID del proyecto relacionado (si aplica)
  :leido_por,         # Lista de IDs de participantes que lo han leído
  :reacciones         # Lista de reacciones (emojis, likes, etc.)
  ]

  @doc """
  Crea una nueva instancia de un **mensaje** dentro del dominio del sistema de hackathon.

  Esta función actúa como **constructor** del dominio, inicializando una estructura `%Message{}`
  con todos los campos que describen un mensaje enviado por un participante dentro de un canal o proyecto.

  ### Parámetros
  - `id` → Identificador único del mensaje.
  - `remitente_id` → ID del participante que envía el mensaje.
  - `canal_id` → ID del canal o sala donde se publica el mensaje.
  - `contenido` → Texto o cuerpo del mensaje.
  - `timestamp` → Fecha y hora exacta en que se envía (tipo `NaiveDateTime`).
  - `tipo` → Tipo de mensaje (`"texto"`, `"archivo"`, `"sistema"`, `"notificación"`).
  - `adjunto_url` → Enlace al archivo adjunto (puede ser `nil` si no aplica).
  - `equipo_id` → ID del equipo asociado al mensaje (si aplica).
  - `proyecto_id` → ID del proyecto relacionado al mensaje (si aplica).
  - `leido_por` → Lista de IDs de los participantes que han leído el mensaje.
  - `reacciones` → Lista de reacciones (emojis o respuestas rápidas).

  ### Retorna
  Una estructura del tipo `%Proyecto_final_Prg3.Domain.Message{}` completamente inicializada.
  """
  def nuevo(id, remitente_id, canal_id, contenido, timestamp, tipo, adjunto_url, equipo_id, proyecto_id, leido_por, reacciones) do
    %__MODULE__{id: id, remitente_id: remitente_id, canal_id: canal_id, contenido: contenido, timestamp: timestamp, tipo: tipo,
  adjunto_url: adjunto_url, equipo_id: equipo_id, proyecto_id: proyecto_id, leido_por: leido_por, reacciones: reacciones}
  end
end

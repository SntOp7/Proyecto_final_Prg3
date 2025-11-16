defmodule ProyectoFinalPrg3.Domain.Message do
  @moduledoc """
  Representa un mensaje enviado dentro de un canal del sistema de Hackathon.

  Esta versión optimizada contiene únicamente los atributos esenciales
  requeridos para la comunicación por canales según los requisitos
  del proyecto académico.
  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """
  @derive Jason.Encoder
  defstruct [
    # Identificador único del mensaje
    :id,
    # ID del participante que envía el mensaje
    :remitente_id,
    # ID del canal donde se publica
    :canal_id,
    # Texto del mensaje
    :contenido,
    # Fecha y hora de envío
    :timestamp
  ]

  @doc """
  Crea una nueva instancia de `Message`.

  ## Parámetros:
    - `id`           → Identificador único.
    - `remitente_id` → Participante que envía el mensaje.
    - `canal_id`     → Canal donde se publica.
    - `contenido`    → Texto del mensaje.
    - `timestamp`    → Fecha de emisión.

  ## Ejemplo:
      iex> Message.nuevo("msg1", "user1", "canal_general", "Hola a todos", NaiveDateTime.utc_now())
  """
  def nuevo(id, remitente_id, canal_id, contenido, timestamp) do
    %__MODULE__{
      id: id,
      remitente_id: remitente_id,
      canal_id: canal_id,
      contenido: contenido,
      timestamp: timestamp
    }
  end
end

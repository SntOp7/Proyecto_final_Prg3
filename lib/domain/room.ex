defmodule Proyecto_final_Prg3.Domain.Room do

  @moduledoc """
  ## Módulo: `Proyecto_final_Prg3.Domain.Room`

  Este módulo define la estructura y comportamiento de una **sala de comunicación (Room)** dentro
  del dominio del sistema de hackathon.

  Una **sala** representa un espacio virtual de interacción entre los participantes, mentores y
  organizadores del evento. Su función principal es agrupar mensajes, gestionar la comunicación
  temática o por equipos, y mantener un registro histórico de las conversaciones que ocurren
  dentro del sistema colaborativo.

  ### Contexto de dominio
  Las salas pueden tener diferentes propósitos según su tipo:
  - **Equipo:** comunicación interna entre los miembros de un mismo grupo.
  - **Mentoría:** canal exclusivo entre mentores y equipos asignados.
  - **Temática:** espacio general para debatir sobre áreas específicas (IA, diseño, sostenibilidad, etc.).
  - **General o del sistema:** canal abierto a todos los usuarios o para anuncios oficiales.

  Cada sala mantiene su lista de participantes activos, sus mensajes asociados, y metadatos
  sobre su creación y estado actual.
  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-25
  Fecha de última modificación:
  Licencia: GNU GPLv3
  """
  defstruct [
  :id,                # Identificador único de la sala
  :nombre,            # Nombre de la sala o tema de conversación
  :descripcion,       # Breve descripción del propósito de la sala
  :tipo,              # Tipo de sala (equipo, temática, general, mentoría)
  :participantes,     # Lista de IDs o structs de participantes dentro de la sala
  :mensajes,          # Lista o referencia a los mensajes asociados
  :fecha_creacion,    # Fecha de creación de la sala
  :creador_id,        # ID del participante que la creó
  :estado,            # Estado de la sala (activa, cerrada, archivada)
  :canal_id           # ID del canal asociado en el sistema de comunicación
  ]


  @doc"""

  Crea una nueva instancia de una **sala de comunicación (Room)** dentro del sistema de hackathon.

  Esta función inicializa la estructura `%Room{}` con los campos necesarios para representar
  un canal de interacción entre los participantes, equipos o mentores.

  ### Parámetros
  - `id`: Identificador único de la sala.
  - `nombre`: Nombre o tema central de la sala.
  - `descripcion`: Texto breve que explica la finalidad de la sala.
  - `tipo`: Tipo de sala (por ejemplo: `"equipo"`, `"mentoría"`, `"general"`, `"temática"`).
  - `participantes`: Lista de IDs o estructuras de los usuarios que participan en la sala.
  - `mensajes`: Colección o referencia a los mensajes que pertenecen a esta sala.
  - `fecha_creacion`: Fecha en que se creó la sala.
  - `creador_id`: ID del usuario que creó la sala.
  - `estado`: Estado actual de la sala (`"activa"`, `"cerrada"`, `"archivada"`).
  - `canal_id`: Identificador del canal de comunicación asignado dentro del sistema.

  ### Retorna
  Una estructura `%Proyecto_final_Prg3.Domain.Room{}` completamente inicializada.

  """
  def nuevo(id, nombre, descripcion, tipo, participantes, mensajes, fecha_creacion, creador_id, estado, canal_id) do
    %__MODULE__{id: id, nombre: nombre, descripcion: descripcion, tipo: tipo, participantes: participantes,
    mensajes: mensajes, fecha_creacion: fecha_creacion, creador_id: creador_id, estado: estado, canal_id: canal_id}
  end
end

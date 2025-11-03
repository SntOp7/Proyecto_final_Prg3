defmodule ProyectoFinalPrg3.Domain.Team do


  defstruct [:id, :nombre, :descripcion, :categoria, :id_proyecto, :id_mentor, :participantes,
  :fecha_creacion, :estado, :canal_chat_id, :puntaje, :historial]

  def nuevo(id, nombre, descripcion, categoria, id_proyecto, id_mentor, participantes, fecha_creacion, estado, canal_chat_id, puntaje, historial) do
    %__MODULE__{id: id, nombre: nombre, descripcion: descripcion, categoria: categoria, id_proyecto: id_proyecto,
     id_mentor: id_mentor, participantes: participantes, fecha_creacion: fecha_creacion, estado: estado,
      canal_chat_id: canal_chat_id, puntaje: puntaje, historial: historial}
  end



end

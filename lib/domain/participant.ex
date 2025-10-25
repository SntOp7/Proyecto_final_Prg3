defmodule Proyecto_final_prg3.Domain.Participante do
  defstruct [:id, :nombre, :correo]

  def nuevo(id, nombre, correo) do
    %__MODULE__{id: id, nombre: nombre, correo: correo}
  end

end

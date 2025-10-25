defmodule Proyecto_final_Prg3.Domain.Participant do
  defstruct [:id, :nombre, :correo]

  def nuevo(id, nombre, correo) do
    %__MODULE__{id: id, nombre: nombre, correo: correo}
  end

end

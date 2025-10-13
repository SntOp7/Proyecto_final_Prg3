defmodule Proyecto_final_prg3.Domain.Participante do
  defstruct [:id, :nombre, :correo, :rol]

  def nuevo(id, nombre, correo, rol) do
    %_MODULE_{id: id, nombre: nombre, correo: correo, rol: rol}
  end

end

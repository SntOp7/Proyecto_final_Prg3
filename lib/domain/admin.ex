defmodule ProyectoFinalPrg3.Domain.Admin do
  @moduledoc """
  Representa a un administrador del sistema.
  """

  @enforce_keys [:id, :nombre, :correo, :username, :contrasena, :rol]
  defstruct [:id, :nombre, :correo, :username, :contrasena, :rol]

  @type t :: %__MODULE__{
          id: String.t(),
          nombre: String.t(),
          correo: String.t(),
          username: String.t(),
          contrasena: String.t(),
          rol: atom()
        }
end

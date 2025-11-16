defmodule ProyectoFinalPrg3.Adapters.Security.EncryptionAdapterBehaviour do
  @moduledoc """
  Behaviour que define las operaciones de cifrado y verificación de contraseñas.
  """

  @callback cifrar(String.t()) :: String.t()
  @callback verificar(String.t(), String.t()) :: boolean()
end

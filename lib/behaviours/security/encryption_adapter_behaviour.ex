defmodule ProyectoFinalPrg3.Adapters.Security.EncryptionAdapterBehaviour do
  @moduledoc "Behaviour para cifrado/verificación de contraseñas."

  @callback cifrar(String.t()) :: String.t()
  @callback verificar(String.t(), String.t()) :: boolean()
end

defmodule ProyectoFinalPrg3.Adapters.Security.PermissionAdapterBehaviour do
  @moduledoc "Behaviour para comprobación de permisos."

  @callback autorizado?(String.t(), [String.t()]) :: {:ok, :permitido} | {:error, :no_autorizado}
end

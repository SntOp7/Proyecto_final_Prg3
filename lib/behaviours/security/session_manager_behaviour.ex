defmodule ProyectoFinalPrg3.Adapters.Security.SessionManagerBehaviour do
  @moduledoc """
  Behaviour para la gestión de sesiones de usuario.
  """

  @callback activar_sesion(String.t(), String.t()) :: :ok | {:error, any()}
  @callback validar_sesion(String.t()) :: {:ok, String.t()} | {:error, any()}
  @callback revocar_sesion(String.t()) :: :ok
end

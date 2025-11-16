defmodule ProyectoFinalPrg3.Adapters.Security.SessionManagerBehaviour do
  @moduledoc "Behaviour para gestión de sesiones (ETS)."

  @callback activar_sesion(String.t(), String.t()) :: :ok | {:error, any()}
  @callback validar_sesion(String.t()) :: {:ok, String.t()} | {:error, any()}
  @callback revocar_sesion(String.t()) :: :ok
  @callback obtener_participante_actual() :: String.t() | nil
end

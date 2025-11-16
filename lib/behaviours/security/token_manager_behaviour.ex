defmodule ProyectoFinalPrg3.Adapters.Security.TokenManagerBehaviour do
  @moduledoc "Behaviour para gestión de tokens."

  @callback generar_token(String.t()) :: {:ok, String.t()} | {:error, any()}
  @callback validar_token(String.t()) :: {:ok, String.t()} | {:error, any()}
end

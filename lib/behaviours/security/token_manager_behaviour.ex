defmodule ProyectoFinalPrg3.Adapters.Security.TokenManagerBehaviour do
  @moduledoc """
  Behaviour para la creación y validación de tokens de acceso.
  """

  @callback generar_token(String.t()) :: {:ok, String.t()} | {:error, any()}
  @callback validar_token(String.t()) :: {:ok, String.t()} | {:error, any()}
end

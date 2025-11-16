defmodule ProyectoFinalPrg3.Services.AuthServiceBehaviour do
  @moduledoc "Behaviour para el servicio de autenticación."

  @callback registrar_participante(String.t(), String.t(), String.t(), String.t(), any()) ::
              {:ok, map()} | {:error, any()}

  @callback autenticar(String.t(), String.t()) :: {:ok, map()} | {:error, any()}
  @callback obtener_participante(String.t()) :: {:ok, map()} | {:error, any()}
end

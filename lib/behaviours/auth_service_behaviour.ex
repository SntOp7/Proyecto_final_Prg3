defmodule ProyectoFinalPrg3.Services.AuthServiceBehaviour do
  @moduledoc """
  Behaviour genérico para el servicio de autenticación.

  Define las funciones que pueden ser mockeadas en las pruebas con Mox.
  """

  @callback autenticar(username :: String.t(), password :: String.t()) ::
              {:ok, map()} | {:error, :credenciales_invalidas}

  @callback registrar_usuario(params :: map()) ::
              {:ok, map()} | {:error, term()}

  @callback cerrar_sesion(id_usuario :: String.t()) :: :ok

  @callback usuario_actual() ::
              {:ok, map()} | {:error, :no_sesion}
end

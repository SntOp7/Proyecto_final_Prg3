defmodule ProyectoFinalPrg3.Adapters.Security.PermissionAdapterBehaviour do
  @moduledoc """
  Behaviour para el adaptador de permisos del sistema.

  Define las funciones que deben ser implementadas por cualquier
  adaptador que maneje validación de permisos y que será mockeado
  mediante Mox en las pruebas.
  """

  @callback autorizado?(id_usuario :: String.t(), permiso :: atom()) ::
              boolean()
end

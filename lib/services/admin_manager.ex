defmodule ProyectoFinalPrg3.Services.AdminManager do
  @moduledoc """
  Servicio de gestión de administradores.
  Permite extraer admins del sistema y obtener sus datos.
  """

  alias ProyectoFinalPrg3.Adapters.Persistence.AdminStore

  # ------------------------------------------------------------
  # API
  # ------------------------------------------------------------

  def obtener_admin(id_admin) when is_binary(id_admin) do
    AdminStore.obtener_admin(id_admin)
  end

  def listar_admins do
    AdminStore.listar_admins()
  end
end

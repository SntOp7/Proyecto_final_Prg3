defmodule ProyectoFinalPrg3.Services.AdminManager do
  @moduledoc """
  Servicio de gestión de administradores.
  Permite extraer admins del sistema y obtener sus datos.
  Este servicio actúa como intermediario entre los controladores y la capa de persistencia.
  Proporciona funciones para obtener un administrador por su ID y listar todos los administradores.
  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  alias ProyectoFinalPrg3.Adapters.Persistence.AdminStore

  # ------------------------------------------------------------
  # API
  # ------------------------------------------------------------

  @doc """
  Obtiene un administrador por su ID.
  ## Parámetros
    - id_admin: ID del administrador (string).
  ## Retorna
    - {:ok, admin} si se encuentra el administrador.
    - {:error, :not_found} si no se encuentra el administrador.
  """
  def obtener_admin(id_admin) when is_binary(id_admin) do
    AdminStore.obtener_admin(id_admin)
  end

  @doc """
  Lista todos los administradores.
  ## Retorna
    - Lista de administradores.
  """
  def listar_admins do
    AdminStore.listar_admins()
  end
end

defmodule ProyectoFinalPrg3.Adapters.Persistence.AdminStore do
  @moduledoc """
  Capa de persistencia para administradores.
  Extrae admins desde el CSV de participantes.
  """

  alias ProyectoFinalPrg3.Domain.Admin

  @file_path "data/participantes.csv"

  # ------------------------------------------------------------
  # API PRINCIPAL
  # ------------------------------------------------------------

  def obtener_admin(id_admin) do
    case cargar_admins() |> Enum.find(&(&1.id == id_admin)) do
      nil -> {:error, :admin_no_encontrado}
      admin -> {:ok, admin}
    end
  end

  def listar_admins, do: cargar_admins()

  # ------------------------------------------------------------
  # PARSEO DEL CSV
  # ------------------------------------------------------------

  defp cargar_admins do
    if File.exists?(@file_path) do
      @file_path
      |> File.stream!()
      |> CSV.decode!(headers: true)
      |> Enum.filter(fn row -> row["rol"] == "admin" end)
      |> Enum.map(&mapear_admin/1)
    else
      []
    end
  end

  defp mapear_admin(row) do
    %Admin{
      id: row["id"],
      nombre: row["nombre"],
      correo: row["correo"],
      username: row["username"],
      contrasena: row["contrasena"],
      rol: :admin
    }
  end
end

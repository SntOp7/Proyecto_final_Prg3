defmodule ProyectoFinalPrg3.Adapters.Security.PermissionAdapterTest do
  use ExUnit.Case, async: true

  alias ProyectoFinalPrg3.Adapters.Security.PermissionAdapter
  alias ProyectoFinalPrg3.Services.AuthService
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  import Mox

  setup :verify_on_exit!

  describe "tiene_permiso?/2" do
    test "retorna true si el rol tiene acceso a la acción" do
      assert PermissionAdapter.tiene_permiso?(:admin, :crear_equipo)
      assert PermissionAdapter.tiene_permiso?(:mentor, :ver_proyecto)
      assert PermissionAdapter.tiene_permiso?(:participante, :unirse_equipo)
    end

    test "retorna false si el rol no tiene permiso para la acción" do
      refute PermissionAdapter.tiene_permiso?(:mentor, :gestionar_usuarios)
      refute PermissionAdapter.tiene_permiso?(:participante, :eliminar_equipo)
      refute PermissionAdapter.tiene_permiso?(:admin, :accion_inexistente)
    end

    test "retorna false si el rol no existe" do
      refute PermissionAdapter.tiene_permiso?(:invitado, :ver_proyecto)
    end
  end

  describe "listar_permisos/1" do
    test "retorna todas las acciones válidas por rol" do
      permisos = PermissionAdapter.listar_permisos(:admin)
      assert :crear_equipo in permisos
      assert :eliminar_equipo in permisos
      assert length(permisos) > 0
    end

    test "retorna lista vacía si el rol no existe" do
      assert PermissionAdapter.listar_permisos(:fantasma) == []
    end
  end

  describe "autorizado?/2" do
    setup do
      # Mock del AuthService y LoggerService para aislar la lógica
      AuthServiceMock
      |> expect(:obtener_participante, fn "123" ->
        {:ok, %{id: "123", rol: "mentor"}}
      end)

      LoggerServiceMock
      |> expect(:registrar_evento, 1, fn _msg, _data -> :ok end)

      :ok
    end

    test "retorna {:ok, :permitido} si el usuario tiene permiso" do
      assert PermissionAdapter.autorizado?("123", :ver_proyecto) == {:ok, :permitido}
    end

    test "retorna {:error, :no_autorizado} si el usuario no tiene permisos" do
      AuthServiceMock
      |> expect(:obtener_participante, fn "999" ->
        {:ok, %{id: "999", rol: "participante"}}
      end)

      LoggerServiceMock
      |> expect(:registrar_evento, 1, fn _msg, _data -> :ok end)

      assert PermissionAdapter.autorizado?("999", :asignar_mentor) == {:error, :no_autorizado}
    end

    test "retorna {:error, :no_autorizado} si el usuario no existe" do
      AuthServiceMock
      |> expect(:obtener_participante, fn _ -> {:error, :no_encontrado} end)

      LoggerServiceMock
      |> expect(:registrar_evento, 1, fn _msg, _data -> :ok end)

      assert PermissionAdapter.autorizado?("noexiste", :ver_proyecto) == {:error, :no_autorizado}
    end

    test "invoca el logger tanto en caso de éxito como de error" do
      AuthServiceMock
      |> expect(:obtener_participante, fn "ok" -> {:ok, %{rol: "admin"}} end)
      |> expect(:obtener_participante, fn "fail" -> {:error, :no_autorizado} end)

      LoggerServiceMock
      |> expect(:registrar_evento, 2, fn _msg, _data -> :ok end)

      PermissionAdapter.autorizado?("ok", :crear_equipo)
      PermissionAdapter.autorizado?("fail", :eliminar_equipo)
    end

    test "lanza error si el argumento no es válido" do
      assert_raise FunctionClauseError, fn ->
        PermissionAdapter.autorizado?(123, :ver_proyecto)
      end
    end
  end
end

defmodule ProyectoFinalPrg3.Adapters.Security.SessionManagerTest do
  use ExUnit.Case, async: true

  alias ProyectoFinalPrg3.Adapters.Security.SessionManager
  alias ProyectoFinalPrg3.Adapters.Security.TokenManager
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  import Mox

  setup :verify_on_exit!

  setup do
    # Reiniciar ETS antes de cada prueba
    :ets.delete_all_objects(:sesiones_activas)
    SessionManager.start_link(nil)
    :ok
  end

  describe "activar_sesion/2" do
    test "registra una sesión en ETS correctamente" do
      LoggerServiceMock
      |> expect(:registrar_evento, fn "Sesión activada", %{usuario: "u1"} -> :ok end)

      assert SessionManager.activar_sesion("u1", "token123") == :ok
      assert :ets.lookup(:sesiones_activas, "u1") != []
    end

    test "lanza error si los parámetros no son binarios" do
      assert_raise FunctionClauseError, fn -> SessionManager.activar_sesion(:id, 123) end
    end
  end

  describe "validar_sesion/1" do
    test "retorna {:ok, id_usuario} si el token es válido y existe en ETS" do
      TokenManagerMock
      |> expect(:validar_token, fn "token123" -> {:ok, "user1"} end)

      LoggerServiceMock
      |> expect(:registrar_evento, 1, fn _, _ -> :ok end)

      SessionManager.activar_sesion("user1", "token123")

      assert SessionManager.validar_sesion("token123") == {:ok, "user1"}
    end

    test "retorna {:error, :token_invalido} si el token no está registrado" do
      TokenManagerMock
      |> expect(:validar_token, fn "fake" -> {:ok, "userX"} end)

      assert SessionManager.validar_sesion("fake") == {:error, :token_invalido}
    end

    test "retorna {:error, :token_invalido} si el token es inválido" do
      TokenManagerMock
      |> expect(:validar_token, fn "token_malo" -> {:error, :invalido} end)

      assert SessionManager.validar_sesion("token_malo") == {:error, :token_invalido}
    end
  end

  describe "revocar_sesion/1" do
    test "elimina la sesión existente correctamente" do
      LoggerServiceMock
      |> expect(:registrar_evento, fn "Sesión activada", _ -> :ok end)
      |> expect(:registrar_evento, fn "Sesión cerrada", _ -> :ok end)

      SessionManager.activar_sesion("u1", "token123")
      assert :ets.lookup(:sesiones_activas, "u1") != []

      assert SessionManager.revocar_sesion("u1") == :ok
      assert :ets.lookup(:sesiones_activas, "u1") == []
    end

    test "retorna {:error, :no_sesion} si el usuario no tiene sesión" do
      assert SessionManager.revocar_sesion("no_user") == {:error, :no_sesion}
    end
  end

  describe "sesion_activa?/1" do
    test "retorna true si el usuario tiene sesión activa" do
      LoggerServiceMock
      |> expect(:registrar_evento, fn "Sesión activada", _ -> :ok end)

      SessionManager.activar_sesion("u1", "tok")
      assert SessionManager.sesion_activa?("u1") == true
    end

    test "retorna false si el usuario no tiene sesión" do
      refute SessionManager.sesion_activa?("desconocido")
    end
  end

  describe "obtener_participante_actual/0" do
    test "retorna el id del primer usuario con sesión activa" do
      LoggerServiceMock
      |> expect(:registrar_evento, fn "Sesión activada", _ -> :ok end)

      SessionManager.activar_sesion("u123", "tokenxyz")
      assert SessionManager.obtener_participante_actual() == "u123"
    end

    test "retorna nil si no hay sesiones activas" do
      assert SessionManager.obtener_participante_actual() == nil
    end
  end
end

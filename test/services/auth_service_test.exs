defmodule ProyectoFinalPrg3.Test.Services.AuthServiceTest do
  use ExUnit.Case, async: true
  import Mox

  alias ProyectoFinalPrg3.Services.AuthService
  alias ProyectoFinalPrg3.Domain.Participant

  @moduledoc """
  Pruebas unitarias para `AuthService`.

  Se validan los principales casos de uso del servicio de autenticación:
  - Registro de nuevos participantes.
  - Autenticación y generación de token.
  - Cierre de sesión.
  - Validación de token y obtención de datos.
  - Verificación de roles autorizados.

  Los adaptadores de seguridad y persistencia son simulados con `Mox` para
  garantizar aislamiento y reproducibilidad.
  """

  setup :verify_on_exit!

  # ===================================================================
  # Mocks simulados
  # ===================================================================

  setup do
    Application.put_env(:proyecto_final_prg3, :participant_store, self())
    Application.put_env(:proyecto_final_prg3, :token_manager, self())
    Application.put_env(:proyecto_final_prg3, :session_manager, self())
    Application.put_env(:proyecto_final_prg3, :encryption_adapter, self())
    :ok
  end

  # ===================================================================
  # Pruebas de registro
  # ===================================================================

  describe "registrar_participante/4" do
    test "registra un nuevo participante si el correo no existe" do
      expect(ParticipantStoreMock, :buscar_por_correo, fn _ -> nil end)
      expect(EncryptionAdapterMock, :cifrar, fn "1234" -> "hashed1234" end)
      expect(ParticipantStoreMock, :guardar_participante, fn p -> p end)

      {:ok, participante} =
        AuthService.registrar_participante("Juan Pérez", "juan@example.com", "1234", "participante")

      assert %Participant{} = participante
      assert participante.correo == "juan@example.com"
      assert participante.contrasena == "hashed1234"
      assert participante.rol == "participante"
    end

    test "retorna error si el correo ya está registrado" do
      expect(ParticipantStoreMock, :buscar_por_correo, fn _ -> %Participant{} end)

      assert {:error, :correo_ya_registrado} =
               AuthService.registrar_participante("Ana", "ana@example.com", "abcd")
    end
  end

  # ===================================================================
  # Pruebas de autenticación
  # ===================================================================

  describe "autenticar/2" do
    setup do
      participante = %Participant{id: "p1", correo: "test@user.com", contrasena: "hashedpwd"}
      %{p: participante}
    end

    test "retorna token si las credenciales son válidas", %{p: p} do
      expect(ParticipantStoreMock, :buscar_por_correo, fn _ -> p end)
      expect(EncryptionAdapterMock, :verificar, fn "1234", "hashedpwd" -> true end)
      expect(TokenManagerMock, :generar_token, fn "p1" -> "token123" end)
      expect(SessionManagerMock, :activar_sesion, fn "p1", "token123" -> :ok end)
      expect(ParticipantStoreMock, :actualizar_estado, fn "p1", true -> :ok end)

      {:ok, %{participante: result, token: token}} = AuthService.autenticar("test@user.com", "1234")
      assert result.id == "p1"
      assert token == "token123"
    end

    test "falla si el usuario no existe" do
      expect(ParticipantStoreMock, :buscar_por_correo, fn _ -> nil end)

      assert {:error, :usuario_no_encontrado} = AuthService.autenticar("no@user.com", "1234")
    end

    test "falla si la contraseña es incorrecta", %{p: p} do
      expect(ParticipantStoreMock, :buscar_por_correo, fn _ -> p end)
      expect(EncryptionAdapterMock, :verificar, fn _, _ -> false end)

      assert {:error, :contrasena_invalida} = AuthService.autenticar("test@user.com", "wrong")
    end
  end

  # ===================================================================
  # Pruebas de sesión
  # ===================================================================

  describe "cerrar_sesion/1" do
    test "revoca la sesión y actualiza estado" do
      expect(SessionManagerMock, :revocar_sesion, fn "p1" -> :ok end)
      expect(ParticipantStoreMock, :actualizar_estado, fn "p1", false -> :ok end)

      assert {:ok, :sesion_cerrada} = AuthService.cerrar_sesion("p1")
    end
  end

  # ===================================================================
  # Validación de token y roles
  # ===================================================================

  describe "validar_token/1 y es_autorizado?/2" do
    test "retorna participante válido si el token es correcto" do
      expect(TokenManagerMock, :validar_token, fn "token123" -> {:ok, "p1"} end)
      expect(ParticipantStoreMock, :obtener_participante, fn "p1" -> %Participant{id: "p1"} end)

      assert {:ok, %Participant{id: "p1"}} = AuthService.validar_token("token123")
    end

    test "devuelve error si el token no es válido" do
      expect(TokenManagerMock, :validar_token, fn _ -> {:error, :token_invalido} end)
      assert {:error, :token_invalido} = AuthService.validar_token("fake")
    end

    test "valida si un usuario tiene rol autorizado" do
      expect(ParticipantStoreMock, :obtener_participante, fn "p1" -> %Participant{id: "p1", rol: "mentor"} end)
      assert AuthService.es_autorizado?("p1", ["mentor", "admin"])
    end

    test "retorna falso si el usuario no tiene rol permitido" do
      expect(ParticipantStoreMock, :obtener_participante, fn "p2" -> %Participant{id: "p2", rol: "participante"} end)
      refute AuthService.es_autorizado?("p2", ["mentor"])
    end
  end
end

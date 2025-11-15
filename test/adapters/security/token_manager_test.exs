defmodule ProyectoFinalPrg3.Adapters.Security.TokenManagerTest do
  use ExUnit.Case, async: true

  alias ProyectoFinalPrg3.Adapters.Security.TokenManager
  alias ProyectoFinalPrg3.Adapters.Security.EncryptionAdapter

  import Mox

  setup :verify_on_exit!

  describe "generar_token/1" do
    test "genera un token Base64 válido con formato esperado" do
      EncryptionAdapterMock
      |> expect(:crear_contraseña, fn data -> "HASH-" <> String.slice(data, 0, 8) end)

      {:ok, token} = TokenManager.generar_token("user_123")

      assert is_binary(token)
      assert {:ok, decoded} = Base.decode64(token)
      assert String.starts_with?(decoded, "user_123:")
      assert String.contains?(decoded, ":HASH-")
    end

    test "retorna error si el id_usuario no es binario" do
      assert_raise FunctionClauseError, fn -> TokenManager.generar_token(123) end
    end
  end

  describe "validar_token/1" do
    setup do
      {:ok, ts} = TokenManager.generar_token("demo_user")
      %{token: ts}
    end

    test "valida correctamente un token firmado", %{token: _} do
      # Preparamos un token de ejemplo conocido
      firma = "FAKE_HASH"
      id = "usuarioX"
      timestamp = "1730050000"
      raw = "#{id}:#{timestamp}:#{firma}"
      token = Base.encode64(raw)

      EncryptionAdapterMock
      |> expect(:verificar_contraseña, fn _valor, _hash -> true end)

      assert TokenManager.validar_token(token) == {:ok, id}
    end

    test "retorna error si la firma es inválida" do
      id = "usuarioY"
      ts = "1730000000"
      token = Base.encode64("#{id}:#{ts}:firma_mala")

      EncryptionAdapterMock
      |> expect(:verificar_contraseña, fn _, _ -> false end)

      assert TokenManager.validar_token(token) == {:error, :token_invalido}
    end

    test "retorna error si el token no es Base64 válido" do
      assert TokenManager.validar_token("%%%NO_VALIDO%%%") == {:error, :token_invalido}
    end

    test "retorna error si el token tiene formato incorrecto" do
      token = Base.encode64("sin:partes")
      assert TokenManager.validar_token(token) == {:error, :token_invalido}
    end

    test "retorna error si el parámetro no es binario" do
      assert TokenManager.validar_token(1234) == {:error, :token_invalido}
    end
  end
end

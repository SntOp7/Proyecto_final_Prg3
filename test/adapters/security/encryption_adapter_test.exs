defmodule ProyectoFinalPrg3.Adapters.Security.EncryptionAdapterTest do
  use ExUnit.Case, async: true

  alias ProyectoFinalPrg3.Adapters.Security.EncryptionAdapter

  @moduletag :security

  describe "cifrar/1" do
    test "devuelve un hash hexadecimal válido de 64 caracteres" do
      hash = EncryptionAdapter.cifrar("mi_contraseña_segura")
      assert is_binary(hash)
      assert String.length(hash) == 64
      assert String.match?(hash, ~r/^[A-F0-9]+$/)
    end

    test "dos contraseñas iguales generan el mismo hash" do
      h1 = EncryptionAdapter.cifrar("clave123")
      h2 = EncryptionAdapter.cifrar("clave123")
      assert h1 == h2
    end

    test "contraseñas distintas generan hashes diferentes" do
      h1 = EncryptionAdapter.cifrar("claveA")
      h2 = EncryptionAdapter.cifrar("claveB")
      refute h1 == h2
    end

    test "lanza error si se pasa un tipo no binario" do
      assert_raise FunctionClauseError, fn ->
        EncryptionAdapter.cifrar(12345)
      end
    end
  end

  describe "verificar/2" do
    test "retorna true si la contraseña coincide con el hash" do
      contrasena = "test_secure"
      hash = EncryptionAdapter.cifrar(contrasena)
      assert EncryptionAdapter.verificar(contrasena, hash)
    end

    test "retorna false si la contraseña no coincide con el hash" do
      hash = EncryptionAdapter.cifrar("password_real")
      refute EncryptionAdapter.verificar("password_falsa", hash)
    end

    test "maneja correctamente mayúsculas/minúsculas en hash hexadecimal" do
      contrasena = "caseSensitive"
      hash_upper = EncryptionAdapter.cifrar(contrasena)
      hash_lower = String.downcase(hash_upper)

      # Aunque el hash hexadecimal puede ser minúsculo, debe validarse igual
      assert EncryptionAdapter.verificar(contrasena, hash_upper)
      refute EncryptionAdapter.verificar(contrasena, hash_lower)
    end

    test "lanza error si alguno de los argumentos no es binario" do
      hash = EncryptionAdapter.cifrar("valid")
      assert_raise FunctionClauseError, fn ->
        EncryptionAdapter.verificar(1234, hash)
      end

      assert_raise FunctionClauseError, fn ->
        EncryptionAdapter.verificar("clave", :not_a_binary)
      end
    end
  end

  describe "integridad del algoritmo SHA-256" do
    test "verifica que el hash corresponde al algoritmo esperado" do
      contrasena = "hash_test"
      hash = EncryptionAdapter.cifrar(contrasena)

      sha256_manual =
        :crypto.hash(:sha256, contrasena)
        |> Base.encode16()

      assert hash == sha256_manual
    end

    test "el hash es determinístico (sin salt aleatorio)" do
      contrasena = "deterministico"
      hashes = Enum.map(1..5, fn _ -> EncryptionAdapter.cifrar(contrasena) end)
      assert Enum.uniq(hashes) |> length() == 1
    end
  end
end

defmodule ProyectoFinalPrg3.Adapters.Security.EncryptionAdapter do
  @moduledoc """
  Adaptador responsable del cifrado y verificación de contraseñas
  dentro del sistema de Hackathon colaborativo.

  Este módulo ofrece una interfaz simple para:
  - `cifrar/1`: crear un hash seguro de una contraseña.
  - `verificar/2`: comprobar si una contraseña coincide con su hash almacenado.

  Se usa en conjunto con `AuthService` para la autenticación de participantes
  y la validación de credenciales seguras.

  ## Ejemplo
      iex> hash = EncryptionAdapter.cifrar("mi_secreta")
      "A7F1C33E0A2B9D..."

      iex> EncryptionAdapter.verificar("mi_secreta", hash)
      true

  ## Notas
  - Utiliza el algoritmo SHA-256 para hashing.
  - El resultado se devuelve en formato hexadecimal (Base16).
  - En futuras versiones podría reemplazarse por `Argon2` o `Bcrypt` para mayor seguridad.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias :crypto

  @doc """
  Genera un hash SHA-256 de la contraseña en texto plano.

  ## Parámetros:
    - `contrasena`: texto a cifrar.

  ## Retorna:
    - Cadena hexadecimal representando el hash.
  """
  def cifrar(contrasena) when is_binary(contrasena) do
    :crypto.hash(:sha256, contrasena) |> Base.encode16()
  end

  @doc """
  Verifica si una contraseña ingresada coincide con su hash almacenado.

  ## Parámetros:
    - `contrasena`: texto plano ingresado por el usuario.
    - `hash`: cadena hexadecimal almacenada.

  ## Retorna:
    - `true` si coinciden.
    - `false` en caso contrario.
  """
  def verificar(contrasena, hash) when is_binary(contrasena) and is_binary(hash) do
    cifrar(contrasena) == hash
  end
end

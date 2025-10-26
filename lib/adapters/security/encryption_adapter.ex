defmodule ProyectoFinalPrg3.Adapters.Security.EncryptionAdapter do
  @moduledoc """
  Adaptador responsable de manejar el cifrado y verificación de contraseñas
  dentro del sistema de Hackathon colaborativa.

  Este módulo provee funciones básicas para:
  - Crear un hash seguro de una contraseña.
  - Verificar si una contraseña coincide con su hash almacenado.

  Se utiliza principalmente en los servicios de autenticación (`AuthService`)
  y en el manejo de sesiones (`SessionManager`).

  ## Ejemplo de uso
      iex> hash = EncryptionAdapter.crear_contraseña("mi_secreta")
      "A7F1C33E0A2B9D..."

      iex> EncryptionAdapter.verificar_contraseña("mi_secreta", hash)
      true

  ## Notas
  - Actualmente utiliza el algoritmo SHA-256 como función de hash.
  - Puede reemplazarse en el futuro por `Bcrypt` o `Argon2` para mayor seguridad.
  - Los resultados se devuelven en formato hexadecimal (Base16).

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias :crypto

  @doc """
  Crea un hash seguro a partir de una contraseña en texto plano.

  ## Parámetros:
    - `contraseña`: texto plano que se desea proteger.

  ## Retorna:
    - Cadena hexadecimal representando el hash (SHA-256).

  ## Ejemplo:
      iex> EncryptionAdapter.crear_contraseña("123456")
      "8D969EEF6ECAD3C29A3A629280E686CF..."
  """
  def crear_contraseña(contraseña) when is_binary(contraseña) do
    :crypto.hash(:sha256, contraseña) |> Base.encode16()
  end

  @doc """
  Verifica si una contraseña en texto plano coincide con su hash almacenado.

  ## Parámetros:
    - `contraseña`: texto en claro ingresado por el usuario.
    - `hash`: hash previamente almacenado.

  ## Retorna:
    - `true` si coinciden.
    - `false` en caso contrario.

  ## Ejemplo:
      iex> hash = EncryptionAdapter.crear_contraseña("hola123")
      iex> EncryptionAdapter.verificar_contraseña("hola123", hash)
      true
  """
  def verificar_contraseña(contraseña, hash) when is_binary(contraseña) and is_binary(hash) do
    crear_contraseña(contraseña) == hash
  end
end

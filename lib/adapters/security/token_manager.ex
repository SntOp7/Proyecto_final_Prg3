defmodule ProyectoFinalPrg3.Adapters.Security.TokenManager do
  @moduledoc """
  Módulo encargado de la creación y validación de **tokens de sesión**
  para usuarios autenticados dentro del sistema de hackathon colaborativa.

  Los tokens generados se basan en una firma criptográfica simple
  que incluye el identificador del usuario, un timestamp y una clave secreta.

  Este módulo depende de `EncryptionAdapter` para el hashing seguro de la firma,
  y es utilizado principalmente por `SessionManager` y `AuthService`.

  ## Ejemplo de flujo:
      iex> {:ok, token} = TokenManager.generar_token("user_123")
      iex> TokenManager.validar_token(token)
      {:ok, "user_123"}

  ## Notas de seguridad:
  - Los tokens se generan con una clave interna `@secret`, configurable según el entorno.
  - El esquema no usa JWT estándar, pero puede ampliarse fácilmente para hacerlo.
  - El tiempo de creación se incluye, pero **no se expira automáticamente**.
    (El control de expiración se maneja en `SessionManager`).

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Adapters.Security.EncryptionAdapter

  # Clave secreta usada para firmar los tokens
  @secret "clave-super-secreta"

  # ============================================================
  # FUNCIÓN DE GENERACIÓN DE TOKEN
  # ============================================================

  @doc """
  Genera un token seguro para un usuario autenticado.

  ## Parámetros:
    - `id_usuario`: identificador único del usuario.

  ## Retorna:
    - Cadena codificada en Base64 que contiene el token firmado.

  ## Estructura interna del token (antes de codificar):
      "usuario_id:timestamp:firma"

  ## Ejemplo:
      iex> TokenManager.generar_token("u123")
      {:ok, "dTEyMzoxNzMwMjUwNjE4OkFCR..."}
  """
  def generar_token(id_usuario) when is_binary(id_usuario) do
    timestamp = System.system_time(:second)
    data = "#{id_usuario}:#{timestamp}"
    firma = EncryptionAdapter.crear_contraseña(data <> @secret)
    token = Base.encode64("#{id_usuario}:#{timestamp}:#{firma}")
    {:ok, token}
  end

  # ============================================================
  # FUNCIÓN DE VALIDACIÓN DE TOKEN
  # ============================================================

  def validar_token(_), do: {:error, :token_invalido}

  @doc """
  Valida un token verificando su integridad y firma.

  ## Parámetros:
    - `token`: cadena codificada en Base64 generada por `generar_token/1`.

  ## Retorna:
    - `{:ok, id_usuario}` si el token es válido.
    - `{:error, :token_invalido}` si la firma o el formato no son válidos.

  ## Ejemplo:
      iex> {:ok, token} = TokenManager.generar_token("user_1")
      iex> TokenManager.validar_token(token)
      {:ok, "user_1"}
  """
  def validar_token(token) when is_binary(token) do
    with {:ok, decoded} <- Base.decode64(token),
         [id_usuario, timestamp, firma] <- String.split(decoded, ":"),
         true <- EncryptionAdapter.verificar_contraseña("#{id_usuario}:#{timestamp}#{@secret}", firma) do
      {:ok, id_usuario}
    else
      _ -> {:error, :token_invalido}
    end
  end
end

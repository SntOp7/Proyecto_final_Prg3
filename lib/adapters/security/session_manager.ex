defmodule ProyectoFinalPrg3.Adapters.Security.SessionManager do
  @moduledoc """
  Módulo encargado del manejo de sesiones de usuario dentro del sistema de hackathon.

  Este componente pertenece a la capa **Adapters/Security** y provee
  funciones para iniciar, validar y cerrar sesiones activas de participantes
  autenticados, utilizando los tokens generados por `TokenManager`.

  Es utilizado directamente por `AuthService` para gestionar el inicio y cierre
  de sesión de los usuarios, y por otros servicios (como `TeamManager` o `ChatService`)
  para obtener el usuario actualmente autenticado.

  ## Funcionalidades principales:
    - Iniciar sesión (`iniciar_sesion/1`)
    - Validar sesión (`validar_sesion/1`)
    - Cerrar sesión (`cerrar_sesion/1`)
    - Obtener el usuario actual (`obtener_participante_actual/0`)

  ## Ejemplo de uso:
      iex> {:ok, token} = SessionManager.iniciar_sesion("user_001")
      iex> SessionManager.validar_sesion(token)
      {:ok, "user_001"}
      iex> SessionManager.obtener_participante_actual()
      "user_001"

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Adapters.Security.TokenManager
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # Almacén temporal de sesiones activas (ETS o Agent según necesidad)
  @table :sesiones_activas

  # ============================================================
  # INICIALIZACIÓN
  # ============================================================

  @doc false
  def start_link(_) do
    unless :ets.whereis(@table) != :undefined do
      :ets.new(@table, [:named_table, :public, read_concurrency: true])
    end

    {:ok, self()}
  end

  # ============================================================
  # GESTIÓN DE SESIONES
  # ============================================================

  @doc """
  Inicia una nueva sesión para el usuario especificado, generando un token
  mediante `TokenManager`.

  Guarda la sesión activa en memoria y la retorna al cliente.

  ## Parámetros:
    - `id_usuario`: identificador único del usuario (por ejemplo, su UUID).

  ## Retorna:
    - `{:ok, token}` si la sesión se creó correctamente.
    - `{:error, :no_autorizado}` si hubo un fallo durante la creación.
  """
  def iniciar_sesion(id_usuario) when is_binary(id_usuario) do
    case TokenManager.generar_token(id_usuario) do
      {:ok, token} ->
        :ets.insert(@table, {id_usuario, token, System.system_time(:second)})
        LoggerService.registrar_evento("Sesión iniciada", %{usuario: id_usuario})
        {:ok, token}

      _ ->
        {:error, :no_autorizado}
    end
  end

  @doc """
  Valida si un token corresponde a una sesión activa y legítima.

  ## Parámetros:
    - `token`: cadena codificada en Base64 generada por `TokenManager`.

  ## Retorna:
    - `{:ok, id_usuario}` si la sesión es válida.
    - `{:error, :token_invalido}` si el token no es reconocido o expiró.
  """
  def validar_sesion(token) when is_binary(token) do
    case TokenManager.validar_token(token) do
      {:ok, id_usuario} ->
        case :ets.lookup(@table, id_usuario) do
          [{^id_usuario, ^token, _timestamp}] ->
            {:ok, id_usuario}

          _ ->
            {:error, :token_invalido}
        end

      {:error, _} ->
        {:error, :token_invalido}
    end
  end

  @doc """
  Cierra la sesión activa del usuario, eliminando su registro del sistema.

  ## Parámetros:
    - `id_usuario`: identificador del usuario autenticado.

  ## Retorna:
    - `:ok` si la sesión fue eliminada.
    - `{:error, :no_sesion}` si no había sesión activa.
  """
  def cerrar_sesion(id_usuario) when is_binary(id_usuario) do
    case :ets.lookup(@table, id_usuario) do
      [{^id_usuario, _token, _timestamp}] ->
        :ets.delete(@table, id_usuario)
        LoggerService.registrar_evento("Sesión cerrada", %{usuario: id_usuario})
        :ok

      _ ->
        {:error, :no_sesion}
    end
  end

  # ============================================================
  # CONSULTA DE USUARIO ACTUAL
  # ============================================================

  @doc """
  Retorna el identificador del usuario autenticado actualmente,
  si existe una sesión activa en el proceso actual.

  **Nota:** En una versión distribuida, este método se conectaría
  con un contexto de sesión por proceso (por ejemplo, mediante `Process.put/2`).

  ## Retorna:
    - `id_usuario` si hay sesión activa.
    - `nil` si no existe una sesión registrada.
  """
  def obtener_participante_actual do
    case :ets.tab2list(@table) do
      [{id_usuario, _token, _timestamp} | _] -> id_usuario
      _ -> nil
    end
  end
end

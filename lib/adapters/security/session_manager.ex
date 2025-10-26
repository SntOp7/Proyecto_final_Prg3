defmodule ProyectoFinalPrg3.Adapters.Security.SessionManager do
  @moduledoc """
  Módulo encargado del manejo de sesiones activas de los participantes autenticados.

  Forma parte de la capa **Adapters/Security** y se encarga de:
  - Registrar sesiones activas (`activar_sesion/2`).
  - Validar tokens (`validar_sesion/1`).
  - Revocar sesiones (`revocar_sesion/1`).
  - Comprobar si un usuario tiene una sesión activa (`sesion_activa?/1`).

  Se comunica directamente con:
  - `AuthService` para la autenticación de usuarios.
  - `TokenManager` para la generación y validación de tokens.
  - `LoggerService` para registrar eventos de inicio o cierre de sesión.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Adapters.Security.TokenManager
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

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
  Activa una sesión en el sistema para un usuario autenticado.

  Recibe el `id_usuario` y el `token` ya generado por `AuthService`.

  ## Parámetros:
    - `id_usuario`: identificador único del usuario.
    - `token`: cadena generada por `TokenManager`.

  ## Retorna:
    - `:ok` si la sesión fue registrada correctamente.
  """
  def activar_sesion(id_usuario, token) when is_binary(id_usuario) and is_binary(token) do
    :ets.insert(@table, {id_usuario, token, System.system_time(:second)})
    LoggerService.registrar_evento("Sesión activada", %{usuario: id_usuario})
    :ok
  end

  @doc """
  Valida si un token corresponde a una sesión activa en memoria.
  """
  def validar_sesion(token) when is_binary(token) do
    case TokenManager.validar_token(token) do
      {:ok, id_usuario} ->
        case :ets.lookup(@table, id_usuario) do
          [{^id_usuario, ^token, _timestamp}] -> {:ok, id_usuario}
          _ -> {:error, :token_invalido}
        end

      {:error, _} ->
        {:error, :token_invalido}
    end
  end

  @doc """
  Revoca (cierra) una sesión activa y elimina su registro.
  """
  def revocar_sesion(id_usuario) when is_binary(id_usuario) do
    case :ets.lookup(@table, id_usuario) do
      [{^id_usuario, _token, _timestamp}] ->
        :ets.delete(@table, id_usuario)
        LoggerService.registrar_evento("Sesión cerrada", %{usuario: id_usuario})
        :ok

      _ ->
        {:error, :no_sesion}
    end
  end

  @doc """
  Verifica si un usuario tiene una sesión activa actualmente.
  """
  def sesion_activa?(id_usuario) do
    case :ets.lookup(@table, id_usuario) do
      [{^id_usuario, _token, _timestamp}] -> true
      _ -> false
    end
  end

  @doc """
  Obtiene el usuario actualmente autenticado (si existe una sesión activa).
  """
  def obtener_participante_actual do
    case :ets.tab2list(@table) do
      [{id_usuario, _token, _timestamp} | _] -> id_usuario
      _ -> nil
    end
  end
end

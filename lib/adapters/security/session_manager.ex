defmodule ProyectoFinalPrg3.Adapters.Security.SessionManager do
  @moduledoc """
  Administrador de sesiones basado en ETS.
  La tabla :sesiones_activas se crea al cargar el módulo para garantizar
  su disponibilidad inmediata tanto en ejecución normal como en pruebas.
  Proporciona funciones para activar, validar, revocar y verificar sesiones de usuario.
  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  alias ProyectoFinalPrg3.Adapters.Security.TokenManager
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService
  alias ProyectoFinalPrg3.Services.ParticipantManager

  @table :sesiones_activas

  # ============================================================
  # CREACIÓN DE LA ETS AL CARGAR EL MÓDULO
  # ============================================================

  if :ets.whereis(@table) == :undefined do
    :ets.new(@table, [:named_table, :public, read_concurrency: true])
  end

  # ============================================================
  # GESTIÓN DE SESIONES
  # ============================================================

  @doc """
  Activa una sesión en el sistema para un usuario autenticado.
  Parámetros:
    - `id_usuario`: Identificador único del usuario.
    - `token`: Token JWT asociado a la sesión.
  Retorna:
    - `:ok` tras activar la sesión.
  """
  def activar_sesion(id_usuario, token) when is_binary(id_usuario) and is_binary(token) do
    :ets.insert(@table, {id_usuario, token, System.system_time(:second)})

    LoggerService.registrar_evento("Sesión activada", %{usuario: id_usuario})

    :ok
  end

  @doc """
  Valida si un token corresponde a una sesión activa.
  Parámetros:
    - `token`: Token JWT a validar.
  Retorna:
    - `{:ok, id_usuario}` si el token es válido y corresponde a una sesión activa.
    - `{:error, :token_invalido}` en caso contrario.
  """
  def validar_sesion(token) when is_binary(token) do
    case TokenManager.validar_token(token) do
      {:ok, id_usuario} ->
        case :ets.lookup(@table, id_usuario) do
          [{^id_usuario, ^token, _ts}] -> {:ok, id_usuario}
          _ -> {:error, :token_invalido}
        end

      {:error, _} ->
        {:error, :token_invalido}
    end
  end

  @doc """
  Revoca una sesión activa.
  Parámetros:
    - `id_usuario`: Identificador único del usuario.
  Retorna:
    - `:ok` tras revocar la sesión.
    - `{:error, :no_sesion}` si no existe sesión activa para el usuario.
  """
  def revocar_sesion(id_usuario) when is_binary(id_usuario) do
    case :ets.lookup(@table, id_usuario) do
      [{^id_usuario, _token, _ts}] ->
        :ets.delete(@table, id_usuario)
        LoggerService.registrar_evento("Sesión cerrada", %{usuario: id_usuario})
        :ok

      _ ->
        {:error, :no_sesion}
    end
  end

  @doc """
  Verifica si un usuario tiene sesión activa.
  Parámetros:
    - `id_usuario`: Identificador único del usuario.
  Retorna:
    - `true` si la sesión está activa.
    - `false` en caso contrario.
  """
  def sesion_activa?(id_usuario) do
    case :ets.lookup(@table, id_usuario) do
      [{^id_usuario, _token, _ts}] -> true
      _ -> false
    end
  end

  @doc """
  Retorna el primer usuario logueado (si existe).
  Retorna:
    - `{:ok, participante}` si hay una sesión activa.
    - `{:error, :no_sesion_activa}` si no hay sesiones activas.
  """
  def obtener_participante_actual do
    alias ProyectoFinalPrg3.Services.MentorManager

    with [{id_usuario, _token, _ts} | _] <- :ets.tab2list(@table) do
      case ParticipantManager.obtener_participante(id_usuario) do
        {:ok, participante} ->
          {:ok, participante}

        {:error, _} ->
          case MentorManager.obtener_mentor(id_usuario) do
            {:ok, mentor} -> {:ok, mentor}
            {:error, razon} -> {:error, razon}
          end
      end
    else
      [] -> {:error, :no_sesion_activa}
    end
  end
end

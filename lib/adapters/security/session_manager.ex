defmodule ProyectoFinalPrg3.Adapters.Security.SessionManager do
  @moduledoc """
  Administrador de sesiones basado en ETS.

  La tabla :sesiones_activas se crea al cargar el módulo para garantizar
  su disponibilidad inmediata tanto en ejecución normal como en pruebas.
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
  """
  def activar_sesion(id_usuario, token) when is_binary(id_usuario) and is_binary(token) do
    :ets.insert(@table, {id_usuario, token, System.system_time(:second)})

    LoggerService.registrar_evento("Sesión activada", %{usuario: id_usuario})

    :ok
  end

  @doc """
  Valida si un token corresponde a una sesión activa.
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
  """
  def sesion_activa?(id_usuario) do
    case :ets.lookup(@table, id_usuario) do
      [{^id_usuario, _token, _ts}] -> true
      _ -> false
    end
  end

  @doc """
  Retorna el primer usuario logueado (si existe).
  """
  def obtener_participante_actual do
    with [{id_usuario, _token, _ts} | _] <- :ets.tab2list(@table),
         {:ok, participante} <- ParticipantManager.obtener_participante(id_usuario) do
      {:ok, participante}
    else
      [] -> {:error, :no_sesion_activa}
      {:error, razon} -> {:error, razon}
    end
  end
end

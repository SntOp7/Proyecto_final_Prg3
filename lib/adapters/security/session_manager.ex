defmodule ProyectoFinalPrg3.Adapters.Security.SessionManager do
  @moduledoc """
  (… descripción igual a la tuya …)
  """

  @behaviour ProyectoFinalPrg3.Adapters.Security.SessionManagerBehaviour

  alias ProyectoFinalPrg3.Adapters.Security.TokenManager
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  @table :sesiones_activas

  # ============================================================
  # INICIALIZACIÓN
  # ============================================================

  @doc false
  def start_link(_) do
    # Crear la tabla solo si NO existe
    if :ets.whereis(@table) == :undefined do
      :ets.new(@table, [:named_table, :public, read_concurrency: true])
    end

    {:ok, self()}
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
  Valida si un token corresponde a una sesión activa en memoria.
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
  Revoca una sesión activa y elimina su registro.
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
  Obtiene cualquier usuario autenticado (si existe alguno).
  """
  def obtener_participante_actual do
    case :ets.tab2list(@table) do
      [{id_usuario, _token, _ts} | _] -> id_usuario
      _ -> nil
    end
  end
end

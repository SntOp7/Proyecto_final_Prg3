defmodule ProyectoFinalPrg3.Services.SupervisionManager do
  @moduledoc """
  Servicio responsable de la **supervisión dinámica y recuperación de procesos críticos**
  dentro del sistema de hackathon.

  Su objetivo es garantizar la **disponibilidad continua** de los servicios principales
  (autenticación, métricas, sesiones, broadcast, etc.), monitoreando su estado y reiniciándolos
  en caso de fallo.

  Este módulo actúa como un **supervisor de alto nivel** en la capa de servicios, complementando
  al árbol de supervisión definido en `ProyectoFinalPrg3.Application`.

  ## Funcionalidades principales
  - Monitorear procesos clave registrados (por nombre o PID).
  - Reiniciar agentes o servicios caídos (`MetricsService`, `SessionManager`, etc.).
  - Registrar incidentes mediante `LoggerService` o `AuditLogger`.
  - Emitir alertas a través de `BroadcastService`.
  - Integrarse con el sistema de métricas (`MetricsService`) para seguimiento de estabilidad.

  ## Ejemplo de uso
      iex> SupervisionManager.registrar_proceso(:metrics, ProyectoFinalPrg3.Services.MetricsService)
      :ok

      iex> SupervisionManager.verificar_estado(:metrics)
      {:ok, :activo}

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-03
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService
  alias ProyectoFinalPrg3.Services.BroadcastService
  alias ProyectoFinalPrg3.Services.MetricsService

  @agent_name __MODULE__

  # ============================================================
  # INICIALIZACIÓN Y REGISTRO
  # ============================================================

  @doc """
  Inicia el supervisor en memoria mediante un `Agent` interno si aún no está activo.
  """
  def iniciar do
    unless Process.whereis(@agent_name) do
      {:ok, _pid} = Agent.start_link(fn -> %{} end, name: @agent_name)
      LoggerService.registrar_evento("SupervisionManager iniciado", %{estado: :ok})
    end

    :ok
  end

  @doc """
  Registra un proceso supervisado bajo un identificador lógico (`:metrics`, `:session_manager`, etc.).

  Si el proceso ya está registrado, actualiza su referencia.
  """
  def registrar_proceso(nombre, modulo) when is_atom(nombre) and is_atom(modulo) do
    iniciar()
    Agent.update(@agent_name, &Map.put(&1, nombre, modulo))

    LoggerService.registrar_evento("Proceso registrado para supervisión", %{
      nombre: nombre,
      modulo: modulo
    })

    :ok
  end

  @doc """
  Lista todos los procesos actualmente bajo supervisión.
  """
  def listar_procesos do
    iniciar()
    Agent.get(@agent_name, & &1)
  end

  # ============================================================
  # SUPERVISIÓN ACTIVA
  # ============================================================

  @doc """
  Verifica el estado de un proceso registrado y lo reinicia si no responde.

  Retorna:
  - `{:ok, :activo}` si el proceso está disponible.
  - `{:restarted, modulo}` si fue reiniciado.
  - `{:error, :no_registrado}` si no está en la tabla de supervisión.
  """
  def verificar_estado(nombre) when is_atom(nombre) do
    iniciar()

    case Agent.get(@agent_name, &Map.get(&1, nombre)) do
      nil ->
        {:error, :no_registrado}

      modulo when is_atom(modulo) ->
        if proceso_activo?(modulo) do
          {:ok, :activo}
        else
          reiniciar_proceso(nombre, modulo)
          {:restarted, modulo}
        end
    end
  end

  @doc """
  Revisa todos los procesos registrados y reinicia los que no estén activos.
  Retorna un resumen de los procesos revisados.
  """
  def verificar_todos do
    iniciar()
    procesos = listar_procesos()

    resultados =
      for {nombre, _modulo} <- procesos, into: [] do
        case verificar_estado(nombre) do
          {:ok, :activo} -> {nombre, :activo}
          {:restarted, _} -> {nombre, :reiniciado}
          _ -> {nombre, :error}
        end
      end

    LoggerService.registrar_evento("Revisión de supervisión completa", %{resultados: resultados})
    resultados
  end

  # ============================================================
  # REINICIO Y RECUPERACIÓN
  # ============================================================

  @doc false
  defp reiniciar_proceso(nombre, modulo) do
    try do
      apply(modulo, :inicializar_supervision, [])
      LoggerService.registrar_evento("Proceso reiniciado correctamente", %{nombre: nombre})

      MetricsService.registrar_evento(:proceso_reiniciado, %{
        proceso: nombre,
        modulo: modulo
      })

      BroadcastService.notificar(:proceso_reiniciado, %{
        nombre: nombre,
        modulo: modulo
      })

      {:ok, :reiniciado}
    rescue
      error ->
        LoggerService.registrar_evento("Error al reiniciar proceso", %{
          nombre: nombre,
          error: Exception.message(error)
        })

        MetricsService.registrar_evento(:error_reinicio, %{
          proceso: nombre,
          error: Exception.message(error)
        })

        BroadcastService.notificar_error(
          "SupervisionManager",
          "Error al reiniciar proceso #{inspect(nombre)}: #{Exception.message(error)}"
        )

        {:error, :fallo_reinicio}
    end
  end

  @doc false
  defp proceso_activo?(modulo) do
    case Process.whereis(modulo) do
      nil -> false
      pid when is_pid(pid) -> Process.alive?(pid)
      _ -> false
    end
  end
end

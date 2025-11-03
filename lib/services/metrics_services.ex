defmodule ProyectoFinalPrg3.Services.MetricsService do
  @moduledoc """
  Servicio responsable de la **recolección, análisis y exposición de métricas** del sistema de hackathon.

  Este módulo centraliza estadísticas operativas para monitorear el rendimiento,
  la participación y la actividad general de los usuarios, equipos y proyectos.

  ## Funcionalidades principales
  - Registrar eventos clave del sistema (inicio de sesión, creación de equipos, avances de proyectos, etc.).
  - Generar métricas agregadas sobre usuarios, equipos, proyectos y actividad.
  - Ofrecer un punto de consulta unificado para otros servicios o dashboards.
  - Integrarse con `LoggerService` y `BroadcastService` para notificaciones y auditoría.

  ## Integraciones
  - `AuthService` → seguimiento de sesiones y autenticaciones.
  - `TeamManager` → creación y disolución de equipos.
  - `ProjectManager` → creación, avance y finalización de proyectos.
  - `LoggerService` → registro de métricas importantes.
  - `BroadcastService` → difusión de cambios globales en métricas (opcional).

  ## Ejemplo de uso
      iex> MetricsService.registrar_evento(:inicio_sesion, %{usuario_id: "abc-123"})
      :ok

      iex> MetricsService.obtener_resumen()
      %{
        total_usuarios: 25,
        equipos_activos: 8,
        proyectos_en_desarrollo: 5
      }

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-03
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService
  alias ProyectoFinalPrg3.Services.{AuthService, TeamManager, ProjectManager}

  # ============================================================
  # ESTRUCTURA INTERNA DE MÉTRICAS
  # ============================================================

  @metrics %{
    usuarios_activos: 0,
    equipos_creados: 0,
    equipos_activos: 0,
    proyectos_creados: 0,
    proyectos_en_desarrollo: 0,
    sesiones_activas: 0,
    eventos: []
  }

  @doc """
  Inicializa o restablece las métricas internas a sus valores por defecto.
  """
  def inicializar do
    put_metrics(@metrics)
    LoggerService.registrar_evento("Métricas inicializadas", %{estado: :ok})
    :ok
  end

  # ============================================================
  # REGISTRO DE EVENTOS
  # ============================================================

  @doc """
  Registra un evento relevante dentro del sistema para su análisis posterior.

  ## Parámetros:
    - `tipo_evento`: átomo que representa la categoría del evento (por ejemplo, `:inicio_sesion`, `:equipo_creado`).
    - `datos`: mapa opcional con información adicional sobre el evento.

  Cada evento se guarda en una lista interna y puede ser consultado más adelante.
  """
  def registrar_evento(tipo_evento, datos \\ %{}) when is_atom(tipo_evento) do
    metricas = get_metrics()

    evento = %{
      tipo: tipo_evento,
      timestamp: DateTime.utc_now(),
      datos: datos
    }

    actualizadas =
      Map.update!(metricas, :eventos, fn lista -> [evento | lista] end)
      |> actualizar_contadores(tipo_evento)

    put_metrics(actualizadas)
    LoggerService.registrar_evento("Evento registrado en métricas", evento)
    :ok
  end

  # ============================================================
  # CONSULTA DE MÉTRICAS
  # ============================================================

  @doc """
  Retorna un resumen general de las métricas del sistema, incluyendo:
  - Usuarios activos
  - Equipos activos y creados
  - Proyectos activos y en desarrollo
  - Sesiones activas
  """
  def obtener_resumen do
    %{
      total_usuarios: contar_usuarios(),
      equipos_activos: contar_equipos(:activo),
      proyectos_en_desarrollo: contar_proyectos(:en_desarrollo),
      sesiones_activas: obtener(:sesiones_activas)
    }
  end

  @doc """
  Devuelve el listado completo de eventos registrados para análisis o auditoría.
  """
  def listar_eventos do
    get_metrics()[:eventos]
  end

  @doc """
  Devuelve el valor actual de una métrica específica.
  """
  def obtener(clave) when is_atom(clave), do: get_metrics()[clave]

  # ============================================================
  # FUNCIONES DE CONTEO Y AGREGACIÓN
  # ============================================================

  @doc false
  defp contar_usuarios do
    case AuthService do
      nil -> 0
      _ -> AuthService |> :erlang.apply(:listar_participantes, []) |> length()
    end
  end

  @doc false
  defp contar_equipos(estado) do
    case TeamManager.listar_equipos() do
      equipos when is_list(equipos) ->
        Enum.count(equipos, &(&1.estado == estado))

      _ -> 0
    end
  end

  @doc false
  defp contar_proyectos(estado) do
    case ProjectManager.listar_proyectos() do
      proyectos when is_list(proyectos) ->
        Enum.count(proyectos, &(&1.estado == estado))

      _ -> 0
    end
  end

  # ============================================================
  # FUNCIONES AUXILIARES DE ACTUALIZACIÓN
  # ============================================================

  @doc false
  defp actualizar_contadores(metricas, tipo_evento) do
    case tipo_evento do
      :inicio_sesion ->
        Map.update!(metricas, :sesiones_activas, &(&1 + 1))

      :cierre_sesion ->
        Map.update!(metricas, :sesiones_activas, &max(&1 - 1, 0))

      :equipo_creado ->
        Map.update!(metricas, :equipos_creados, &(&1 + 1))

      :proyecto_creado ->
        Map.update!(metricas, :proyectos_creados, &(&1 + 1))

      :proyecto_actualizado ->
        Map.update!(metricas, :proyectos_en_desarrollo, &(&1 + 1))

      _ ->
        metricas
    end
  end

  # ============================================================
  # SIMULACIÓN DE ALMACENAMIENTO INTERNO (ETS / AGENTE)
  # ============================================================

  @agent_name __MODULE__

  @doc false
  defp put_metrics(data) do
    if Process.whereis(@agent_name) do
      Agent.update(@agent_name, fn _ -> data end)
    else
      {:ok, _pid} = Agent.start_link(fn -> data end, name: @agent_name)
    end
  end

  @doc false
  defp get_metrics do
    if Process.whereis(@agent_name) do
      Agent.get(@agent_name, & &1)
    else
      @metrics
    end
  end
end

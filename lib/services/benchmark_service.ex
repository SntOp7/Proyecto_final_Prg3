defmodule ProyectoFinalPrg3.Services.BenchmarkService do
  @moduledoc """
  Servicio encargado de la **medición y comparación de rendimiento**
  entre algoritmos o funciones del sistema Hackathon.

  Este módulo forma parte de la capa de **servicios**, y permite
  evaluar el tiempo de ejecución de distintas funciones para análisis
  de optimización o auditoría de desempeño.

  ## Funcionalidades principales:
  - Medir el tiempo de ejecución de una función.
  - Comparar dos algoritmos y calcular el *speedup*.
  - Registrar resultados de benchmark en el sistema de logs.
  - Generar reportes básicos de rendimiento.

  ## Ejemplo de uso:
      iex> BenchmarkService.comparar(
      ...>   {ProyectoFinalPrg3.Services.TeamManager, :listar_equipos, []},
      ...>   {ProyectoFinalPrg3.Services.ProjectManager, :listar_proyectos, []}
      ...> )
      {:ok, "El primer algoritmo es 1.75 veces más rápido que el segundo."}

  ---
  **Autores:** Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez
  **Fecha:** 2025-11-03
  **Licencia:** GNU GPLv3
  """

  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # ============================================================
  # FUNCIONES PRINCIPALES DE BENCHMARK
  # ============================================================

  @doc """
  Determina el tiempo de ejecución (en microsegundos) de una función.

  ## Parámetros:
    - `{modulo, funcion, args}` → tupla con la referencia a ejecutar.

  ## Retorna:
    - Tiempo de ejecución en microsegundos.
  """
  def medir_tiempo({modulo, funcion, args}) do
    tiempo_inicial = System.monotonic_time()
    apply(modulo, funcion, args)
    tiempo_final = System.monotonic_time()

    System.convert_time_unit(tiempo_final - tiempo_inicial, :native, :microsecond)
  end

  @doc """
  Compara dos funciones o algoritmos y calcula el *speedup*.

  ## Parámetros:
    - `ref1`: `{modulo, funcion, args}` del primer algoritmo.
    - `ref2`: `{modulo, funcion, args}` del segundo algoritmo.

  ## Retorna:
    - `{:ok, mensaje}` con el resultado de la comparación.
  """
  def comparar(ref1, ref2) do
    tiempo1 = medir_tiempo(ref1)
    tiempo2 = medir_tiempo(ref2)

    speedup = calcular_speedup(tiempo1, tiempo2) |> Float.round(2)
    mensaje =
      "Tiempos: #{tiempo1}µs y #{tiempo2}µs — " <>
      "el primer algoritmo es #{speedup} veces más rápido que el segundo."

    LoggerService.registrar_evento("Benchmark ejecutado", %{tiempo1: tiempo1, tiempo2: tiempo2, speedup: speedup})
    {:ok, mensaje}
  end

  @doc """
  Calcula el *speedup* (factor de mejora) entre dos tiempos de ejecución.
  """
  def calcular_speedup(t1, t2) when t1 > 0 and t2 > 0, do: t2 / t1
  def calcular_speedup(_, _), do: 0

  # ============================================================
  # FUNCIONES AUXILIARES
  # ============================================================

  @doc """
  Ejecuta un benchmark múltiple entre una lista de funciones
  y genera un ranking de rendimiento.
  """
  def ranking(funciones) when is_list(funciones) do
    resultados =
      Enum.map(funciones, fn ref ->
        {ref, medir_tiempo(ref)}
      end)
      |> Enum.sort_by(fn {_ref, tiempo} -> tiempo end)

    LoggerService.registrar_evento("Benchmark múltiple ejecutado", %{ranking: resultados})
    resultados
  end
end

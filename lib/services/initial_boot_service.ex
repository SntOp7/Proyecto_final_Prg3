defmodule ProyectoFinalPrg3.Services.InitialBootService do
  @moduledoc """
  Servicio encargado del proceso de arranque e inicialización del sistema.

  `InitialBootService` prepara el entorno de ejecución según el **tipo de nodo**
  configurado (`:central`, `:persistencia`, `:cli`). Se ejecuta automáticamente
  bajo supervisión desde `Application` y reemplaza el antiguo flujo manual en
  `start.exs`.

  ## Tipos de nodo

  ### 🟦 Nodo CENTRAL (`:central`)
  - Inicializa logs y auditoría
  - Inicializa repositorios (CSV)
  - Inicia nodo distribuido **y se conecta** a nodos remotos
  - Habilita difusión distribuida

  ### 🟩 Nodo PERSISTENCIA (`:persistencia`)
  - Inicializa repositorios únicamente
  - Inicia nodo distribuido **sin conectarse** a otros
  - No genera auditoría visible

  ### 🟨 Nodo CLI (`:cli`)
  - No inicializa nodos distribuidos
  - No inicializa repositorios
  - Solo registra logs mínimos

  ## Flujo general

  1. Se inicia bajo supervisión
  2. Se programa un arranque diferido
  3. Se ejecuta lógica según tipo de nodo
  4. Se inicializan repositorios cuando aplica
  5. Se conecta a nodos cuando aplica
  6. El sistema queda listo para operar

  Autores: Sharif Giraldo, Juan Sebastián Hernández, Santiago Ospina Sánchez
  Actualizado: 2025-11-16
  Licencia: GNU GPLv3
  """

  use GenServer
  require Logger

  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService
  alias ProyectoFinalPrg3.Adapters.Persistence.PersistenceManager
  alias ProyectoFinalPrg3.Adapters.Network.NodeManager

  # ============================================================
  # START
  # ============================================================

  @doc """
  Inicia el proceso supervisado del boot del sistema.

  No arranca inmediatamente: programa un :boot para ejecutarse después
  de que el árbol de supervisión haya terminado de levantarse.
  """
  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  # ============================================================
  # INIT
  # ============================================================

  @impl true
  def init(:ok) do
    :ets.new(:sesiones_activas, [:set, :named_table, :public])
    Process.send_after(self(), :boot, 20)
    {:ok, %{}}
  end

  # ============================================================
  # BOOT
  # ============================================================

  @impl true
  def handle_info(:boot, state) do
    IO.puts("\n🚀 Iniciando sistema ProyectoFinalPrg3...\n")

    tipo = Application.get_env(:proyecto_final_prg3, :tipo_nodo, :central)

    LoggerService.limpiar_logs()
    LoggerService.registrar_evento("Inicio del sistema", %{nodo: tipo})

    # Inicializa nodos distribuidos según tipo
    case inicializar_nodos(tipo) do
      :ok ->
        :ok

      {:error, razon} ->
        Logger.error("❌ Fallo al iniciar nodo #{tipo}: #{inspect(razon)}")
        IO.puts("❌ Sistema detenido: dependencia no disponible.\n")
        System.stop(1)
    end

    if tipo == :persistencia do
      PersistenceManager.inicializar()
      LoggerService.registrar_evento("Repositorios cargados", %{})
    end

    {:noreply, state}
  end

  # ============================================================
  # LÓGICA DE INICIALIZACIÓN POR TIPO DE NODO
  # ============================================================

  @doc """
  Inicializa el nodo distribuido según el tipo:

  - :cli → NO crea nodo distribuido, pero se conecta al CENTRAL obligatoriamente.
  - :persistencia → crea nodo distribuido sin conectarse a otros.
  - :central → crea nodo distribuido y se conecta al nodo persistencia.
  """

  # ============================================================
  # CLI NODE
  # ============================================================
  def inicializar_nodos(:cli) do
    LoggerService.registrar_evento("Nodo CLI: sin capacidades distribuidas", %{})

    central_node =
      Application.get_env(:proyecto_final_prg3, :central_node, :central@central)

    IO.puts("🔌 Conectando CLI → CENTRAL (#{inspect(central_node)})...")

    case Node.connect(central_node) do
      true ->
        LoggerService.registrar_evento("CLI conectado al CENTRAL", %{nodo: central_node})
        :ok

      false ->
        LoggerService.registrar_evento("Error conectando CLI al CENTRAL", %{nodo: central_node})
        {:error, :central_no_disponible}
    end
  end

  # ============================================================
  # PERSISTENCIA NODE
  # ============================================================
  def inicializar_nodos(:persistencia) do
    case NodeManager.iniciar_nodo_local() do
      :ok ->
        LoggerService.registrar_evento("Nodo PERSISTENCIA iniciado", %{})
        :ok

      {:error, razon} ->
        {:error, razon}
    end
  end

  # ============================================================
  # CENTRAL NODE
  # ============================================================
  def inicializar_nodos(:central) do
    with :ok <- NodeManager.iniciar_nodo_local(),
         true <- esperar_persistencia() do
      LoggerService.registrar_evento("CENTRAL conectado → PERSISTENCIA", %{})
      :ok
    else
      false ->
        {:error, :persistencia_no_disponible}

      {:error, r} ->
        {:error, r}
    end
  end

  # ============================================================
  # FUNCIONES AUXILIARES
  # ============================================================

  @doc false
  defp esperar_persistencia(intentos \\ 20)

  defp esperar_persistencia(0), do: false

  defp esperar_persistencia(n) do
    [persistencia] = Application.get_env(:proyecto_final_prg3, :nodos, [])

    if Node.connect(persistencia) do
      true
    else
      Process.sleep(300)
      esperar_persistencia(n - 1)
    end
  end
end

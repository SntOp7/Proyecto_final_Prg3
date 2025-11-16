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

  alias ProyectoFinalPrg3.Adapters.Logging.{LoggerService, AuditService}
  alias ProyectoFinalPrg3.Adapters.Persistence.PersistenceManager
  alias ProyectoFinalPrg3.Adapters.Network.NodeManager

  # ============================================================
  # START LINK
  # ============================================================

  @doc """
  Inicia el proceso supervisado del boot del sistema.

  No arranca inmediatamente: programa un `:boot` para ejecutarse después
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
    Process.send_after(self(), :boot, 15)
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

    inicializar_nodos(tipo)

    if tipo in [:central, :persistencia] do
      PersistenceManager.inicializar()
      LoggerService.registrar_evento("Repositorios cargados", %{})
    end

    if tipo == :central do
      AuditService.exportar_a_txt()
    end

    IO.puts("✔ Sistema listo en nodo #{tipo}.\n")

    {:noreply, state}
  end

  # ============================================================
  # LÓGICA PARA CADA TIPO DE NODO
  # ============================================================

  @doc """
  Inicializa el nodo distribuido según el tipo:

  - :cli → NO crea nodo distribuido
  - :persistencia → crea nodo distribuido sin conectarse
  - :central → crea nodo distribuido y se conecta al cluster
  """
  def inicializar_nodos(:cli) do
    LoggerService.registrar_evento("Nodo CLI: sin capacidades distribuidas", %{})
    :ok
  end

  def inicializar_nodos(:persistencia) do
    iniciar_y_loggear(:persistencia, false)
  end

  def inicializar_nodos(:central) do
    iniciar_y_loggear(:central, true)
  end

  defp iniciar_y_loggear(tipo, conectar?) do
    case NodeManager.iniciar_nodo_local() do
      :ok ->
        LoggerService.registrar_evento("Nodo local iniciado", %{tipo: tipo})
        if conectar?, do: NodeManager.conectarse_a_nodos()

      {:error, razon} ->
        LoggerService.registrar_evento("Error iniciando nodo", %{razon: razon})
    end
  end
end

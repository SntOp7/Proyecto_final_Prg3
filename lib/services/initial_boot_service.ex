defmodule ProyectoFinalPrg3.Services.InitialBootService do
  @moduledoc """
  Servicio encargado del proceso de arranque e inicialización del sistema.

  `InitialBootService` centraliza todas las tareas que anteriormente se realizaban
  en `start.exs`, garantizando un proceso de inicio ordenado, trazable y seguro.
  Este servicio se ejecuta al inicio de la aplicación y prepara los módulos
  críticos para el funcionamiento del sistema.

  Es utilizado principalmente por:

    - El sistema de arranque (`Application`)
    - Módulos que dependen de la carga inicial de repositorios
    - Servicios de auditoría y registro de eventos

  ## Funciones principales
    - `start_link/1`: Inicia el proceso supervisor de arranque.
    - `init/1`: Programa la ejecución diferida del proceso de boot.
    - `handle_info/2`: Ejecuta las tareas de inicialización del sistema, incluyendo:
        * Limpieza de logs
        * Inicialización de repositorios de persistencia
        * Registro del evento de inicio
        * Exportación de auditorías

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha: 2025-10-27
  Licencia: GNU GPLv3
  """

  use GenServer

  alias ProyectoFinalPrg3.Adapters.Logging.{LoggerService, AuditService}
  alias ProyectoFinalPrg3.Adapters.Persistence.PersistenceManager

  # ============================================================
  # INICIO DEL SERVICIO
  # ============================================================

  @doc """
  Inicia el proceso supervisado encargado del arranque del sistema.

  ## Flujo:
    1. Registra el proceso bajo el nombre del módulo.
    2. Delegado a `GenServer.start_link/3`.
    3. Deja el sistema listo para recibir el mensaje `:boot`.

  ## Retorna:
    - `{:ok, pid}` si el proceso inicia correctamente.
    - `{:error, razon}` si el proceso falla al iniciar.
  """

  def start_link(_args), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  # ============================================================
  # CONFIGURACIÓN INICIAL
  # ============================================================

  @doc """
  Configura el estado inicial del servicio y programa la ejecución del proceso
  de boot del sistema.

  ## Flujo:
    1. Se recibe `:ok` como parámetro de inicio.
    2. Se programa un mensaje diferido (`:boot`) para ejecutar en 10 ms.
    3. Se retorna el estado inicial vacío.

  ## Retorna:
    - `{:ok, %{}}` indicando que el servicio fue inicializado correctamente.
  """

  @impl true
  def init(:ok) do
    Process.send_after(self(), :boot, 10)
    {:ok, %{}}
  end

  # ============================================================
  # EJECUCIÓN DEL ARRANQUE DEL SISTEMA
  # ============================================================

  @doc """
  Ejecuta el flujo de inicialización del sistema tras recibir el mensaje `:boot`.

  Este método realiza todas las tareas críticas necesarias para preparar
  el sistema antes de aceptar solicitudes o ejecutar procesos dependientes.

  ## Flujo:
    1. Muestra mensaje visual de arranque en consola.
    2. Limpia los logs anteriores para evitar ruido histórico.
    3. Registra el evento de “inicio de sistema”.
    4. Inicializa todos los repositorios de persistencia.
    5. Registra que los repositorios fueron cargados.
    6. Exporta auditorías pendientes a archivo de texto.
    7. Informa al usuario que el sistema está listo.

  ## Retorna:
    - `{:noreply, state}` indicando que no se requiere respuesta al mensaje.
  """

  @impl true
  def handle_info(:boot, state) do
    IO.puts("\n🚀 Iniciando sistema ProyectoFinalPrg3...\n")

    LoggerService.limpiar_logs()
    LoggerService.registrar_evento("Inicio del sistema de hackathon", %{})

    PersistenceManager.inicializar()
    LoggerService.registrar_evento("Repositorios cargados", %{})

    AuditService.exportar_a_txt()

    IO.puts("✔ Sistema listo.\n")

    {:noreply, state}
  end
end

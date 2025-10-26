defmodule ProyectoFinalPrg3.Services.CommandService do
  @moduledoc """
  Servicio encargado de la ejecución de comandos provenientes de la interfaz CLI.

  Este módulo actúa como el **intérprete central** del sistema de comandos,
  orquestando llamadas a los servicios de dominio correspondientes según la acción solicitada.

  ## Flujo general
  1. `CommandExecutor` recibe la instrucción desde la CLI.
  2. `CommandService` interpreta el comando (`service` + `action`).
  3. Se ejecuta el servicio correspondiente (`TeamManager`, `ChatService`, etc.).
  4. Se devuelve el resultado o mensaje al usuario.

  ## Ejemplo
      iex> CommandService.ejecutar_comando(%{service: :command_service, action: :listar_equipos}, [])
      {:ok, [%Team{}, %Team{}]}

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Services.{TeamManager, ProjectManager, ChatService}
  alias ProyectoFinalPrg3.Adapters.Security.SessionManager
  alias ProyectoFinalPrg3.Adapters.CLI.CommandRegistry
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # ============================================================
  # CASO POR DEFECTO
  # ============================================================

  @doc """
  Maneja comandos no reconocidos o con formato incorrecto.
  """
  def ejecutar_comando(_, _) do
    {:error, "Comando no reconocido o uso incorrecto. Usa /help para ver los comandos disponibles."}
  end

  # ============================================================
  # COMANDOS PRINCIPALES
  # ============================================================

  @doc """
  Lista todos los equipos registrados en el sistema.
  """
  def ejecutar_comando(%{service: :command_service, action: :listar_equipos}, _args) do
    equipos = TeamManager.listar_equipos()
    LoggerService.registrar_evento("Comando ejecutado", %{accion: :listar_equipos})
    {:ok, equipos}
  end

  @doc """
  Muestra la información del proyecto asociado a un equipo.
  """
  def ejecutar_comando(%{service: :command_service, action: :mostrar_proyecto}, [nombre_equipo]) do
    with {:ok, equipo} <- TeamManager.obtener_equipo(nombre_equipo),
         {:ok, proyecto} <- ProjectManager.obtener_proyecto_por_id(equipo.id_proyecto) do
      LoggerService.registrar_evento("Comando ejecutado", %{accion: :mostrar_proyecto, equipo: nombre_equipo})
      {:ok, proyecto}
    else
      {:error, :no_encontrado} -> {:error, "No se encontró el equipo o proyecto indicado."}
      _ -> {:error, "Error al recuperar el proyecto."}
    end
  end

  @doc """
  Permite a un participante autenticado unirse a un equipo existente.
  """
  def ejecutar_comando(%{service: :command_service, action: :unirse_a_equipo}, [nombre_equipo]) do
    id_participante = SessionManager.obtener_participante_actual()

    case TeamManager.unirse_a_equipo(nombre_equipo, id_participante) do
      {:ok, equipo} ->
        LoggerService.registrar_evento("Comando ejecutado", %{accion: :unirse_a_equipo, equipo: equipo.nombre})
        {:ok, "Te uniste exitosamente al equipo #{equipo.nombre}"}

      {:error, :ya_es_miembro} -> {:error, "Ya perteneces a este equipo."}
      {:error, :no_encontrado} -> {:error, "No se encontró el equipo indicado."}
      _ -> {:error, "No fue posible unirse al equipo."}
    end
  end

  @doc """
  Permite ingresar al canal de chat de un equipo.
  """
  def ejecutar_comando(%{service: :command_service, action: :ingresar_chat_equipo}, [nombre_equipo]) do
    ChatService.ingresar_chat_equipo(nombre_equipo)
    LoggerService.registrar_evento("Comando ejecutado", %{accion: :ingresar_chat_equipo, equipo: nombre_equipo})
    {:ok, "Has ingresado al chat del equipo #{nombre_equipo}."}
  end

  @doc """
  Muestra la lista de comandos disponibles registrados en el sistema.
  """
  def ejecutar_comando(%{service: :command_service, action: :mostrar_ayuda}, _args) do
    mostrar_ayuda()
  end

  # ============================================================
  # FUNCIONES AUXILIARES
  # ============================================================

  @doc """
  Imprime la lista de comandos disponibles en la CLI.
  """
  def mostrar_ayuda do
    IO.puts("\nComandos disponibles:")
    Enum.each(CommandRegistry.all(), fn {cmd, info} ->
      IO.puts("  #{cmd} → #{info.description}")
    end)
    {:ok, :help_mostrado}
  end
end

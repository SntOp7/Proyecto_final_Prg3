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

  ## Comandos disponibles
  - `listar_equipos` → lista todos los equipos.
  - `mostrar_proyecto` → muestra el proyecto asociado a un equipo.
  - `unirse_a_equipo` → permite a un participante unirse a un equipo existente.
  - `ingresar_chat_equipo` → ingresa al canal de chat del equipo.
  - `mostrar_ayuda` → muestra los comandos disponibles.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Services.{TeamManager, ProjectManager, ChatService}
  alias ProyectoFinalPrg3.Adapters.Security.SessionManager
  alias ProyectoFinalPrg3.Adapters.CLI.CommandRegistry

  @spec ejecutar_comando(map(), list()) :: {:ok, any()} | {:error, String.t()}

  # ============================================================
  # COMANDOS CORRECTOS (según CommandRegistry)
  # ============================================================

  # /teams
  def ejecutar_comando(%{service: :team_manager, action: :list_teams}, _args) do
    equipos = TeamManager.listar_equipos()
    {:ok, equipos}
  end

  # /project <equipo>
  def ejecutar_comando(%{service: :project_manager, action: :show_project}, [nombre_equipo]) do
    with {:ok, equipo} <- TeamManager.obtener_equipo(nombre_equipo),
         {:ok, proyecto} <- ProjectManager.obtener_proyecto_por_id(equipo.id_proyecto) do
      {:ok, proyecto}
    else
      _ -> {:error, "No se encontró el equipo o proyecto indicado."}
    end
  end

  # /join <equipo>
  def ejecutar_comando(%{service: :team_manager, action: :join_team}, [nombre_equipo]) do
    id = SessionManager.obtener_participante_actual()

    case TeamManager.unirse_a_equipo(nombre_equipo, id) do
      {:ok, equipo} -> {:ok, "Te uniste al equipo #{equipo.nombre}"}
      {:error, :ya_es_miembro} -> {:error, "Ya perteneces a este equipo."}
      {:error, :no_encontrado} -> {:error, "Equipo no encontrado."}
    end
  end

  # /chat <equipo>
  def ejecutar_comando(%{service: :chat_manager, action: :open_chat}, [nombre_equipo]) do
    ChatService.ingresar_chat_equipo(nombre_equipo)
    {:ok, "Ingresaste al chat del equipo #{nombre_equipo}"}
  end

  # /help
  def ejecutar_comando(%{service: :command_service, action: :show_help}, _args) do
    comandos =
      CommandRegistry.all()
      |> Enum.map(fn {cmd, info} ->
        "#{cmd} → #{info.description}"
      end)
      |> Enum.join("\n")

    {:ok, "Comandos disponibles:\n" <> comandos}
  end

  # ============================================================
  # DEFAULT
  # ============================================================

  def ejecutar_comando(_, _) do
    {:error, "Comando no reconocido o uso incorrecto. Usa /help para ver los comandos disponibles."}
  end
end

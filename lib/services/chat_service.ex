defmodule ProyectoFinalPrg3.Services.ChatService do
  @moduledoc """
  Servicio principal responsable de la **gestión del chat por equipos** dentro del sistema Hackathon.

  Coordina:
  - Validación de equipo y participante.
  - Entrada al canal del chat del equipo.
  - Integración con `BroadcastService` para notificaciones.
  - Registro de eventos mediante `LoggerService`.

  Actualmente implementa:
    - Ingreso al chat del equipo.

  Expandible para funcionalidades futuras:
    - Enviar mensajes.
    - Historial del chat.
    - Salir del chat.
    - Subsistemas de notificaciones.

  ---
  **Autores:** Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez
  **Fecha:** 2025-11-03
  **Licencia:** GNU GPLv3
  """

  alias ProyectoFinalPrg3.Services.TeamManager
  alias ProyectoFinalPrg3.Adapters.Security.SessionManager
  alias ProyectoFinalPrg3.Services.BroadcastService
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # ============================================================
  # INGRESO AL CHAT DEL EQUIPO
  # ============================================================

  @doc """
  Permite que un participante autenticado ingrese al chat de un equipo.

  ## Flujo:
    1. Verifica que exista una sesión activa.
    2. Obtiene el equipo.
    3. Valida que el participante pertenezca al equipo.
    4. Registra en logs y notifica.
    5. Retorna mensaje de ingreso.

  ## Retorna:
    - `{:ok, mensaje}`
    - `{:error, razon}`
  """
  def ingresar_chat_equipo(nombre_equipo) when is_binary(nombre_equipo) do
    with {:ok, id_participante} <- obtener_sesion_actual(),
         {:ok, equipo} <- TeamManager.obtener_equipo(nombre_equipo),
         true <- miembro_del_equipo?(equipo, id_participante) do

      LoggerService.registrar_evento("Ingreso a chat", %{
        participante: id_participante,
        equipo: equipo.nombre
      })

      BroadcastService.notificar(:ingreso_chat, %{
        equipo: equipo.nombre,
        participante: id_participante
      })

      {:ok, "Has ingresado al chat del equipo #{equipo.nombre}."}
    else
      {:error, :no_sesion} ->
        {:error, "Debes iniciar sesión para acceder al chat."}

      {:error, :no_encontrado} ->
        {:error, "El equipo '#{nombre_equipo}' no existe."}

      false ->
        {:error, "No perteneces a este equipo, no puedes ingresar a su chat."}
    end
  end

  # ============================================================
  # FUNCIONES AUXILIARES
  # ============================================================

  defp obtener_sesion_actual do
    case SessionManager.obtener_participante_actual() do
      nil -> {:error, :no_sesion}
      id -> {:ok, id}
    end
  end

  defp miembro_del_equipo?(equipo, id_participante) do
    Enum.any?(equipo.participantes, fn p -> p.id == id_participante end)
  end
end

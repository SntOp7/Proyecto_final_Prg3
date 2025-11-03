defmodule ProyectoFinalPrg3.Services.MatchingService do
  @moduledoc """
  Servicio responsable de la lógica de emparejamiento (matching) entre
  participantes, equipos y mentores dentro del sistema de hackathon.

  Su objetivo es automatizar la asignación de miembros y mentores según
  criterios definidos, optimizando la conformación de equipos y la distribución
  de mentorías.

  Este módulo actúa como un servicio complementario: no reemplaza la gestión
  manual de `TeamManager` ni `ParticipantManager`, sino que la amplía.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Services.{TeamManager, ParticipantManager, BroadcastService}
  alias ProyectoFinalPrg3.Domain.{Team, Participant}

  # ============================================================
  # FUNCIÓN PRINCIPAL: ASIGNACIÓN AUTOMÁTICA DE PARTICIPANTES
  # ============================================================

  @doc """
  Asigna automáticamente un participante a un equipo disponible y compatible.

  Los criterios por defecto son:
    - Que el equipo esté activo.
    - Que el equipo tenga menos de `max_integrantes` miembros (por defecto 5).
    - Que la categoría o experiencia del participante coincida con la del equipo (si aplica).

  Si no encuentra un equipo compatible, retorna `{:error, :sin_equipo_disponible}`.
  """
  def asignar_a_equipo(id_participante, max_integrantes \\ 5) do
    with {:ok, participante} <- ParticipantManager.obtener_participante(id_participante),
         equipos <- TeamManager.listar_equipos(),
         equipos_disponibles <- filtrar_equipos_disponibles(equipos, participante, max_integrantes),
         equipo_optimo <- seleccionar_equipo_optimo(equipos_disponibles) do
      case equipo_optimo do
        nil ->
          {:error, :sin_equipo_disponible}

        _ ->
          TeamManager.agregar_participante(equipo_optimo.nombre, participante)
          BroadcastService.notificar(:participante_asignado_automaticamente, %{
            participante: participante.nombre,
            equipo: equipo_optimo.nombre
          })
          {:ok, equipo_optimo}
      end
    else
      {:error, razon} -> {:error, razon}
    end
  end

  # ============================================================
  # FUNCIONES AUXILIARES
  # ============================================================

  @doc false
  defp filtrar_equipos_disponibles(equipos, participante, max_integrantes) do
    Enum.filter(equipos, fn eq ->
      eq.estado == :activo and
        length(eq.participantes) < max_integrantes and
        (is_nil(eq.categoria) or eq.categoria == participante.experiencia)
    end)
  end

  @doc false
  defp seleccionar_equipo_optimo([]), do: nil
  defp seleccionar_equipo_optimo(equipos) do
    Enum.min_by(equipos, &length(&1.participantes))
  end
end

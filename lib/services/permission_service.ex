defmodule ProyectoFinalPrg3.Services.PermissionService do
  @moduledoc """
  Servicio de permisos basado en roles para determinar qué comandos puede ejecutar un usuario.
  """

  alias ProyectoFinalPrg3.Services.ParticipantManager
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  @permissions %{
    "participante" => [
      :ver_equipos,
      :ver_proyecto,
      :unirse_equipo,
      :crear_equipo,
      :ver_canales
    ],

    "mentor" => [
      :ver_equipos,
      :ver_proyecto,
      :enviar_feedback
    ],

    "admin" => [
      :ver_equipos,
      :ver_proyecto,
      :crear_equipo,
      :eliminar_equipo,
      :asignar_mentor,
      :gestionar_usuarios
    ]
  }

  # ============================================================
  # API PRINCIPAL
  # ============================================================

  @doc """
  Verifica si un usuario tiene permiso para ejecutar una acción.
  """
  def autorizado?(id_usuario, accion) do
    with {:ok, user} <- ParticipantManager.obtener_participante(id_usuario),
         rol when not is_nil(rol) <- user.rol,
         permisos <- Map.get(@permissions, rol, []) do

      permitido = accion in permisos

      LoggerService.registrar_evento("Verificación de permiso", %{
        usuario: id_usuario,
        accion: accion,
        rol: rol,
        permitido: permitido
      })

      permitido
    else
      _ ->
        LoggerService.registrar_evento("Permiso denegado", %{
          usuario: id_usuario,
          accion: accion
        })

        false
    end
  end

  def permisos_por_rol(rol), do: Map.get(@permissions, rol, [])
  def listar_todos_los_permisos, do: @permissions
end

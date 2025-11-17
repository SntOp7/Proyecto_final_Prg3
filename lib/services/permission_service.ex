defmodule ProyectoFinalPrg3.Services.PermissionService do
  @moduledoc """
  Servicio de permisos basado en roles para determinar qué comandos puede ejecutar un usuario.
  """

  alias ProyectoFinalPrg3.Services.{ParticipantManager, MentorManager}
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  @permisos %{
    admin: [
      :crear_equipo,
      :eliminar_equipo,
      :enviar_anuncio,
      :ver_todos_los_proyectos,
      :editar_proyecto,
      :asignar_mentor,
      :gestionar_usuarios,
      :ver_equipos,
      :ver_proyecto,
      :crear_proyecto,
      :ver_canales
    ],
    mentor: [
      :ver_proyecto,
      :enviar_feedback,
      :revisar_avance,
      :comentar_equipo,
      :ver_equipos,
      :ver_canales
    ],
    participante: [
      :registrarse,
      :iniciar_sesion,
      :unirse_equipo,
      :enviar_mensaje,
      :actualizar_perfil,
      :subir_avance,
      :editar_proyecto,
      :ver_equipos,
      :ver_proyecto,
      :crear_equipo,
      :crear_proyecto,
      :ver_canales
    ]
  }

  # ============================================================
  # API PRINCIPAL
  # ============================================================

  @doc """
  Verifica si un usuario tiene permiso para ejecutar una acción.
  """
  def autorizado?(id_usuario, accion) do
    usuario =
      case ParticipantManager.obtener_participante(id_usuario) do
        {:ok, user} ->
          user

        _ ->
          case MentorManager.obtener_mentor(id_usuario) do
            {:ok, mentor} -> mentor
            _ -> nil
          end
      end

    case usuario do
      nil ->
        LoggerService.registrar_evento("Permiso denegado", %{
          usuario: id_usuario,
          accion: accion,
          razon: "usuario_no_encontrado"
        })

        false

      user ->
        rol_atom = if is_binary(user.rol), do: String.to_atom(user.rol), else: user.rol
        permisos = Map.get(@permisos, rol_atom, [])
        permitido = accion in permisos

        LoggerService.registrar_evento("Verificación de permiso", %{
          usuario: id_usuario,
          accion: accion,
          rol: rol_atom,
          permitido: permitido
        })

        permitido
    end
  end

  def permisos_por_rol(rol), do: Map.get(@permisos, rol, [])
  def listar_todos_los_permisos, do: @permisos
end

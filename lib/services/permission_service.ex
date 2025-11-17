defmodule ProyectoFinalPrg3.Services.PermissionService do
  @moduledoc """
  Servicio de permisos basado en roles para determinar qué comandos puede ejecutar un usuario.
  """

  alias ProyectoFinalPrg3.Services.{ParticipantManager, MentorManager}
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  @permissions %{
    participante: [
      :ver_equipos,
      :ver_proyecto,
      :crear_proyecto,
      :unirse_equipo,
      :crear_equipo,
      :ver_canales
    ],
    mentor: [
      :ver_equipos,
      :ver_proyecto,
      :enviar_feedback
    ],
    admin: [
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
  IO.puts("=" <> String.duplicate("=", 60))
  IO.puts("🔐 VERIFICANDO PERMISO")
  IO.puts("   ID Usuario: #{inspect(id_usuario)}")
  IO.puts("   Acción solicitada: #{inspect(accion)}")

  usuario =
    case ParticipantManager.obtener_participante(id_usuario) do
      {:ok, user} ->
        IO.puts("   ✅ Encontrado como PARTICIPANTE")
        user

      error ->
        IO.puts("   ❌ No es participante: #{inspect(error)}")
        case MentorManager.obtener_mentor(id_usuario) do
          {:ok, mentor} ->
            IO.puts("   ✅ Encontrado como MENTOR")
            mentor
          error2 ->
            IO.puts("   ❌ No es mentor: #{inspect(error2)}")
            nil
        end
    end

  case usuario do
    nil ->
      IO.puts("   ⛔ RESULTADO: Usuario no encontrado → PERMISO DENEGADO")
      IO.puts("=" <> String.duplicate("=", 60))

      LoggerService.registrar_evento("Permiso denegado", %{
        usuario: id_usuario,
        accion: accion,
        razon: "usuario_no_encontrado"
      })

      false

    user ->
      IO.puts("   👤 Usuario encontrado: #{user.nombre}")
      IO.puts("   🎭 Rol del usuario (original): #{inspect(user.rol)}")

      # Convertir a átomo si es string
      rol_atom = if is_binary(user.rol), do: String.to_atom(user.rol), else: user.rol

      IO.puts("   🎭 Rol del usuario (convertido): #{inspect(rol_atom)}")

      # 🔥 USAR rol_atom AQUÍ
      permisos = Map.get(@permissions, rol_atom, [])
      IO.puts("   📋 Permisos del rol: #{inspect(permisos)}")

      permitido = accion in permisos
      IO.puts("   🎯 ¿Acción '#{accion}' en permisos?: #{permitido}")
      IO.puts("   #{if permitido, do: "✅", else: "❌"} RESULTADO: PERMISO #{if permitido, do: "CONCEDIDO", else: "DENEGADO"}")
      IO.puts("=" <> String.duplicate("=", 60))

      LoggerService.registrar_evento("Verificación de permiso", %{
        usuario: id_usuario,
        accion: accion,
        rol: rol_atom,
        permitido: permitido
      })

      permitido
  end
end

  def permisos_por_rol(rol), do: Map.get(@permissions, rol, [])
  def listar_todos_los_permisos, do: @permissions
end

defmodule ProyectoFinalPrg3.Services.PermissionService do
  @moduledoc """
  Servicio encargado de la **gestión de permisos y control de acceso** dentro del sistema de hackathon.

  Su propósito es validar si un participante autenticado tiene los privilegios necesarios
  para ejecutar determinadas acciones (crear equipos, asignar mentores, revisar proyectos, etc.).

  ## Funcionalidades principales:
  - Verificar si un usuario tiene acceso a un recurso.
  - Determinar si un rol puede ejecutar una acción específica.
  - Definir reglas de autorización basadas en roles.
  - Integrarse con `AuthService` y `ParticipantManager` para obtener información del usuario.

  ## Ejemplo de uso:
      iex> PermissionService.autorizado?("user-123", :crear_equipo)
      true

      iex> PermissionService.autorizado?("user-456", :asignar_mentor)
      false

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-03
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Services.AuthService
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # ============================================================
  # ROLES Y PERMISOS
  # ============================================================

  @permissions %{
    "participante" => [
      :ver_proyectos,
      :unirse_equipo,
      :editar_perfil,
      :ver_mentores
    ],
    "líder" => [
      :ver_proyectos,
      :unirse_equipo,
      :crear_equipo,
      :asignar_tareas,
      :editar_perfil
    ],
    "mentor" => [
      :ver_proyectos,
      :comentar_proyecto,
      :calificar_proyecto,
      :ver_equipos
    ],
    "organizador" => [
      :crear_equipo,
      :asignar_mentor,
      :ver_todos_los_usuarios,
      :eliminar_equipo,
      :modificar_configuracion
    ],
    "admin" => [
      :crear_usuario,
      :eliminar_usuario,
      :gestionar_roles,
      :ver_todos_los_logs,
      :modificar_configuracion
    ]
  }

  # ============================================================
  # VALIDACIÓN DE PERMISOS
  # ============================================================

  @doc """
  Verifica si un usuario tiene permiso para ejecutar una acción específica.

  ## Parámetros:
    - `id_usuario`: identificador del participante autenticado.
    - `accion`: átomo que representa la acción a ejecutar.

  ## Retorna:
    - `true` si el usuario tiene permiso.
    - `false` si no lo tiene.
  """
  def autorizado?(id_usuario, accion) when is_binary(id_usuario) and is_atom(accion) do
    with {:ok, participante} <- AuthService.obtener_participante(id_usuario),
         rol when not is_nil(rol) <- participante.rol,
         permisos <- Map.get(@permissions, rol, []) do
      resultado = accion in permisos
      LoggerService.registrar_evento("Verificación de permiso", %{
        usuario: id_usuario,
        rol: rol,
        accion: accion,
        autorizado: resultado
      })
      resultado
    else
      _ ->
        LoggerService.registrar_evento("Intento de acceso no autorizado", %{
          usuario: id_usuario,
          accion: accion
        })
        false
    end
  end

  @doc """
  Devuelve la lista de acciones disponibles para un rol específico.
  """
  def permisos_por_rol(rol) do
    Map.get(@permissions, rol, [])
  end

  @doc """
  Indica si un rol tiene una acción específica permitida.
  """
  def rol_autorizado?(rol, accion) do
    accion in Map.get(@permissions, rol, [])
  end

  @doc """
  Lista todos los roles y sus permisos.
  """
  def listar_todos_los_permisos do
    @permissions
  end
end

defmodule ProyectoFinalPrg3.Adapters.Security.PermissionAdapter do
  @moduledoc """
  Adaptador responsable del **control de permisos y roles** dentro del sistema de hackathon.

  Este módulo define y valida los permisos de acceso según el rol del participante,
  permitiendo que los servicios del dominio (como `TeamManager`, `ProjectManager`, etc.)
  verifiquen si un usuario tiene autorización para ejecutar ciertas acciones.

  Pertenece a la capa `Adapters/Security` y es utilizado por servicios como
  `AuthService`, `MentorManager`, `TeamManager` o `SupervisionService`.

  ## Roles disponibles:
    - `:admin` → Control total del sistema.
    - `:mentor` → Puede supervisar proyectos y equipos.
    - `:participante` → Puede unirse a equipos, enviar avances y mensajes.

  ## Ejemplo de uso:
      iex> PermissionAdapter.tiene_permiso?(:mentor, :editar_proyecto)
      true

      iex> PermissionAdapter.autorizado?("uuid-123", :crear_equipo)
      {:ok, :permitido}

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Services.AuthService
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # ============================================================
  # DEFINICIÓN DE PERMISOS POR ROL
  # ============================================================

  @permisos %{
    admin: [
      :crear_equipo,
      :eliminar_equipo,
      :ver_todos_los_proyectos,
      :editar_proyecto,
      :asignar_mentor,
      :gestionar_usuarios
    ],
    mentor: [
      :ver_proyecto,
      :enviar_feedback,
      :revisar_avance,
      :comentar_equipo
    ],
    participante: [
      :unirse_equipo,
      :enviar_mensaje,
      :actualizar_perfil,
      :subir_avance
    ]
  }

  # ============================================================
  # VALIDACIÓN DE PERMISOS
  # ============================================================

  @doc """
  Verifica si un **rol** específico tiene permiso para una acción determinada.

  ## Parámetros:
    - `rol`: átomo que identifica el rol del usuario (`:admin`, `:mentor`, `:participante`).
    - `accion`: átomo que representa la acción (ej. `:crear_equipo`).

  ## Retorna:
    - `true` si el rol tiene permiso.
    - `false` en caso contrario.
  """
  def tiene_permiso?(rol, accion) when is_atom(rol) and is_atom(accion) do
    acciones = Map.get(@permisos, rol, [])
    accion in acciones
  end

  @doc """
  Verifica si un **usuario autenticado** tiene permiso para ejecutar una acción específica.

  Este método consulta el rol del usuario desde `AuthService`
  y valida si está autorizado según el mapa de permisos.

  ## Parámetros:
    - `id_usuario`: identificador del participante.
    - `accion`: átomo que representa la acción a validar.

  ## Retorna:
    - `{:ok, :permitido}` si el usuario puede realizar la acción.
    - `{:error, :no_autorizado}` si el usuario no tiene permisos suficientes.
  """
  def autorizado?(id_usuario, accion) when is_binary(id_usuario) and is_atom(accion) do
    with {:ok, participante} <- AuthService.obtener_participante(id_usuario),
         true <- tiene_permiso?(String.to_atom(participante.rol), accion) do
      LoggerService.registrar_evento("Permiso concedido", %{usuario: id_usuario, accion: accion})
      {:ok, :permitido}
    else
      _ ->
        LoggerService.registrar_evento("Permiso denegado", %{usuario: id_usuario, accion: accion})
        {:error, :no_autorizado}
    end
  end

  @doc """
  Devuelve la lista de acciones permitidas para un rol determinado.
  """
  def listar_permisos(rol) when is_atom(rol), do: Map.get(@permisos, rol, [])
end

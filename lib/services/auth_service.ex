defmodule ProyectoFinalPrg3.Services.AuthService do
  @moduledoc """
  Servicio responsable de la **autenticación, sesiones y control de acceso**
  de los participantes dentro del sistema de hackathon.

  Este módulo coordina las operaciones de:
  - Registro y autenticación de participantes.
  - Validación de tokens y sesiones activas.
  - Integración con `PermissionService` para verificación de permisos.
  - Registro de eventos de acceso.

  ---
  **Autores:** Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez
  **Fecha:** 2025-10-27
  **Licencia:** GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.Participant
  alias ProyectoFinalPrg3.Adapters.Security.{TokenManager, SessionManager, EncryptionAdapter}
  alias ProyectoFinalPrg3.Adapters.Persistence.ParticipantStore
  alias ProyectoFinalPrg3.Services.PermissionService
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # ============================================================
  # REGISTRO Y AUTENTICACIÓN
  # ============================================================

  @doc """
  Registra un nuevo participante en el sistema.

  Cifra la contraseña, inicializa los valores por defecto y guarda el usuario.
  """
  def registrar_participante(
        nombre,
        correo,
        username,
        contrasena,
        rol \\ "participante",
        experiencia \\ ""
      ) do
    case ParticipantStore.buscar_por_correo(correo) do
      nil ->
        hashed = EncryptionAdapter.cifrar(contrasena)

        participante = %Participant{
          id: UUID.uuid4(),
          nombre: nombre,
          correo: correo,
          username: username,
          contrasena: hashed,
          rol: rol,
          equipo_id: nil,
          experiencia: experiencia,
          fecha_registro: DateTime.utc_now(),
          estado: :pendiente,
          ultima_conexion: nil,
          mensajes: [],
          canales_asignados: [],
          token_sesion: nil,
          perfil_url: nil
        }

        ParticipantStore.guardar_participante(participante)
        LoggerService.registrar_evento("Usuario registrado", %{correo: correo, rol: rol})
        {:ok, participante}

      _existente ->
        {:error, :correo_ya_registrado}
    end
  end

  @doc """
  Autentica a un participante verificando su correo y contraseña.

  Si las credenciales son válidas, genera un token y activa la sesión.
  """
  def autenticar(correo, contrasena) do
  case ParticipantStore.buscar_por_correo(correo) do
    nil ->
      {:error, :usuario_no_encontrado}

    %Participant{} = participante ->
      if EncryptionAdapter.verificar(contrasena, participante.contrasena || "") do
        with {:ok, token} <- TokenManager.generar_token(participante.id),
             :ok <- SessionManager.activar_sesion(participante.id, token) do
          actualizado = %{
            participante
            | estado: :activo,
              ultima_conexion: DateTime.utc_now(),
              token_sesion: token
          }

          ParticipantStore.guardar_participante(actualizado)

          LoggerService.registrar_evento("Inicio de sesión", %{
            usuario: correo,
            rol: participante.rol
          })

          ProyectoFinalPrg3.Services.MetricsService.registrar_evento(:inicio_sesion, %{
            usuario_id: participante.id,
            correo: correo,
            rol: participante.rol
          })

          {:ok, %{participante: actualizado, token: token}}
        else
          _ -> {:error, :error_en_sesion}
        end
      else
        {:error, :contrasena_invalida}
      end
  end
end

  @doc """
  Cierra la sesión activa de un participante, revocando su token y actualizando su estado.
  """
  def cerrar_sesion(id_participante) do
  SessionManager.revocar_sesion(id_participante)

  case ParticipantStore.obtener_participante(id_participante) do
    nil ->
      {:error, :no_encontrado}

    participante ->
      actualizado = %{participante | estado: :desconectado, token_sesion: nil}
      ParticipantStore.guardar_participante(actualizado)

      LoggerService.registrar_evento("Sesión cerrada", %{usuario: id_participante})

      # 🔹 REGISTRO EN MÉTRICAS
      ProyectoFinalPrg3.Services.MetricsService.registrar_evento(:cierre_sesion, %{
        usuario_id: id_participante,
        rol: participante.rol
      })

      {:ok, :sesion_cerrada}
  end
end

  # ============================================================
  # CONSULTA DE PARTICIPANTES
  # ============================================================

  @doc """
  Lista todos los participantes registrados en el sistema.

  Retorna una lista de estructuras `%Participant{}` obtenidas desde el `ParticipantStore`.
  """
  def listar_participantes do
    participantes = ParticipantStore.listar_participantes()
    LoggerService.registrar_evento("Consulta de participantes", %{total: length(participantes)})
    participantes
  end

  # ============================================================
  # VALIDACIÓN Y PERMISOS
  # ============================================================

  @doc """
  Verifica si un token de sesión es válido y retorna el participante asociado.
  """
  def validar_token(token) do
    case TokenManager.validar_token(token) do
      {:ok, id_participante} -> obtener_participante(id_participante)
      {:error, _} -> {:error, :token_invalido}
    end
  end

  @doc """
  Obtiene los datos de un participante por su ID.
  """
  def obtener_participante(id_participante) do
    case ParticipantStore.obtener_participante(id_participante) do
      nil -> {:error, :no_encontrado}
      participante -> {:ok, participante}
    end
  end

  @doc """
  Valida si un participante tiene permiso para realizar una acción específica.

  Este método delega la verificación al `PermissionService`.
  """
  def tiene_permiso?(id_participante, accion) when is_atom(accion) do
    case PermissionService.autorizado?(id_participante, accion) do
      true ->
        LoggerService.registrar_evento("Permiso concedido", %{
          usuario: id_participante,
          accion: accion
        })

        true

      false ->
        LoggerService.registrar_evento("Acceso denegado", %{
          usuario: id_participante,
          accion: accion
        })

        false
    end
  end

  # ============================================================
  # UTILIDADES
  # ============================================================

  @doc """
  Verifica si un token de sesión está activo.
  """
  def sesion_activa?(token) do
    case SessionManager.validar_sesion(token) do
      {:ok, _id} -> true
      _ -> false
    end
  end
end

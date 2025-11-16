defmodule ProyectoFinalPrg3.Services.AuthService do
  @moduledoc """
  Servicio responsable de autenticación, sesiones y permisos.
  Compatible con el struct Participant (sin campo :contrasena).
  """

  alias ProyectoFinalPrg3.Domain.Participant
  alias ProyectoFinalPrg3.Adapters.Security.{TokenManager, SessionManager, EncryptionAdapter}
  alias ProyectoFinalPrg3.Adapters.Persistence.ParticipantStore
  alias ProyectoFinalPrg3.Services.PermissionService
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # ============================================================
  # REGISTRO
  # ============================================================

  @doc """
  Registra un participante y almacena la contraseña cifrada directamente
  en ParticipantStore junto al usuario.
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

        participante =
          Participant.nuevo(
            UUID.uuid4(),
            nombre,
            correo,
            username,
            rol,
            nil,
            experiencia,
            DateTime.utc_now(),
            :pendiente,
            nil,
            [],
            [],
            nil,
            nil,
            nil

          )

        # Guardamos participante Y contraseña cifrada en ParticipantStore
        ParticipantStore.guardar_participante(%{
          participante
          | token_sesion: nil
        })

        # Guardar hash en el store (campo separado interno del store)
        ParticipantStore.guardar_contrasena(correo, hashed)

        LoggerService.registrar_evento("Usuario registrado", %{
          correo: correo,
          rol: rol
        })

        {:ok, participante}

      _ ->
        {:error, :correo_ya_registrado}
    end
  end

  # ============================================================
  # AUTENTICACIÓN
  # ============================================================

  def autenticar(correo, contrasena) do
    case ParticipantStore.buscar_por_correo(correo) do
      nil ->
        {:error, :usuario_no_encontrado}

      %Participant{} = participante ->
        # Obtener hash real desde el store
        hashed = ParticipantStore.obtener_contrasena(correo)

        if EncryptionAdapter.verificar(contrasena, hashed || "") do
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

            {:ok, %{participante: actualizado, token: token}}
          else
            _ -> {:error, :error_en_sesion}
          end
        else
          {:error, :contrasena_invalida}
        end
    end
  end

  # ============================================================
  # CIERRE DE SESIÓN
  # ============================================================

  def cerrar_sesion(id_participante) do
    SessionManager.revocar_sesion(id_participante)

    case ParticipantStore.obtener_participante(id_participante) do
      nil ->
        {:error, :no_encontrado}

      participante ->
        actualizado = %{participante | estado: :desconectado, token_sesion: nil}
        ParticipantStore.guardar_participante(actualizado)

        LoggerService.registrar_evento("Sesión cerrada", %{usuario: id_participante})

        {:ok, :sesion_cerrada}
    end
  end

  # ============================================================
  # CONSULTA
  # ============================================================

  def listar_participantes do
    participantes = ParticipantStore.listar_participantes()

    LoggerService.registrar_evento("Consulta de participantes", %{
      total: length(participantes)
    })

    participantes
  end

  def validar_token(token) do
    case TokenManager.validar_token(token) do
      {:ok, id} -> obtener_participante(id)
      _ -> {:error, :token_invalido}
    end
  end

  def obtener_participante(id) do
    case ParticipantStore.obtener_participante(id) do
      nil -> {:error, :no_encontrado}
      p -> {:ok, p}
    end
  end

  # ============================================================
  # PERMISOS
  # ============================================================

  def tiene_permiso?(id_participante, accion) do
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

  def sesion_activa?(token) do
    case SessionManager.validar_sesion(token) do
      {:ok, _} -> true
      _ -> false
    end
  end


end

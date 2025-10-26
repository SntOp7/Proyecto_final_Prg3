defmodule ProyectoFinalPrg3.Services.AuthService do
  @moduledoc """
  Módulo encargado de la autenticación y gestión de sesiones de los participantes en el sistema de hackathon.

  Provee funciones para:
  - Registrar y autenticar usuarios.
  - Validar credenciales y sesiones activas.
  - Generar y revocar tokens de acceso.
  - Recuperar información del participante autenticado.

  Este servicio coordina la autenticación entre la capa de negocio y los adaptadores
  de seguridad (`TokenManager`, `SessionManager`, `EncryptionAdapter`).

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-25
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.Participant
  alias ProyectoFinalPrg3.Adapters.Security.{TokenManager, SessionManager, EncryptionAdapter}
  alias ProyectoFinalPrg3.Adapters.Persistence.ParticipantStore

  # ============================================================
  # REGISTRO Y AUTENTICACIÓN
  # ============================================================

  @doc """
  Registra un nuevo participante en el sistema.
  Cifra su contraseña antes de almacenarla.
  """
  def registrar_participante(nombre, correo, contrasena, rol \\ "participante") do
    case ParticipantStore.buscar_por_correo(correo) do
      nil ->
        hashed = EncryptionAdapter.cifrar(contrasena)

        participante = %Participant{
          id: UUID.uuid4(),
          nombre: nombre,
          correo: correo,
          contrasena: hashed,
          rol: rol,
          equipo_id: nil,
          sesion_activa: false
        }

        ParticipantStore.guardar_participante(participante)
        {:ok, participante}

      _existente ->
        {:error, :correo_ya_registrado}
    end
  end

  @doc """
  Autentica un participante verificando su correo y contraseña.
  Si las credenciales son válidas, genera un token de sesión y marca al usuario como activo.
  """
  def autenticar(correo, contrasena) do
    case ParticipantStore.buscar_por_correo(correo) do
      nil ->
        {:error, :usuario_no_encontrado}

      %Participant{} = p ->
        if EncryptionAdapter.verificar(contrasena, p.contrasena) do
          with {:ok, token} <- TokenManager.generar_token(p.id),
               :ok <- SessionManager.activar_sesion(p.id, token) do
            ParticipantStore.actualizar_estado(p.id, true)
            {:ok, %{participante: p, token: token}}
          else
            _ -> {:error, :error_en_sesion}
          end
        else
          {:error, :contrasena_invalida}
        end
    end
  end

  @doc """
  Cierra la sesión activa de un participante.
  """
  def cerrar_sesion(id_participante) do
    SessionManager.revocar_sesion(id_participante)
    ParticipantStore.actualizar_estado(id_participante, false)
    {:ok, :sesion_cerrada}
  end

  # ============================================================
  # VALIDACIÓN Y CONSULTA
  # ============================================================

  @doc """
  Verifica si un token de sesión es válido y retorna el participante asociado.
  """
  def validar_token(token) do
    case TokenManager.validar_token(token) do
      {:ok, id} -> obtener_participante(id)
      {:error, _} -> {:error, :token_invalido}
    end
  end

  @doc """
  Recupera la información de un participante autenticado por su ID.
  """
  def obtener_participante(id_participante) do
    case ParticipantStore.obtener_participante(id_participante) do
      nil -> {:error, :no_encontrado}
      participante -> {:ok, participante}
    end
  end

  @doc """
  Verifica si un participante tiene una sesión activa válida.
  """
  def sesion_activa?(token) do
    case SessionManager.validar_sesion(token) do
      {:ok, _id} -> true
      _ -> false
    end
  end

  @doc """
  Verifica si el participante autenticado tiene permisos de administrador o mentor.
  """
  def es_autorizado?(id_participante, roles_permitidos) when is_list(roles_permitidos) do
    with {:ok, participante} <- obtener_participante(id_participante) do
      participante.rol in roles_permitidos
    else
      _ -> false
    end
  end

  # ============================================================
  # FUNCIONES INTERNAS
  # ============================================================

  @doc false
  defp registrar_evento_autenticacion(id, evento) do
    IO.puts("[Auth] Evento: #{evento} | Usuario: #{id} | Fecha: #{DateTime.utc_now()}")
  end
end

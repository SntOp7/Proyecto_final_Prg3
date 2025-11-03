defmodule ProyectoFinalPrg3.Services.AuthService do
  @moduledoc """
  Servicio responsable de la **autenticación y gestión de sesiones** de los participantes
  dentro del sistema de hackathon.

  Este módulo forma parte de la capa de servicios y coordina las operaciones de:
  - Registro de nuevos participantes.
  - Autenticación mediante correo y contraseña.
  - Validación y gestión de sesiones activas.
  - Generación, validación y revocación de tokens de acceso.
  - Control de roles y permisos de usuario.

  Se comunica con los adaptadores:
  - `TokenManager` → Generación y validación de tokens.
  - `SessionManager` → Manejo de sesiones activas.
  - `EncryptionAdapter` → Cifrado y verificación de contraseñas.
  - `ParticipantStore` → Persistencia de los datos de usuario.

  ---
  **Autores:** Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez
  **Fecha de creación:** 2025-10-27
  **Licencia:** GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.Participant
  alias ProyectoFinalPrg3.Adapters.Security.{TokenManager, SessionManager, EncryptionAdapter}
  alias ProyectoFinalPrg3.Adapters.Persistence.ParticipantStore

  # ============================================================
  # REGISTRO Y AUTENTICACIÓN
  # ============================================================

  @doc """
  Registra un nuevo participante en el sistema.

  Cifra la contraseña, inicializa los atributos por defecto y guarda el usuario en la persistencia.
  """
  def registrar_participante(nombre, correo, username, contrasena, rol \\ "participante", experiencia \\ "") do
    case ParticipantStore.buscar_por_correo(correo) do
      nil ->
        hashed = EncryptionAdapter.cifrar(contrasena)

        participante = %Participant{
          id: UUID.uuid4(),
          nombre: nombre,
          correo: correo,
          username: username,
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

        # Se almacena el hash de la contraseña en un campo auxiliar dentro del store
        ParticipantStore.guardar_participante(Map.put(participante, :contrasena, hashed))
        {:ok, participante}

      _existente ->
        {:error, :correo_ya_registrado}
    end
  end

  @doc """
  Autentica a un participante verificando sus credenciales.

  Si el correo y la contraseña son válidos:
  - Genera un token JWT (u otro tipo de token según `TokenManager`).
  - Registra la sesión activa en el `SessionManager`.
  - Actualiza el estado y la última conexión del participante.

  Retorna el participante autenticado junto con su token.
  """
  def autenticar(correo, contrasena) do
    case ParticipantStore.buscar_por_correo(correo) do
      nil ->
        {:error, :usuario_no_encontrado}

      %Participant{} = participante ->
        # Verificar la contraseña cifrada (usando campo `contrasena` en almacenamiento)
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
            registrar_evento_autenticacion(participante.id, :inicio_sesion)
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
        registrar_evento_autenticacion(id_participante, :sesion_cerrada)
        {:ok, :sesion_cerrada}
    end
  end

  # ============================================================
  # VALIDACIÓN Y CONSULTA
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
  Recupera la información de un participante autenticado por su ID.
  """
  def obtener_participante(id_participante) do
    case ParticipantStore.obtener_participante(id_participante) do
      nil -> {:error, :no_encontrado}
      participante -> {:ok, participante}
    end
  end

  @doc """
  Verifica si un token de sesión está actualmente activo.
  """
  def sesion_activa?(token) do
    case SessionManager.validar_sesion(token) do
      {:ok, _id} -> true
      _ -> false
    end
  end

  @doc """
  Verifica si un participante tiene permisos entre una lista de roles permitidos.
  """
  def es_autorizado?(id_participante, roles_permitidos) when is_list(roles_permitidos) do
    with {:ok, participante} <- obtener_participante(id_participante) do
      participante.rol in roles_permitidos
    else
      _ -> false
    end
  end

  # ============================================================
  # FUNCIONES AUXILIARES Y DE LOGGING
  # ============================================================

  @doc false
  defp registrar_evento_autenticacion(id, evento) do
    IO.puts("[AuthService] Evento: #{evento} | Usuario: #{id} | Fecha: #{DateTime.utc_now()}")
  end
end

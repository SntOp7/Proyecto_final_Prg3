defmodule ProyectoFinalPrg3.Services.AuthService do
  @moduledoc """
  Servicio responsable de autenticación y manejo de sesiones del sistema.

  Realiza:
    • Registro de usuarios con contraseña cifrada
    • Autenticación mediante verificación de hash
    • Generación y validación de tokens
    • Activación y revocación de sesiones
    • Registro de eventos de acceso

  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  alias ProyectoFinalPrg3.Domain.Participant
  alias ProyectoFinalPrg3.Adapters.Security.{EncryptionAdapter, TokenManager, SessionManager}
  alias ProyectoFinalPrg3.Adapters.Persistence.ParticipantStore
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # ============================================================
  # REGISTRO
  # ============================================================

  @doc """
  Registra un participante con contraseña cifrada.

  Parámetros:
    - `nombre`    — Nombre completo del participante.
    - `correo`    — Correo electrónico único.
    - `username`  — Nombre de usuario.
    - `contrasena` — Contraseña en texto plano.
    - `rol`       — Rol del participante (por defecto "participante").

  Retorna:
    {:ok, participante}
    {:error, :correo_ya_registrado}
  """
  def registrar(nombre, correo, username, contrasena, rol \\ "participante") do
    case ParticipantStore.buscar_por_correo(correo) do
      nil ->
        hash = EncryptionAdapter.cifrar(contrasena)

        participante = %Participant{
          id: UUID.uuid4(),
          nombre: nombre,
          correo: correo,
          username: username,
          contrasena: hash,
          rol: rol,
          equipo_id: nil,
          estado: :activo,
          mensajes: []
        }

        ParticipantStore.guardar_participante(participante)

        LoggerService.registrar_evento("Usuario registrado", %{correo: correo})

        {:ok, participante}

      _ ->
        {:error, :correo_ya_registrado}
    end
  end

  # ============================================================
  # LOGIN
  # ============================================================

  @doc """
  Autentica un usuario mediante correo + contraseña.

  Parámetros:
    - `correo` — Correo del participante.
    - `contrasena` — Contraseña en texto plano.

  Retorna:
    {:ok, %{participante: p, token: t}}
    {:error, :no_encontrado}
    {:error, :contrasena_invalida}
  """
  def autenticar(correo, contrasena) do
    case ParticipantStore.buscar_por_correo(correo) do
      nil ->
        {:error, :no_encontrado}

      %Participant{} = participante ->
        if EncryptionAdapter.verificar(contrasena, participante.contrasena) do
          with {:ok, token} <- TokenManager.generar_token(participante.id),
               :ok <- SessionManager.activar_sesion(participante.id, token) do
            LoggerService.registrar_evento("Inicio de sesión", %{correo: correo})

            {:ok, %{participante: participante, token: token}}
          else
            _ -> {:error, :error_en_sesion}
          end
        else
          {:error, :contrasena_invalida}
        end
    end
  end

  # ============================================================
  # LOGOUT
  # ============================================================

  @doc """
  Cierra la sesión asociada a un participante.
  Retorna:
    {:ok, :sesion_cerrada}
  """
  def cerrar_sesion(id_participante) do
    SessionManager.revocar_sesion(id_participante)
    LoggerService.registrar_evento("Sesión cerrada", %{usuario: id_participante})
    {:ok, :sesion_cerrada}
  end

  # ============================================================
  # VALIDACIÓN DE TOKEN
  # ============================================================

  @doc """
  Parámetros:
    - `token` — Token a validar.
  Valida un token y retorna el participante asociado.
  Retorna:
    {:ok, participante}
    {:error, :token_invalido}
    {:error, :no_encontrado}
  """
  def validar_token(token) do
    case TokenManager.validar_token(token) do
      {:ok, id} ->
        case ParticipantStore.obtener_participante(id) do
          nil -> {:error, :no_encontrado}
          p -> {:ok, p}
        end

      _ ->
        {:error, :token_invalido}
    end
  end

  # ============================================================
  # SESIONES
  # ============================================================

  @doc """
  Verifica si un token pertenece a una sesión activa.
  Parámetros:
    - `token` — Token a verificar.
  Retorna:
    - `true` si la sesión está activa.
    - `false` en caso contrario.
  """
  def sesion_activa?(token) do
    case SessionManager.validar_sesion(token) do
      {:ok, _} -> true
      _ -> false
    end
  end
end

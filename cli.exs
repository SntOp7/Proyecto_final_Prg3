IO.puts("🎮 CLI lista (/help para ver comandos)\n")

defmodule CLI.Main do
  @moduledoc """
  Módulo principal para la interfaz de línea de comandos (CLI) del sistema.
  Permite la interacción con el usuario para ejecutar comandos y mostrar resultados.
  Soporta envío de mensajes directos cuando el usuario está en un chat activo.

  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  @doc """
  Bucle principal de la interfaz de línea de comandos.

  Este proceso NO ejecuta la aplicación completa.
  Solo envía los comandos al nodo central usando CommandRouter,
  el cual delega la lógica al sistema distribuido.

  Permite dos modos de interacción:
  - Comandos con prefijo `/`: se envían al CommandRouter
  - Texto sin prefijo: se envía como mensaje si el usuario está en un chat activo
  """
  def loop do
    case IO.gets("> ") do
      nil ->
        IO.puts("Saliendo...")

      line ->
        linea_trim = String.trim(line)

        # Procesar la entrada
        resultado = cond do
          # Si está vacío, ignorar
          linea_trim == "" ->
            :ok

          # Si empieza con /, es un comando
          String.starts_with?(linea_trim, "/") ->
            ProyectoFinalPrg3.Adapters.CLI.CommandRouter.route(linea_trim)

          # Si NO empieza con / pero está en un chat, enviar mensaje
          true ->
            enviar_mensaje_si_en_chat(linea_trim)
        end

        # Mostrar resultado
        case resultado do
          {:ok, msg} ->
            mostrar_resultado(msg)

          {:error, msg} ->
            IO.puts("❌ #{msg}")

          :ok ->
            :ok

          other ->
            IO.inspect(other)
        end

        loop()
    end
  end

  # ============================================================
  # ENVIAR MENSAJE SI ESTÁ EN CHAT
  # ============================================================

  @doc false
  defp enviar_mensaje_si_en_chat(texto) do
    alias ProyectoFinalPrg3.Adapters.Security.SessionManager
    alias ProyectoFinalPrg3.Services.ChatService

    case SessionManager.obtener_participante_actual() do
      {:ok, participante} ->
        if ChatService.chat_activo?(participante.id) do
          # Está en un chat, enviar mensaje
          ChatService.enviar_mensaje(texto)
        else
          # No está en chat, es comando inválido
          {:error, "Formato inválido. Usa /help para ver los comandos válidos."}
        end

      _ ->
        {:error, "Formato inválido. Usa /help para ver los comandos válidos."}
    end
  end

  # ============================================================
  # FORMATEO DE RESULTADOS
  # ============================================================

  @doc false
  defp mostrar_resultado(msg) when is_binary(msg) do
    IO.puts(msg)
  end

  defp mostrar_resultado(lista) when is_list(lista) do
    if Enum.empty?(lista) do
      IO.puts("No hay resultados para mostrar.")
    else
      Enum.each(lista, fn item ->
        IO.puts(formatear_item(item))
      end)
    end
  end

  @doc false
  defp mostrar_resultado(struct) when is_map(struct) do
    IO.puts(formatear_item(struct))
  end

  @doc false
  defp mostrar_resultado(otro) do
    IO.inspect(otro, pretty: true, limit: :infinity)
  end

  # ============================================================
  # FORMATEO POR TIPO DE ENTIDAD
  # ============================================================

  @doc false
  defp formatear_item(%ProyectoFinalPrg3.Domain.Team{} = equipo) do
    """

    🏆 #{equipo.nombre}
       📂 Categoría: #{equipo.categoria}
       📝 Descripción: #{equipo.descripcion}
       👥 Participantes: #{length(equipo.participantes)}
       📅 Creado: #{Calendar.strftime(equipo.fecha_creacion, "%Y-%m-%d %H:%M")}
       ⚡ Estado: #{equipo.estado}
    """
  end

  @doc false
  defp formatear_item(%ProyectoFinalPrg3.Domain.Project{} = proyecto) do
    """

    💼 #{proyecto.nombre}
       📂 Categoría: #{proyecto.categoria}
       📝 Descripción: #{proyecto.descripcion}
       🔗 Repositorio: #{proyecto.repositorio_url || "No definido"}
       📅 Creado: #{Calendar.strftime(proyecto.fecha_creacion, "%Y-%m-%d %H:%M")}
       ⚡ Estado: #{proyecto.estado}
    """
  end

  defp formatear_item(%ProyectoFinalPrg3.Domain.Participant{} = participante) do
    """

    👤 #{participante.nombre} (@#{participante.username})
       📧 Email: #{participante.correo}
       🎭 Rol: #{participante.rol}
       🏆 Equipo: #{participante.equipo_id || "Sin equipo"}
       ⚡ Estado: #{participante.estado}
    """
  end

  @doc false
  defp formatear_item(%ProyectoFinalPrg3.Domain.Mentor{} = mentor) do
    """

    👨‍🏫 #{mentor.nombre}
       📧 Email: #{mentor.correo}
       🎭 Rol: #{mentor.rol}
       🆔 ID: #{mentor.id}
    """
  end

  defp formatear_item(%ProyectoFinalPrg3.Domain.Progress{} = avance) do
    """

    📊 #{avance.titulo} (v#{avance.version})
       💼 Proyecto: #{avance.proyecto_id}
       📝 Descripción: #{avance.descripcion}
       👤 Autor: #{avance.autor_id}
       📅 Registrado: #{Calendar.strftime(avance.timestamp, "%Y-%m-%d %H:%M")}
    """
  end

  defp formatear_item(item) do
    "\n" <> inspect(item, pretty: true, limit: :infinity)
  end
end

CLI.Main.loop()

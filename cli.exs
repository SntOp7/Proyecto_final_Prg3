IO.puts("🎮 CLI lista (/help para ver comandos)\n")

defmodule CLI.Main do
  @moduledoc """
  Interfaz CLI para ProyectoFinalPrg3.
  Maneja:
  - Comandos con prefijo '/'
  - Mensajes de chat
  - Anuncios globales
  """

  # ============================================================
  # INICIO DEL CLI
  # ============================================================

  def start do
    # 🔥 REGISTRAR EL CLI COMO PROCESO GLOBAL
    # Esto permite que el CENTRAL le envíe mensajes:
    #   send(pid, {:anuncio_global, mensaje})
    :global.register_name({:cli_user, self()}, self())

    # INICIAR BUCLE PRINCIPAL
    loop(%{})
  end

  # ============================================================
  # BUCLE PRINCIPAL
  # ============================================================

  def loop(state) do
    receive do
      # ======================================================
      # 🟦 ANUNCIOS GLOBALES DESDE EL CENTRAL
      # ======================================================
      {:anuncio_global, mensaje} ->
        IO.puts("""

        🌐 [ANUNCIO GLOBAL]
        #{mensaje.contenido}
        """)
        loop(state)

      # ======================================================
      # 🟩 MENSAJES DE CHAT (si decides implementarlo luego)
      # ======================================================
      {:mensaje_chat, mensaje} ->
        IO.puts("\n💬 #{mensaje.autor}: #{mensaje.contenido}")
        loop(state)

      # ======================================================
      # 🟨 CUALQUIER OTRO MENSAJE
      # ======================================================
      other ->
        IO.puts("📥 Mensaje del sistema: #{inspect(other)}")
        loop(state)
    after
      0 ->
        case IO.gets("> ") do
          nil ->
            IO.puts("Saliendo...")

          line ->
            linea = String.trim(line)

            resultado =
              cond do
                linea == "" ->
                  :ok

                # Comando tipo /login /register /announcement...
                String.starts_with?(linea, "/") ->
                  ProyectoFinalPrg3.Adapters.CLI.CommandRouter.route(linea)

                # Texto → Chat
                true ->
                  enviar_mensaje_si_en_chat(linea)
              end

            case resultado do
              {:ok, msg} -> mostrar_resultado(msg)
              {:error, msg} -> IO.puts("❌ #{msg}")
              :ok -> :ok
              other -> IO.inspect(other)
            end

            loop(state)
        end
    end
  end

  # ============================================================
  # ENVÍO DE MENSAJE A CHAT SI APLICA
  # ============================================================

  defp enviar_mensaje_si_en_chat(texto) do
    alias ProyectoFinalPrg3.Adapters.Security.SessionManager
    alias ProyectoFinalPrg3.Services.ChatService

    case SessionManager.obtener_participante_actual() do
      {:ok, participante} ->
        if ChatService.chat_activo?(participante.id) do
          ChatService.enviar_mensaje(texto)
        else
          {:error, "Formato inválido. Usa /help para ver los comandos válidos."}
        end

      _ ->
        {:error, "Formato inválido. Usa /help para ver los comandos válidos."}
    end
  end

  # ============================================================
  # FORMATEO DE RESULTADOS
  # ============================================================

  defp mostrar_resultado(msg) when is_binary(msg), do: IO.puts(msg)

  defp mostrar_resultado(lista) when is_list(lista) do
    if Enum.empty?(lista) do
      IO.puts("No hay resultados para mostrar.")
    else
      Enum.each(lista, fn item ->
        IO.puts(formatear_item(item))
      end)
    end
  end

  defp mostrar_resultado(map) when is_map(map), do: IO.puts(formatear_item(map))

  defp mostrar_resultado(otro), do: IO.inspect(otro, pretty: true, limit: :infinity)

  # ============================================================
  # FORMATEADORES DE ENTIDADES
  # ============================================================

  defp formatear_item(%ProyectoFinalPrg3.Domain.Team{} = e) do
    """

    🏆 #{e.nombre}
       📂 Categoría: #{e.categoria}
       📝 Descripción: #{e.descripcion}
       👥 Participantes: #{length(e.participantes)}
       📅 Creado: #{Calendar.strftime(e.fecha_creacion, "%Y-%m-%d %H:%M")}
       ⚡ Estado: #{e.estado}
    """
  end

  defp formatear_item(%ProyectoFinalPrg3.Domain.Project{} = p) do
    """

    💼 #{p.nombre}
       📂 Categoría: #{p.categoria}
       📝 Descripción: #{p.descripcion}
       🔗 Repositorio: #{p.repositorio_url || "No definido"}
       📅 Creado: #{Calendar.strftime(p.fecha_creacion, "%Y-%m-%d %H:%M")}
       ⚡ Estado: #{p.estado}
    """
  end

  defp formatear_item(%ProyectoFinalPrg3.Domain.Participant{} = u) do
    """

    👤 #{u.nombre} (@#{u.username})
       📧 Email: #{u.correo}
       🎭 Rol: #{u.rol}
       🏆 Equipo: #{u.equipo_id || "Sin equipo"}
       ⚡ Estado: #{u.estado}
    """
  end

  defp formatear_item(%ProyectoFinalPrg3.Domain.Mentor{} = m) do
    """

    👨‍🏫 #{m.nombre}
       📧 Email: #{m.correo}
       🎭 Rol: #{m.rol}
       🆔 ID: #{m.id}
    """
  end

  defp formatear_item(%ProyectoFinalPrg3.Domain.Progress{} = a) do
    """

    📊 #{a.titulo} (v#{a.version})
       💼 Proyecto: #{a.proyecto_id}
       📝 Descripción: #{a.descripcion}
       👤 Autor: #{a.autor_id}
       📅 Registrado: #{Calendar.strftime(a.timestamp, "%Y-%m-%d %H:%M")}
    """
  end

  defp formatear_item(other),
    do: "\n" <> inspect(other, pretty: true, limit: :infinity)
end

CLI.Main.start()

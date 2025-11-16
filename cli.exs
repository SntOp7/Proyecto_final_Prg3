Mix.Task.run("app.start")

IO.puts("🎮 CLI lista (/help para ver comandos)\n")

defmodule CLI.Main do
  def loop do
    case IO.gets("> ") do
      nil ->
        IO.puts("Saliendo...")

      line ->
        case ProyectoFinalPrg3.Adapters.CLI.CommandRouter.route(line) do
          {:ok, msg} ->
            mostrar_resultado(msg)

          {:error, msg} ->
            IO.puts("❌ #{msg}")

          other ->
            IO.inspect(other)
        end

        loop()
    end
  end

  # ============================================================
  # FORMATEO DE RESULTADOS
  # ============================================================

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

  defp mostrar_resultado(struct) when is_map(struct) do
    IO.puts(formatear_item(struct))
  end

  defp mostrar_resultado(otro) do
    IO.inspect(otro, pretty: true, limit: :infinity)
  end

  # ============================================================
  # FORMATEO POR TIPO DE ENTIDAD
  # ============================================================

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

  defp formatear_item(item) do
    "\n" <> inspect(item, pretty: true, limit: :infinity)
  end
end

CLI.Main.loop()

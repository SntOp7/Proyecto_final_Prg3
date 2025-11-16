Mix.Task.run("app.start")

IO.puts("🎮 CLI lista (/help para ver comandos)\n")

defmodule CLI.Main do
  def loop do
    case IO.gets("> ") do
      nil -> IO.puts("Saliendo...")

      line ->
        case ProyectoFinalPrg3.Adapters.CLI.CommandParser.parse(line) do
          {:ok, msg} -> IO.puts(msg)
          {:error, msg} -> IO.puts("❌ #{msg}")
          other -> IO.inspect(other)
        end

        loop()
    end
  end
end

CLI.Main.loop()
